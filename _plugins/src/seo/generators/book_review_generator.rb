# frozen_string_literal: true

require_relative '../json_ld_builder'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD Review schema for book reviews.
      class BookReviewLdGenerator
        def self.generate_hash(document, site)
          new(document, site).generate
        end

        def initialize(document, site)
          @document = document
          @site = site
        end

        def generate
          Jekyll::SEO::JsonLdBuilder.build('Review', license: true, document: @document, site: @site) do |review|
            add_review_fields(review)
            add_item_reviewed(review)
          end
        end

        private

        def add_review_fields(review)
          review.site_author
          review.date_published
          review.site_publisher
          review.rating @document.data['rating']
          review.review_body_from_fields(field_priority: %w[excerpt description content])
          review.url
          review.encoding @document.data['markdown_alternate_href']
        end

        def add_item_reviewed(review)
          review.item_reviewed('Book') do |book|
            add_book_fields(book)
          end
        end

        def add_book_fields(book)
          book.name @document.data['title']
          book.url @document.url
          book.authors @document.data['book_authors']
          book.image @document.data['image']
          book.isbn @document.data['isbn']
          book.date_published @document.data['date_published']
          book.awards @document.data['awards']
          book.series @document.data['series'], @document.data['book_number']
          book.same_as @document.data['same_as_urls']
        end
      end
    end
  end
end
