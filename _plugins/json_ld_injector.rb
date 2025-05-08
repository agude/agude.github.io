# _plugins/json_ld_injector.rb
require 'json'
require 'jekyll' # Required for Jekyll.logger

# Require generator modules
require_relative 'utils/json_ld_generators/blog_posting_generator'
require_relative 'utils/json_ld_generators/book_review_generator'
require_relative 'utils/json_ld_generators/generic_review_generator'
require_relative 'utils/json_ld_generators/author_profile_generator'
# TODO: Implement PluginLoggerUtils if needed for more complex logging scenarios,
# but Jekyll.logger is suitable for warnings/errors here.

module JsonLdInjector

  # Central method to determine the type of document and generate JSON-LD
  def self.inject_json_ld(document, site)
    doc_identifier = document.url || document.path || document.relative_path # For logging

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
        # Jekyll.logger.debug "JSON-LD Type:", "Unhandled -> #{doc_identifier}"
    end


    # --- Generate Hash and Inject Script Tag ---
    if generator_module
      json_ld_hash = generator_module.generate_hash(document, site)

      if json_ld_hash && !json_ld_hash.empty?
        begin
          script_content = JSON.pretty_generate(json_ld_hash) # Pretty for dev
          document.data['json_ld_script'] = "<script type=\"application/ld+json\">\n#{script_content}\n</script>"
        rescue JSON::GeneratorError => e
          # Use Jekyll's logger for errors
          Jekyll.logger.error "JSON-LD:", "Failed to generate JSON for '#{doc_identifier}': #{e.message}"
        end
      elsif json_ld_hash # Log if generator returned an empty hash (and wasn't nil)
          Jekyll.logger.debug "JSON-LD:", "Generated JSON-LD hash was empty for: #{doc_identifier}"
      end
      # If json_ld_hash is nil (e.g., missing item_name), nothing is injected.
    end
  end

  private

  # --- Private Helper Methods for Type Checking ---

  def self._is_book_review?(doc)
    # Check collection label first for efficiency
    doc.collection&.label == 'books' && doc.data['layout'] == 'book'
  end

  def self._is_generic_review_post?(doc)
    # Must be a post with the 'review' key present
    doc.collection&.label == 'posts' && doc.data['layout'] == 'post' && doc.data.key?('review')
  end

  def self._is_blog_post?(doc)
    # Must be a post, but *not* have the 'review' key
    doc.collection&.label == 'posts' && doc.data['layout'] == 'post' && !doc.data.key?('review')
  end

  def self._is_author_page?(doc)
    # Identified solely by layout, can be Page or Document
    doc.data['layout'] == 'author_page'
  end

end

# --- Register Hooks ---
# (Hooks remain the same, calling JsonLdInjector.inject_json_ld)

Jekyll::Hooks.register :documents, :post_convert do |document|
  next if document.is_a?(Jekyll::StaticFile)
  next if document.respond_to?(:draft?) && document.draft? && !document.site.show_drafts
  site = document.site
  if site
    JsonLdInjector.inject_json_ld(document, site)
  else
    Jekyll.logger.error "JSON-LD Hook:", "Site object not available for document: #{document.relative_path}"
  end
end

Jekyll::Hooks.register :pages, :post_convert do |page|
  next if page.is_a?(Jekyll::StaticFile)
  site = page.site
  if site
    JsonLdInjector.inject_json_ld(page, site)
  else
     Jekyll.logger.error "JSON-LD Hook:", "Site object not available for page: #{page.relative_path || page.path || page.url}"
  end
end