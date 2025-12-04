# frozen_string_literal: true

# _plugins/src/seo/generators/book_review_generator_class.rb
require 'jekyll'
require_relative '../json_ld_utils'
require_relative '../../infrastructure/url_utils'
require_relative '../../infrastructure/front_matter_utils'

module Jekyll
  # Helper class to handle book review generation logic
  module SEO
    module Generators
      # Generator class for creating JSON-LD Review schema for book reviews.
      # Handles the detailed logic for building book review structured data.
      class BookReviewGenerator
        def initialize(document, site)
          @document = document
          @site = site
        end

        def generate
          data = build_base_review_data
          data['itemReviewed'] = build_item_reviewed
          # Clean final hash
          Jekyll::SEO::JsonLdUtils.cleanup_data_hash!(data)
        end

        private

        def build_base_review_data
          data = {
            '@context' => 'https://schema.org',
            '@type' => 'Review' # The page itself is a Review
          }
          add_review_metadata(data)
          data
        end

        def add_review_metadata(data)
          add_review_author(data)
          add_review_date_published(data)
          add_review_publisher(data)
          add_review_rating(data)
          add_review_body(data)
          add_review_url(data)
        end

        def add_review_author(data)
          # Review Author (Site default)
          data['author'] = Jekyll::SEO::JsonLdUtils.build_site_person_entity(@site)
        end

        def add_review_date_published(data)
          # Review Publication Date (From page.date)
          data['datePublished'] = @document.date.to_time.xmlschema if @document.date
        end

        def add_review_publisher(data)
          # Review Publisher (Site default)
          data['publisher'] = Jekyll::SEO::JsonLdUtils.build_site_person_entity(@site, include_site_url: true)
        end

        def add_review_rating(data)
          # Review Rating (From page.rating)
          data['reviewRating'] = Jekyll::SEO::JsonLdUtils.build_rating_entity(@document.data['rating'])
        end

        def add_review_body(data)
          # Review Body (Priority: excerpt -> description -> content)
          data['reviewBody'] = extract_review_body
        end

        def add_review_url(data)
          # Review URL (This Page)
          data['url'] = review_page_url
        end

        def extract_review_body
          Jekyll::SEO::JsonLdUtils.extract_descriptive_text(
            @document,
            field_priority: %w[excerpt description content]
            # No truncation specified in original include for book review body
          )
        end

        def review_page_url
          @review_page_url ||= Jekyll::Infrastructure::UrlUtils.absolute_url(@document.url, @site)
        end

        def build_item_reviewed
          item = {
            '@type' => 'Book',
            # Book's name is the page title for book review pages
            'name' => @document.data['title'],
            # The URL for the Book item within the Review should be the review page itself
            'url' => review_page_url
          }

          add_book_details(item)
          Jekyll::SEO::JsonLdUtils.cleanup_data_hash!(item) # Clean nested hash
        end

        def add_book_details(item)
          add_book_authors(item)
          item['image'] = Jekyll::SEO::JsonLdUtils.build_image_object_entity(@document.data['image'], @site)
          add_isbn(item)
          add_book_awards(item)
          add_book_series(item)
        end

        def add_book_authors(item)
          # Get author list using Jekyll::Infrastructure::FrontMatterUtils
          names = Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(@document.data['book_authors'])
          return if names.empty?

          item['author'] = if names.length == 1
                             Jekyll::SEO::JsonLdUtils.build_document_person_entity(names.first)
                           else
                             names.map { |name| Jekyll::SEO::JsonLdUtils.build_document_person_entity(name) }.compact
                           end
        end

        def add_isbn(item)
          # ISBN (From page.isbn)
          isbn = @document.data['isbn']
          item['isbn'] = isbn.to_s.strip if isbn && !isbn.to_s.strip.empty?
        end

        def add_book_awards(item)
          # Book Awards (From page.awards - assuming it's an array)
          awards_input = @document.data['awards']
          if awards_input.is_a?(Array)
            # Clean up array: convert to string, strip, remove nils/empty
            cleaned = awards_input.map(&:to_s).map(&:strip).compact.reject(&:empty?)
            item['award'] = cleaned if cleaned.any?
          elsif awards_input
            log_invalid_awards
          end
        end

        def log_invalid_awards
          id = @document.url || @document.data['path'] || @document.relative_path
          Jekyll.logger.warn(
            'JSON-LD (BookReviewGen):',
            "Front matter 'awards' for '#{id}' is not an Array, skipping awards."
          )
        end

        def add_book_series(item)
          # Book Series Info (From page.series and page.book_number)
          series_entity = Jekyll::SEO::JsonLdUtils.build_book_series_entity(
            @document.data['series'],
            @document.data['book_number']
          )
          item['isPartOf'] = series_entity if series_entity
        end
      end
    end
  end
end
