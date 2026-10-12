# frozen_string_literal: true

require_relative '../json_ld_builder'
require_relative '../book_identity_resolver'
require_relative '../book_author_entity_resolver'
require_relative '../../infrastructure/text_processing_utils'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD Review schema for book reviews.
      module BookReviewLdGenerator
        # rubocop:disable-next Metrics/AbcSize -- builder DSL calls inflate branch count
        def self.generate_hash(document, site)
          book_identity_url = Jekyll::SEO::BookIdentityResolver.resolve(document, site)

          Jekyll::SEO::JsonLdBuilder.build('Review', license: true, document: document, site: site) do |review|
            review.site_author
            review.date_published
            review.site_publisher
            review.rating document.data['rating']
            review.review_body_from_fields(field_priority: ['content'])
            review.url
            review.encoding document.data['markdown_alternate_href']

            review.item_reviewed('Book') do |book|
              book.name document.data['title']
              book.node_id book_identity_url, kind: :book
              book.url book_identity_url
              book.author_entities Jekyll::SEO::BookAuthorEntityResolver.resolve(document, site)
              book.image document.data['image']
              book.isbn document.data['isbn']
              book.in_language document.data['language'] || 'en'
              book.date_published document.data['date_published']
              book.awards document.data['awards']
              book.series(
                document.data['series'],
                document.data['book_number'],
                series_path: series_page_path(document, site),
              )
              book.same_as document.data['same_as_urls']
            end
          end
        end

        # The series page URL for the document's `series`, from the link
        # cache. Every series named by a book has a page; a missing one means
        # a typo or a deleted page, so it stops the build like an unresolved
        # author does.
        def self.series_page_path(document, site)
          series_name = document.data['series'].to_s.strip
          return nil if series_name.empty?

          normalized = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(series_name)
          series_data = site&.data&.dig('link_cache', 'series', normalized)
          return series_data['url'] if series_data

          raise Jekyll::Errors::FatalException,
                "JSON-LD Book for #{document.url}: could not resolve series page for #{series_name.inspect}."
        end
        private_class_method :series_page_path
      end
    end
  end
end
