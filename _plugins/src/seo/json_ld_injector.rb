# frozen_string_literal: true

require 'json'
require 'jekyll'

require_relative 'person_json_ld_builder'
require_relative 'generators/book_review_generator'
require_relative 'generators/generic_review_generator'
require_relative 'generators/person_generator'

module Jekyll
  module SEO
    # Injects JSON-LD structured data into Jekyll documents and pages.
    #
    # Data flow:
    #   :documents/:pages, :post_convert hook ->
    #   generate_hash looks up generator from LAYOUT_GENERATORS by layout name ->
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
      # @pattern Layouts with fixed schemas list builder steps in output order.
      #   A symbol calls a builder method with no arguments. A lambda supplies
      #   arguments from the document or builds a nested entity.
      def self.schema(type, *steps, builder: JsonLdBuilder, license: false)
        lambda do |document, site|
          builder.build(type, license: license, document: document, site: site) do |node|
            steps.each do |step|
              if step.is_a?(Symbol)
                node.public_send(step)
              else
                step.call(node, document)
              end
            end
          end
        end
      end
      private_class_method :schema

      PAGE_NAME = ->(node, doc) { node.page_name doc.data['title'] }
      PAGE_STEPS = [PAGE_NAME, :url, :description, :site_author, :is_part_of_website].freeze
      COLLECTION_PAGE = schema('CollectionPage', *PAGE_STEPS)
      private_constant :PAGE_NAME, :PAGE_STEPS, :COLLECTION_PAGE

      # Layout name → [hash generator, debug label]
      LAYOUT_GENERATORS = {
        'post' => [
          schema(
            'BlogPosting',
            ->(node, doc) { node.headline doc.data['title'] },
            :site_author,
            :site_publisher,
            :dates,
            ->(node, doc) { node.image doc.data['image'] },
            :url,
            :main_entity_of_page,
            ->(node, _) { node.description_from_fields(field_priority: %w[description excerpt], truncate_words: 50) },
            :article_body,
            :word_count,
            ->(node, doc) { node.keywords(doc.data['categories'], doc.data['tags']) },
            ->(node, doc) { node.encoding doc.data['markdown_alternate_href'] },
            ->(node, _) { node.require! :headline, :url },
            license: true,
          ),
          'BlogPosting',
        ],
        'review-post' => [Generators::GenericReviewLdGenerator.method(:generate_hash), 'Review'],
        'book' => [Generators::BookReviewLdGenerator.method(:generate_hash), 'Book Review'],
        # The author wrote the books. The CollectionPage describes the
        # site owner's reviews and links to the book author's Person node.
        'author_page' => [
          schema(
            'CollectionPage',
            ->(node, doc) { node.node_id doc.url },
            :url,
            ->(node, doc) { node.page_name doc.data['title'], suffix: 'Book Reviews' },
            :description,
            :site_author,
            :is_part_of_website,
            lambda do |node, doc|
              node.about_entity('Person') do |person|
                person.node_id doc.url, kind: :person
                person.url
                person.name doc.data['title']
                person.same_as doc.data['same_as_urls'], wikidata_qid: doc.data['wikidata_qid']
                person.alternate_names doc.data['pen_names']
              end
            end,
            builder: PersonJsonLdBuilder,
          ),
          'Author Collection Page',
        ],
        'resume' => [Generators::PersonLdGenerator.method(:generate_hash), 'Profile Page'],
        'series_page' => [
          schema(
            'CollectionPage',
            ->(node, doc) { node.page_name doc.data['title'], suffix: 'Book Reviews' },
            :url,
            :description,
            ->(node, doc) { node.about_book_series doc.data['title'] },
            :site_author,
            :is_part_of_website,
          ),
          'Series Page',
        ],
        'category' => [
          schema(
            'CollectionPage',
            ->(node, doc) { node.page_name doc.data['category-title'] || doc.data['title'], suffix: 'Articles' },
            :url,
            :description,
            :site_author,
            :is_part_of_website,
          ),
          'Category Page',
        ],
        'page' => [COLLECTION_PAGE, 'Collection Page'],
        'papers' => [COLLECTION_PAGE, 'Collection Page'],
        'page-not-on-sidebar' => [COLLECTION_PAGE, 'Collection Page'],
        'standalone-page' => [schema('WebPage', *PAGE_STEPS), 'WebPage'],
        'homepage' => [
          schema(
            'WebSite',
            :website_id,
            :site_name,
            :site_alternate_name,
            ->(node, _) { node.url '' },
            :site_description,
            :site_author,
            :site_publisher,
          ),
          'WebSite',
        ],
        'linktree' => [
          schema(
            'ProfilePage',
            PAGE_NAME,
            :url,
            :description,
            :main_entity_person_with_social,
            builder: PersonJsonLdBuilder,
          ),
          'Profile Page',
        ],
      }.freeze

      # Layouts that intentionally have no JSON-LD.
      # `substitute`, `compress`, `redirect` are base/utility layouts that should
      # never appear as a leaf layout on content. `404` and `test-page` are
      # content layouts whose pages don't need structured data.
      SKIP_LAYOUTS = %w[substitute compress redirect 404 test-page].freeze

      # Characters escaped as JSON unicode escapes inside the <script>
      # element. String values carry decoded post text, so `</script>` or
      # `<!-- <script>` in a code sample would end or hijack the element
      # (WHATWG "Restrictions for contents of script elements"). JSON
      # escapes decode back to the same string; HTML entities would not,
      # because script content is not entity-decoded. The three characters
      # never appear in JSON syntax outside strings.
      SCRIPT_UNSAFE_ESCAPES = {
        '<' => '\u003c',
        '>' => '\u003e',
        '&' => '\u0026',
      }.freeze

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

        json_ld_hash = generate_hash(document, site)
        _store_script(json_ld_hash, site, doc_url) if json_ld_hash
      end

      def self.generate_hash(document, site)
        layout = document.data['layout']&.to_s
        generator, type_name = _generator_for_layout(layout, document)
        return unless generator

        Jekyll.logger.debug 'JSON-LD:', "#{type_name} -> #{_doc_id(document)}"
        json_ld_hash = generator.call(document, site)
        return json_ld_hash if json_ld_hash && !json_ld_hash.empty?

        Jekyll.logger.debug 'JSON-LD:', "Empty or nil hash for: #{_doc_id(document)}"
        nil
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

      def self._store_script(hash, site, doc_url)
        script_content = JSON.pretty_generate(hash).gsub(/[<>&]/, SCRIPT_UNSAFE_ESCAPES)
        script_tag = "<script type=\"application/ld+json\">\n#{script_content}\n</script>"
        site.data['generated_json_ld_scripts'][doc_url] = script_tag
      rescue JSON::GeneratorError => e
        raise Jekyll::Errors::FatalException,
              "JSON-LD: Failed to generate JSON for '#{doc_url}': #{e.message}"
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
