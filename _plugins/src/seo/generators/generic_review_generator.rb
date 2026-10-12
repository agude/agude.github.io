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
          validate_item_name!(document, review_fm)

          Jekyll::SEO::JsonLdBuilder.build('Review', license: true, document: document, site: site) do |review|
            # A review-post is a blog post: carry the CreativeWork fields
            # BlogPostingLdGenerator emits, minus the Article-only ones.
            review.headline document.data['title']
            review.site_author
            review.site_publisher
            review.dates
            review.image document.data['image']
            review.review_body_from_fields(field_priority: ['content'])
            review.url
            review.main_entity_of_page
            review.keywords(document.data['categories'], document.data['tags'])
            review.encoding document.data['markdown_alternate_href']
            add_item_reviewed(review, review_fm, document)
          end
        end

        def self.add_item_reviewed(review, review_fm, document)
          review.item_reviewed(review_fm['item_type'] || 'Product') do |item|
            item.name review_fm['item_name']
            item.image_url document.data['image']
            item_url = review_fm['item_url']
            item.url item_url if item_url && !item_url.to_s.strip.empty?
            cleaned = clean_description(review_fm['item_description'])
            item.description cleaned if cleaned
          end
        end

        def self.validate_item_name!(document, review_fm)
          item_name = review_fm['item_name']
          return unless item_name.to_s.strip.empty?

          id = document.url || document.path || document.relative_path
          raise Jekyll::Errors::FatalException,
                "JSON-LD review for '#{id}' requires review.item_name."
        end

        def self.clean_description(text)
          return nil unless text && !text.to_s.strip.empty?

          Jekyll::Infrastructure::TextProcessingUtils.clean_text_from_html(text)
        end
      end
    end
  end
end
