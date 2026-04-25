# frozen_string_literal: true

# _plugins/json_ld_injector.rb
require 'json'
require 'jekyll'

# Require generator modules
require_relative 'generators/blog_posting_generator'
require_relative 'generators/book_review_generator'
require_relative 'generators/generic_review_generator'
require_relative 'generators/author_profile_generator'
require_relative 'generators/person_generator'
require_relative 'generators/website_generator'
require_relative 'generators/series_page_generator'
require_relative 'generators/category_page_generator'
require_relative 'generators/page_generator'
require_relative 'generators/profile_page_generator'
require_relative 'generators/web_page_generator'

module Jekyll
  module SEO
    # Injects JSON-LD structured data into Jekyll documents and pages.
    # Uses a layout-to-generator mapping for simple, predictable routing.
    #
    # Data flow:
    #   :documents/:pages, :post_convert hook ->
    #   inject_json_ld looks up generator from LAYOUT_GENERATORS by layout name ->
    #   generator returns a hash ->
    #   serialized to a <script type="application/ld+json"> tag ->
    #   stored in site.data['generated_json_ld_scripts'][doc.url] ->
    #   _includes/head.html reads from site.data and emits the tag.
    #
    # Strict on unknown layouts: an unregistered layout raises
    # Jekyll::Errors::FatalException. Layouts that legitimately produce
    # no JSON-LD (utility wrappers, redirects, 404, test pages) live in
    # SKIP_LAYOUTS instead of LAYOUT_GENERATORS.
    module JsonLdInjector
      # Layout name → [Generator module, Human-readable type name]
      LAYOUT_GENERATORS = {
        'post' => [Generators::BlogPostingLdGenerator, 'BlogPosting'],
        'review-post' => [Generators::GenericReviewLdGenerator, 'Review'],
        'book' => [Generators::BookReviewLdGenerator, 'Book Review'],
        'author_page' => [Generators::AuthorProfileLdGenerator, 'Author Profile'],
        'resume' => [Generators::PersonLdGenerator, 'Person'],
        'series_page' => [Generators::SeriesPageLdGenerator, 'Series Page'],
        'category' => [Generators::CategoryPageLdGenerator, 'Category Page'],
        'page' => [Generators::PageLdGenerator, 'Collection Page'],
        'page-not-on-sidebar' => [Generators::PageLdGenerator, 'Collection Page'],
        'standalone-page' => [Generators::WebPageLdGenerator, 'WebPage'],
        'homepage' => [Generators::WebsiteLdGenerator, 'WebSite'],
        'linktree' => [Generators::ProfilePageLdGenerator, 'Profile Page'],
      }.freeze

      # Layouts that intentionally have no JSON-LD.
      # `substitute`, `compress`, `redirect` are base/utility layouts that should
      # never appear as a leaf layout on content. `404` and `test-page` are
      # content layouts whose pages don't need structured data.
      SKIP_LAYOUTS = %w[substitute compress redirect 404 test-page].freeze

      def self.initialize_script_storage(site)
        site.data['generated_json_ld_scripts'] ||= {}
      end

      def self.inject_json_ld(document, site)
        initialize_script_storage(site)

        doc_url = document.url
        unless doc_url && !doc_url.empty?
          Jekyll.logger.warn 'JSON-LD:', "Skipping document without URL: #{_doc_id(document)}"
          return
        end

        layout = document.data['layout']
        generator, type_name = _generator_for_layout(layout, document)
        return unless generator

        Jekyll.logger.debug 'JSON-LD:', "#{type_name} -> #{_doc_id(document)}"
        _generate_and_store(generator, document, site, doc_url)
      end

      def self._doc_id(doc)
        doc.url || doc.path || doc.relative_path
      end
      private_class_method :_doc_id

      def self._generator_for_layout(layout, document)
        # Pages without a layout (nil/empty) or with skip layouts get no JSON-LD
        return [nil, nil] if layout.nil? || layout.empty? || SKIP_LAYOUTS.include?(layout)

        entry = LAYOUT_GENERATORS[layout]
        return entry if entry

        raise Jekyll::Errors::FatalException,
              "JSON-LD: Unknown layout '#{layout}' for #{_doc_id(document)}. " \
              'Add it to LAYOUT_GENERATORS or SKIP_LAYOUTS in json_ld_injector.rb'
      end
      private_class_method :_generator_for_layout

      def self._generate_and_store(generator, document, site, doc_url)
        json_ld_hash = generator.generate_hash(document, site)

        if json_ld_hash && !json_ld_hash.empty?
          _store_script(json_ld_hash, site, doc_url)
        else
          Jekyll.logger.debug 'JSON-LD:', "Empty or nil hash for: #{_doc_id(document)}"
        end
      end
      private_class_method :_generate_and_store

      def self._store_script(hash, site, doc_url)
        script_content = JSON.pretty_generate(hash)
        script_tag = "<script type=\"application/ld+json\">\n#{script_content}\n</script>"
        site.data['generated_json_ld_scripts'][doc_url] = script_tag
      rescue JSON::GeneratorError => e
        Jekyll.logger.error 'JSON-LD:', "Failed to generate JSON for '#{doc_url}': #{e.message}"
      end
      private_class_method :_store_script
    end
  end
end

# --- Register Hooks ---

Jekyll::Hooks.register :site, :after_reset, priority: :high do |site|
  Jekyll::SEO::JsonLdInjector.initialize_script_storage(site)
end

Jekyll::Hooks.register :documents, :post_convert do |document|
  next if document.is_a?(Jekyll::StaticFile)
  next if document.respond_to?(:draft?) && document.draft? && !document.site.show_drafts

  site = document.site
  if site
    Jekyll::SEO::JsonLdInjector.inject_json_ld(document, site)
  else
    Jekyll.logger.error 'JSON-LD Hook:', "Site object not available for document: #{document.relative_path}"
  end
end

Jekyll::Hooks.register :pages, :post_convert do |page|
  next if page.is_a?(Jekyll::StaticFile)

  site = page.site
  if site
    Jekyll::SEO::JsonLdInjector.inject_json_ld(page, site)
  else
    Jekyll.logger.error 'JSON-LD Hook:',
                        "Site object not available for page: #{page.relative_path || page.path || page.url}"
  end
end
