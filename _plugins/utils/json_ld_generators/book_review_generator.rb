# _plugins/utils/json_ld_generators/book_review_generator.rb
require_relative '../json_ld_utils'
require_relative '../url_utils'
require 'jekyll' # For logger

module BookReviewLdGenerator
  def self.generate_hash(document, site)
    data = {
      "@context" => "https://schema.org",
      "@type" => "Review" # The page itself is a Review
    }

    # Review Author (Site default)
    author_entity = JsonLdUtils.build_site_person_entity(site)
    data["author"] = author_entity if author_entity

    # Review Publication Date (From page.date)
    data["datePublished"] = document.date.to_time.xmlschema if document.date

    # Review Publisher (Site default)
    publisher_entity = JsonLdUtils.build_site_person_entity(site, include_site_url: true)
    data["publisher"] = publisher_entity if publisher_entity

    # Review Rating (From page.rating)
    rating_entity = JsonLdUtils.build_rating_entity(document.data['rating'])
    data["reviewRating"] = rating_entity if rating_entity

    # Review Body (Priority: excerpt -> description -> content)
    review_body = JsonLdUtils.extract_descriptive_text(
      document,
      field_priority: ['excerpt', 'description', 'content']
      # No truncation specified in original include for book review body
    )
    data["reviewBody"] = review_body if review_body

    # Review URL (This Page)
    review_page_url = UrlUtils.absolute_url(document.url, site)
    data["url"] = review_page_url if review_page_url

    # --- Item Reviewed (The Book) ---
    item_reviewed = {
      "@type" => "Book",
      # Book's name is the page title for book review pages
      "name" => document.data['title']
    }
    # The URL for the Book item within the Review should be the review page itself
    item_reviewed["url"] = review_page_url if review_page_url


    # Book Author (From page.book_author)
    book_author_entity = JsonLdUtils.build_document_person_entity(document.data['book_author'])
    item_reviewed["author"] = book_author_entity if book_author_entity

    # Book Image (From page.image)
    book_image_entity = JsonLdUtils.build_image_object_entity(document.data['image'], site)
    item_reviewed["image"] = book_image_entity if book_image_entity # Assign the whole object

    # ISBN (From page.isbn)
    isbn = document.data['isbn']
    item_reviewed["isbn"] = isbn.to_s.strip if isbn && !isbn.to_s.strip.empty?

    # Book Awards (From page.awards - assuming it's an array)
    awards_input = document.data['awards']
    if awards_input.is_a?(Array)
      # Clean up array: convert to string, strip, remove nils/empty
      cleaned_awards = awards_input.map(&:to_s).map(&:strip).compact.reject(&:empty?)
      item_reviewed["award"] = cleaned_awards if cleaned_awards.any?
    elsif awards_input # Log if awards is present but not an array
      doc_identifier = document.url || document.path || document.relative_path
      Jekyll.logger.warn "JSON-LD (BookReviewGen):", "Front matter 'awards' for '#{doc_identifier}' is not an Array, skipping awards."
    end

    # Book Series Info (From page.series and page.book_number)
    series_entity = JsonLdUtils.build_book_series_entity(
      document.data['series'],
      document.data['book_number']
    )
    item_reviewed["isPartOf"] = series_entity if series_entity

    data["itemReviewed"] = JsonLdUtils.cleanup_data_hash!(item_reviewed) # Clean nested hash

    # Clean final hash
    JsonLdUtils.cleanup_data_hash!(data)
  end
end
