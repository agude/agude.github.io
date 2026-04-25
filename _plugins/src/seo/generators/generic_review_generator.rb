# frozen_string_literal: true

require_relative '../json_ld_builder'
require_relative '../../infrastructure/text_processing_utils'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD Review schema for generic reviews.
      class GenericReviewLdGenerator
        def self.generate_hash(document, site)
          new(document, site).generate
        end

        def initialize(document, site)
          @document = document
          @site = site
          @review_fm = document.data['review'] || {}
        end

        def generate
          return {} unless valid_item_name?

          Jekyll::SEO::JsonLdBuilder.build('Review', license: true, document: @document, site: @site) do |review|
            review.site_author
            review.date_published
            review.site_publisher
            review.review_body_from_fields(field_priority: ['description'])
            review.url

            review.item_reviewed(@review_fm['item_type'] || 'Product') do |item|
              item.name @review_fm['item_name']
              add_item_image(item)
              add_item_url(item)
              add_item_description(item)
            end
          end
        end

        private

        def valid_item_name?
          item_name = @review_fm['item_name']
          return true if item_name && !item_name.to_s.strip.empty?

          log_missing_item_name
          false
        end

        def log_missing_item_name
          id = @document.url || @document.path || @document.relative_path
          Jekyll.logger.error(
            'JSON-LD (GenericReviewGen):',
            "Called for '#{id}' but 'review.item_name' is missing or empty.",
          )
        end

        def add_item_image(item)
          path = @document.data['image']
          return unless path && !path.to_s.strip.empty?

          abs_url = Jekyll::Infrastructure::UrlUtils.absolute_url(path, @site)
          item.raw 'image', abs_url
        end

        def add_item_url(item)
          url = @review_fm['item_url']
          return unless url && !url.strip.empty?

          item.url url
        end

        def add_item_description(item)
          desc = @review_fm['item_description']
          return unless desc && !desc.strip.empty?

          cleaned = Jekyll::Infrastructure::TextProcessingUtils.clean_text_from_html(desc)
          item.description cleaned unless cleaned.empty?
        end
      end
    end
  end
end
