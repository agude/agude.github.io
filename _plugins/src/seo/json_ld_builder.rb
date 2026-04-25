# frozen_string_literal: true

require_relative '../infrastructure/url_utils'
require_relative '../infrastructure/front_matter_utils'
require_relative '../infrastructure/text_processing_utils'
require_relative 'json_ld_utils'

module Jekyll
  module SEO
    # Block-based DSL for building JSON-LD structured data.
    # Handles context binding, snake_case to camelCase conversion, and nested schemas.
    # rubocop:disable Metrics/ClassLength -- builder has many small field methods by design
    class JsonLdBuilder
      CC_BY_SA_LICENSE_URL = 'https://creativecommons.org/licenses/by-sa/4.0/'

      attr_reader :document, :site

      def self.build(type, license: false, document: nil, site: nil, &block)
        builder = new(type, license: license, document: document, site: site, is_root: true)
        yield builder if block_given?
        builder.to_h
      end

      def initialize(type, license: false, document: nil, site: nil, is_root: true)
        @document = document
        @site = site
        @is_root = is_root
        @required_keys = []
        @data = {}
        @data['@context'] = 'https://schema.org' if is_root
        @data['@type'] = type
        @data['license'] = CC_BY_SA_LICENSE_URL if license
      end

      def url(custom_path = nil)
        path = custom_path || @document&.url
        return unless path

        abs_url = Jekyll::Infrastructure::UrlUtils.absolute_url(path, @site)
        set_if_present('url', abs_url)
      end

      def site_author(include_url: false)
        entity = Jekyll::SEO::JsonLdUtils.build_site_person_entity(@site, include_site_url: include_url)
        @data['author'] = entity if entity
      end

      def site_publisher
        entity = Jekyll::SEO::JsonLdUtils.build_site_person_entity(@site, include_site_url: true)
        @data['publisher'] = entity if entity
      end

      def image(path)
        entity = Jekyll::SEO::JsonLdUtils.build_image_object_entity(path, @site)
        @data['image'] = entity if entity
      end

      def authors(value)
        names = Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(value)
        return if names.empty?

        entities = names.map { |name| { '@type' => 'Person', 'name' => name } }
        @data['author'] = entities.length == 1 ? entities.first : entities
      end

      def rating(value)
        entity = Jekyll::SEO::JsonLdUtils.build_rating_entity(value)
        @data['reviewRating'] = entity if entity
      end

      def series(name, position = nil)
        entity = Jekyll::SEO::JsonLdUtils.build_book_series_entity(name, position)
        @data['isPartOf'] = entity if entity
      end

      def dates
        return unless @document&.date

        @data['datePublished'] = @document.date.to_time.xmlschema
        modified = @document.data['last_modified_at'] || @document.date
        @data['dateModified'] = modified.to_time.xmlschema
      end

      def item_reviewed(type, &)
        nested_builder(type, 'itemReviewed', &)
      end

      def author(type, &)
        nested_builder(type, 'author', &)
      end

      # rubocop:disable Naming/PredicatePrefix -- matches JSON-LD field 'isPartOf'
      def is_part_of_website
        return unless @site

        site_name = @site.config['title']
        site_url = Jekyll::Infrastructure::UrlUtils.absolute_url('', @site)
        return unless site_name && site_url

        @data['isPartOf'] = {
          '@type' => 'WebSite',
          'name' => site_name,
          'url' => site_url,
        }
      end
      # rubocop:enable Naming/PredicatePrefix

      def main_entity_of_page
        return unless @document && @site

        abs_url = Jekyll::Infrastructure::UrlUtils.absolute_url(@document.url, @site)
        return unless abs_url

        @data['mainEntityOfPage'] = {
          '@type' => 'WebPage',
          '@id' => abs_url,
        }
      end

      def keywords(categories, tags)
        list = []
        list.concat(categories || [])
        list.concat(tags || [])
        list.uniq!
        @data['keywords'] = list.join(', ') if list.any?
      end

      def encoding(markdown_href)
        entity = Jekyll::SEO::JsonLdUtils.build_markdown_encoding_entity(markdown_href, @site)
        @data['encoding'] = entity if entity
      end

      def description(value = nil)
        text = if value
                 value.to_s.strip
               elsif @document
                 raw = @document.data['description']
                 return unless raw && !raw.to_s.strip.empty?

                 Jekyll::Infrastructure::TextProcessingUtils.clean_text_from_html(raw)
               end
        set_if_present('description', text)
      end

      def description_from_fields(field_priority:, truncate_words: nil)
        return unless @document

        truncate_opts = truncate_words ? { words: truncate_words, omission: '...' } : nil
        text = Jekyll::SEO::JsonLdUtils.extract_descriptive_text(
          @document,
          field_priority: field_priority,
          truncate_options: truncate_opts,
        )
        set_if_present('description', text)
      end

      def article_body
        return unless @document

        text = Jekyll::SEO::JsonLdUtils.extract_descriptive_text(
          @document,
          field_priority: ['content'],
        )
        set_if_present('articleBody', text)
      end

      def same_as(urls)
        return if urls.nil?

        unless urls.is_a?(Array)
          log_invalid_array_type('same_as_urls', 'sameAs')
          return
        end

        cleaned = urls.filter_map do |u|
          s = u.to_s.strip
          s unless s.empty?
        end
        @data['sameAs'] = cleaned if cleaned.any?
      end

      def awards(list)
        return if list.nil?

        unless list.is_a?(Array)
          log_invalid_array_type('awards', 'award')
          return
        end

        cleaned = list.filter_map do |a|
          s = a.to_s.strip
          s unless s.empty?
        end
        @data['award'] = cleaned if cleaned.any?
      end

      def about(type, name)
        return unless name && !name.to_s.strip.empty?

        @data['about'] = {
          '@type' => type,
          'name' => name.to_s.strip,
        }
      end

      def name_with_suffix(suffix)
        title = @document&.data&.[]('title')
        return unless title && !title.strip.empty?

        @data['name'] = "#{title.strip} - #{suffix}"
      end

      def site_name
        name = @site&.config&.[]('title')
        set_if_present('name', name)
      end

      def site_description
        desc = @site&.config&.[]('description')
        set_if_present('description', desc)
      end

      def job_title(value)
        set_if_present('jobTitle', value)
      end

      def works_for(org_name)
        return unless org_name && !org_name.to_s.strip.empty?

        @data['worksFor'] = {
          '@type' => 'Organization',
          'name' => org_name.to_s.strip,
        }
      end

      def social_links_from_site
        author = @site&.config&.[]('author') || {}
        links = Jekyll::SEO::JsonLdUtils.build_social_links(author)
        @data['sameAs'] = links if links.any?
      end

      def main_entity_person_with_social
        author = @site&.config&.[]('author')
        return unless author.is_a?(Hash) && author['name']

        person = { '@type' => 'Person', 'name' => author['name'] }
        links = Jekyll::SEO::JsonLdUtils.build_social_links(author)
        person['sameAs'] = links if links.any?
        @data['mainEntity'] = person
      end

      def alternate_names(names)
        list = Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(names)
        @data['alternateName'] = list if list.any?
      end

      def review_body_from_fields(field_priority:)
        return unless @document

        text = Jekyll::SEO::JsonLdUtils.extract_descriptive_text(
          @document,
          field_priority: field_priority,
        )
        set_if_present('reviewBody', text)
      end

      NOT_PROVIDED = Object.new.freeze
      private_constant :NOT_PROVIDED

      def date_published(value = NOT_PROVIDED)
        if value == NOT_PROVIDED
          return unless @document&.date

          @data['datePublished'] = @document.date.to_time.xmlschema
        else
          set_if_present('datePublished', value)
        end
      end

      def isbn(value)
        set_if_present('isbn', value)
      end

      def require!(*keys)
        @required_keys.concat(keys)
      end

      def raw(key, value)
        @data[key] = value
      end

      def to_h
        check_required_fields
        Jekyll::SEO::JsonLdUtils.cleanup_data_hash!(@data.dup)
      end

      def method_missing(method_name, *args, &)
        return super if block_given?

        json_key = snake_to_camel(method_name.to_s)
        value = args.first
        set_if_present(json_key, value)
      end

      def respond_to_missing?(method_name, include_private = false)
        true || super
      end

      private

      def nested_builder(type, key, &)
        child = self.class.new(type, document: @document, site: @site, is_root: false)
        yield child if block_given?
        result = child.to_h
        @data[key] = result unless result.keys == ['@type']
      end

      def set_if_present(key, value)
        return if value.nil?

        if value.is_a?(String)
          cleaned = value.strip
          @data[key] = cleaned unless cleaned.empty?
        elsif value.respond_to?(:empty?)
          @data[key] = value unless value.empty?
        else
          @data[key] = value
        end
      end

      def snake_to_camel(str)
        str.gsub(/_([a-z])/) { ::Regexp.last_match(1).upcase }
      end

      def log_invalid_array_type(front_matter_key, json_ld_key)
        doc_id = @document&.url || 'unknown'
        Jekyll.logger.warn(
          'JSON-LD:',
          "Front matter '#{front_matter_key}' for '#{doc_id}' is not an Array, skipping #{json_ld_key}.",
        )
      end

      def check_required_fields
        missing = @required_keys.select { |key| field_empty?(snake_to_camel(key.to_s)) }
        return if missing.empty?

        doc_url = @document&.url || 'unknown'
        raise Jekyll::Errors::FatalException,
              "JSON-LD #{@data['@type']} for #{doc_url}: missing required fields: #{missing.join(', ')}"
      end

      def field_empty?(json_key)
        value = @data[json_key]
        value.nil? || (value.respond_to?(:empty?) && value.empty?)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
