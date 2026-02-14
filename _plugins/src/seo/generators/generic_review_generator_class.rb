# frozen_string_literal: true

# _plugins/src/seo/generators/generic_review_generator_class.rb
require 'jekyll'
require_relative '../json_ld_utils'
require_relative '../../infrastructure/url_utils'
require_relative '../../infrastructure/text_processing_utils'

module Jekyll
  # Helper class to handle generic review generation logic
  module SEO
    module Generators
      # Generator class for creating JSON-LD Review schema for generic reviews.
      # Handles the detailed logic for building generic review structured data.
      class GenericReviewGenerator
        def initialize(document, site)
          @document = document
          @site = site
          @review_fm = document.data['review']
        end

        def generate
          return {} unless valid_item_name?

          data = build_base_data
          data['itemReviewed'] = build_item_reviewed

          Jekyll::SEO::JsonLdUtils.cleanup_data_hash!(data)
        end

        private

        def valid_item_name?
          item_name = @review_fm&.dig('item_name')
          return true if item_name && !item_name.to_s.strip.empty?

          log_missing_item_name
          false
        end

        def log_missing_item_name
          id = @document.url || @document.path || @document.relative_path
          Jekyll.logger.error(
            'JSON-LD (GenericReviewGen):',
            "Called for '#{id}' but 'review.item_name' is missing or empty. " \
            'This should have been caught by the injector.',
          )
        end

        def build_base_data
          data = {
            '@context' => 'https://schema.org',
            '@type' => 'Review',
          }
          add_review_metadata(data)
          data
        end

        def add_review_metadata(data)
          data['author'] = Jekyll::SEO::JsonLdUtils.build_site_person_entity(@site)
          data['datePublished'] = @document.date.to_time.xmlschema if @document.date
          data['publisher'] = Jekyll::SEO::JsonLdUtils.build_site_person_entity(@site, include_site_url: true)
          data['reviewBody'] = extract_review_body
          data['url'] = review_page_url
        end

        def extract_review_body
          Jekyll::SEO::JsonLdUtils.extract_descriptive_text(
            @document,
            field_priority: ['description'],
          )
        end

        def review_page_url
          Jekyll::Infrastructure::UrlUtils.absolute_url(@document.url, @site)
        end

        def build_item_reviewed
          item = {
            '@type' => @review_fm['item_type'] || 'Product',
            'name' => @review_fm['item_name'],
          }
          add_item_image(item)
          add_item_url(item)
          add_item_description(item)
          Jekyll::SEO::JsonLdUtils.cleanup_data_hash!(item)
        end

        def add_item_image(item)
          img_entity = Jekyll::SEO::JsonLdUtils.build_image_object_entity(@document.data['image'], @site)
          item['image'] = img_entity['url'] if img_entity
        end

        def add_item_url(item)
          url = @review_fm['item_url']
          item['url'] = Jekyll::Infrastructure::UrlUtils.absolute_url(url, @site) if url && !url.strip.empty?
        end

        def add_item_description(item)
          desc = @review_fm['item_description']
          return unless desc && !desc.strip.empty?

          cleaned = Jekyll::Infrastructure::TextProcessingUtils.clean_text_from_html(desc)
          item['description'] = cleaned unless cleaned.empty?
        end
      end
    end
  end
end
