# _plugins/json_ld_injector.rb
require 'json'
require 'jekyll' # Required for Jekyll.logger and Hook classes

# Require generator modules
require_relative 'utils/json_ld_generators/blog_posting_generator'
require_relative 'utils/json_ld_generators/book_review_generator'
require_relative 'utils/json_ld_generators/generic_review_generator'
require_relative 'utils/json_ld_generators/author_profile_generator'
# TODO: Implement PluginLoggerUtils if needed for more complex logging scenarios,
# but Jekyll.logger is suitable for warnings/errors here.

module JsonLdInjector

  # Initialize storage within site.data
  def self.initialize_script_storage(site)
    # Use site.data for reliable persistence into Liquid payload
    site.data['generated_json_ld_scripts'] ||= {}
  end

  # Central method to determine the type of document and generate JSON-LD
  def self.inject_json_ld(document, site)
    # Ensure storage is initialized (safe to call multiple times, though hook handles it)
    initialize_script_storage(site)

    doc_identifier = document.url || document.path || document.relative_path # For logging
    doc_url = document.url # Use URL as the key

    # If doc_url is nil or empty, we cannot store/retrieve it reliably
    unless doc_url && !doc_url.empty?
      Jekyll.logger.warn "JSON-LD:", "Skipping LD injection for document without URL: #{doc_identifier}"
      return
    end

    generator_module = nil
    log_type_name = "Unknown"

    # --- Determine Document Type using Helper Methods ---
    if _is_book_review?(document)
      log_type_name = "Book Review"
      generator_module = BookReviewLdGenerator
    elsif _is_generic_review_post?(document)
      log_type_name = "Generic Review Post"
      # Check for required item_name *before* assigning the generator
      item_name = document.data.dig('review', 'item_name')
      if item_name && !item_name.to_s.strip.empty?
        generator_module = GenericReviewLdGenerator
      else
        # Use Jekyll's logger for warnings
        Jekyll.logger.warn "JSON-LD:", "Skipping Generic Review LD for '#{doc_identifier}'. Missing 'review.item_name' in front matter."
        # generator_module remains nil
      end
    elsif _is_blog_post?(document) # Check this *after* generic review
      log_type_name = "Blog Posting"
      generator_module = BlogPostingLdGenerator
    elsif _is_author_page?(document)
      log_type_name = "Author Page"
      generator_module = AuthorProfileLdGenerator
    end

    # Log the determined type (or if it's unhandled)
    if generator_module
      Jekyll.logger.debug "JSON-LD Type:", "#{log_type_name} -> #{doc_identifier}"
    else
      # Optionally log unhandled types if needed for debugging other layouts/collections
      # Jekyll.logger.debug "JSON-LD Type:", "Unhandled -> #{doc_identifier}" unless doc_identifier.nil?
    end


    # --- Generate Hash and Store Script in site.data ---
    if generator_module
      json_ld_hash = generator_module.generate_hash(document, site)
      # puts "[DEBUG JsonLdInjector] Generated Hash for #{doc_identifier}: #{json_ld_hash.inspect}" # Keep for debugging if needed

      if json_ld_hash && !json_ld_hash.empty?
        begin
          script_content = JSON.pretty_generate(json_ld_hash) # Pretty for dev
          script_tag = "<script type=\"application/ld+json\">\n#{script_content}\n</script>"
          # Store in site.data using the document URL as the key
          site.data['generated_json_ld_scripts'][doc_url] = script_tag # Changed from site.config
          # puts "[DEBUG JsonLdInjector] Stored script in site.data for URL '#{doc_url}'" # Optional debug
        rescue JSON::GeneratorError => e
          # Use Jekyll's logger for errors
          Jekyll.logger.error "JSON-LD:", "Failed to generate JSON for '#{doc_identifier}': #{e.message}"
        end
      elsif json_ld_hash # Log if generator returned an empty hash (and wasn't nil)
        Jekyll.logger.debug "JSON-LD:", "Generated JSON-LD hash was empty for: #{doc_identifier}"
      else # Log if generator returned nil
        Jekyll.logger.debug "JSON-LD:", "Generator returned nil hash for: #{doc_identifier}"
      end
      # If json_ld_hash is nil (e.g., missing item_name), nothing is stored.
    end
  end

  private

  # --- Private Helper Methods for Type Checking ---

  def self._is_book_review?(doc)
    # Check if it's a Document first, then check collection/layout
    doc.is_a?(Jekyll::Document) && doc.collection&.label == 'books' && doc.data['layout'] == 'book'
  end

  def self._is_generic_review_post?(doc)
    # Check if it's a Document first, then check collection/layout/data
    doc.is_a?(Jekyll::Document) && doc.collection&.label == 'posts' && doc.data['layout'] == 'post' && doc.data.key?('review')
  end

  def self._is_blog_post?(doc)
    # Check if it's a Document first, then check collection/layout/data
    doc.is_a?(Jekyll::Document) && doc.collection&.label == 'posts' && doc.data['layout'] == 'post' && !doc.data.key?('review')
  end

  def self._is_author_page?(doc)
    # This check is safe for both Page and Document as it only uses data
    doc.data['layout'] == 'author_page'
  end

end

# --- Register Hooks ---

# Hook for initializing storage at the beginning of the build
Jekyll::Hooks.register :site, :after_reset, priority: :high do |site|
  # Use :high priority to ensure this runs before other hooks might try to access it
  JsonLdInjector.initialize_script_storage(site)
end

# Hook for all documents (posts, custom collections like 'books') after conversion
Jekyll::Hooks.register :documents, :post_convert do |document|
  # Skip if document is static file or draft (unless drafts are enabled)
  next if document.is_a?(Jekyll::StaticFile)
  next if document.respond_to?(:draft?) && document.draft? && !document.site.show_drafts

  site = document.site
  # Add safety check for site object
  if site
    JsonLdInjector.inject_json_ld(document, site)
  else
    Jekyll.logger.error "JSON-LD Hook:", "Site object not available for document: #{document.relative_path}"
  end
end

# Hook for pages (regular pages like author pages) after conversion
Jekyll::Hooks.register :pages, :post_convert do |page|
  # Skip if page is static file (less likely for pages hook, but safe)
  next if page.is_a?(Jekyll::StaticFile)

  site = page.site
  # Add safety check for site object
  if site
    JsonLdInjector.inject_json_ld(page, site)
  else
    Jekyll.logger.error "JSON-LD Hook:", "Site object not available for page: #{page.relative_path || page.path || page.url}"
  end
end
