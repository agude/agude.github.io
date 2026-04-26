# frozen_string_literal: true

require_relative '../json_ld_builder'
require_relative '../../infrastructure/text_processing_utils'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD Review schema for generic reviews.
      module GenericReviewLdGenerator
        def self.generate_hash(document, site)
          review_fm = document.data['review'] || {}
          return {} unless valid_item_name?(document, review_fm)

          Jekyll::SEO::JsonLdBuilder.build('Review', license: true, document: document, site: site) do |review|
            review.site_author
            review.date_published
            review.site_publisher
            review.review_body_from_fields(field_priority: ['description'])
            review.url

            review.item_reviewed(review_fm['item_type'] || 'Product') do |item|
              item.name review_fm['item_name']
              item.image_url document.data['image']
              item_url = review_fm['item_url']
              item.url item_url if item_url && !item_url.to_s.strip.empty?
              cleaned = clean_description(review_fm['item_description'])
              item.description cleaned if cleaned
            end
          end
        end

        def self.valid_item_name?(document, review_fm)
          item_name = review_fm['item_name']
          return true if item_name && !item_name.to_s.strip.empty?

          id = document.url || document.path || document.relative_path
          Jekyll.logger.error(
            'JSON-LD (GenericReviewGen):',
            "Called for '#{id}' but 'review.item_name' is missing or empty.",
          )
          false
        end

        def self.clean_description(text)
          return nil unless text && !text.to_s.strip.empty?

          Jekyll::Infrastructure::TextProcessingUtils.clean_text_from_html(text)
        end
      end
    end
  end
end
