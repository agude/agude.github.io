# frozen_string_literal: true

# _plugins/json_ld_injector.rb
require 'json'
require 'jekyll' # Required for Jekyll.logger and Hook classes

# Require generator modules
require_relative 'generators/blog_posting_generator'
require_relative 'generators/book_review_generator'
require_relative 'generators/generic_review_generator'
require_relative 'generators/author_profile_generator'

# Injects structured data (JSON-LD) into Jekyll documents and pages.
#
# Generates and embeds JSON-LD structured data for blog posts, book reviews,
# and author pages to enhance SEO and search engine understanding.
module JsonLdInjector
  # Initialize storage within site.data
  def self.initialize_script_storage(site)
    # Use site.data for reliable persistence into Liquid payload
    site.data['generated_json_ld_scripts'] ||= {}
  end

  # Central method to determine the type of document and generate JSON-LD
  def self.inject_json_ld(document, site)
    initialize_script_storage(site)

    doc_url = document.url
    unless doc_url && !doc_url.empty?
      Jekyll.logger.warn 'JSON-LD:', "Skipping LD injection for document without URL: #{_doc_id(document)}"
      return
    end

    generator, type_name = _determine_generator(document)
    return unless generator

    Jekyll.logger.debug 'JSON-LD Type:', "#{type_name} -> #{_doc_id(document)}"

    _generate_and_store(generator, document, site, doc_url)
  end

  # --- Private Helper Methods ---

  def self._doc_id(doc)
    doc.url || doc.path || doc.relative_path
  end

  def self._determine_generator(document)
    if _is_book_review?(document)
      [BookReviewLdGenerator, 'Book Review']
    elsif _is_generic_review_post?(document)
      _handle_generic_review(document)
    elsif _is_blog_post?(document)
      [BlogPostingLdGenerator, 'Blog Posting']
    elsif _is_author_page?(document)
      [AuthorProfileLdGenerator, 'Author Page']
    else
      [nil, 'Unknown']
    end
  end

  def self._handle_generic_review(document)
    item_name = document.data.dig('review', 'item_name')
    if item_name && !item_name.to_s.strip.empty?
      [GenericReviewLdGenerator, 'Generic Review Post']
    else
      _log_missing_item_name(document)
      [nil, 'Generic Review Post (Invalid)']
    end
  end

  def self._log_missing_item_name(document)
    Jekyll.logger.warn 'JSON-LD:',
                       "Skipping Generic Review LD for '#{_doc_id(document)}'. Missing 'review.item_name'."
  end

  def self._generate_and_store(generator, document, site, doc_url)
    json_ld_hash = generator.generate_hash(document, site)

    if json_ld_hash && !json_ld_hash.empty?
      _store_script(json_ld_hash, site, doc_url, document)
    elsif json_ld_hash
      Jekyll.logger.debug 'JSON-LD:', "Generated JSON-LD hash was empty for: #{_doc_id(document)}"
    else
      Jekyll.logger.debug 'JSON-LD:', "Generator returned nil hash for: #{_doc_id(document)}"
    end
  end

  def self._store_script(hash, site, doc_url, document)
    script_content = JSON.pretty_generate(hash)
    script_tag = "<script type=\"application/ld+json\">\n#{script_content}\n</script>"
    site.data['generated_json_ld_scripts'][doc_url] = script_tag
  rescue JSON::GeneratorError => e
    Jekyll.logger.error 'JSON-LD:', "Failed to generate JSON for '#{_doc_id(document)}': #{e.message}"
  end

  def self._is_book_review?(doc)
    doc.is_a?(Jekyll::Document) && doc.collection&.label == 'books' && doc.data['layout'] == 'book'
  end

  def self._is_generic_review_post?(doc)
    doc.is_a?(Jekyll::Document) && doc.collection&.label == 'posts' &&
      doc.data['layout'] == 'post' && doc.data.key?('review')
  end

  def self._is_blog_post?(doc)
    doc.is_a?(Jekyll::Document) && doc.collection&.label == 'posts' &&
      doc.data['layout'] == 'post' && !doc.data.key?('review')
  end

  def self._is_author_page?(doc)
    doc.data['layout'] == 'author_page'
  end
end

# --- Register Hooks ---

Jekyll::Hooks.register :site, :after_reset, priority: :high do |site|
  JsonLdInjector.initialize_script_storage(site)
end

Jekyll::Hooks.register :documents, :post_convert do |document|
  next if document.is_a?(Jekyll::StaticFile)
  next if document.respond_to?(:draft?) && document.draft? && !document.site.show_drafts

  site = document.site
  if site
    JsonLdInjector.inject_json_ld(document, site)
  else
    Jekyll.logger.error 'JSON-LD Hook:', "Site object not available for document: #{document.relative_path}"
  end
end

Jekyll::Hooks.register :pages, :post_convert do |page|
  next if page.is_a?(Jekyll::StaticFile)

  site = page.site
  if site
    JsonLdInjector.inject_json_ld(page, site)
  else
    Jekyll.logger.error 'JSON-LD Hook:',
                        "Site object not available for page: #{page.relative_path || page.path || page.url}"
  end
end
