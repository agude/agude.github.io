# _plugins/utils/json_ld_generators/generic_review_generator.rb
require_relative '../json_ld_utils'
require_relative '../url_utils'
require 'jekyll' # For logger

module GenericReviewLdGenerator
  def self.generate_hash(document, site)
    # Essential check: review.item_name must exist
    review_fm = document.data['review'] # This should exist due to injector logic
    item_name = review_fm&.dig('item_name') # Safely access item_name

    # The injector already logs if item_name is missing, so generator can assume it's present
    # or return nil if it's unexpectedly missing (though injector should prevent this call).
    # For robustness, we can add a guard here too.
    if item_name.nil? || item_name.to_s.strip.empty?
      doc_identifier = document.url || document.path || document.relative_path
      Jekyll.logger.error "JSON-LD (GenericReviewGen):", "Called for '#{doc_identifier}' but 'review.item_name' is missing or empty. This should have been caught by the injector."
      return {} # Return empty hash if critical data is missing
    end

    data = {
      "@context" => "https://schema.org",
      "@type" => "Review"
    }

    # Review Author (Site default)
    author_entity = JsonLdUtils.build_site_person_entity(site)
    data["author"] = author_entity if author_entity

    # Review Publication Date
    data["datePublished"] = document.date.to_time.xmlschema if document.date

    # Review Publisher (Site default)
    publisher_entity = JsonLdUtils.build_site_person_entity(site, include_site_url: true)
    data["publisher"] = publisher_entity if publisher_entity

    # Review Body (From page.description as per original include logic for generic reviews)
    # No excerpt fallback for generic review body in the original include.
    review_body = JsonLdUtils.extract_descriptive_text(
      document,
      field_priority: ['description'] # Only 'description' for generic review body
      # No truncation specified in original include for generic review body
    )
    data["reviewBody"] = review_body if review_body

    # Review URL (This Page)
    review_page_url = UrlUtils.absolute_url(document.url, site)
    data["url"] = review_page_url if review_page_url

    # Item Reviewed
    item_reviewed = {
      "@type" => review_fm['item_type'] || "Product", # Default to Product
      "name" => item_name # Already checked for presence
    }

    # Item Image (Use page.image if available)
    item_image_entity = JsonLdUtils.build_image_object_entity(document.data['image'], site)
    item_reviewed["image"] = item_image_entity["url"] if item_image_entity # Schema.org expects URL string here

    # Item URL (From front matter if provided)
    item_url_fm = review_fm['item_url']
    if item_url_fm && !item_url_fm.strip.empty?
      item_reviewed["url"] = UrlUtils.absolute_url(item_url_fm, site)
    end

    # Item Description (From front matter if provided)
    item_desc_fm = review_fm['item_description']
    if item_desc_fm && !item_desc_fm.strip.empty?
      # Assuming item_description is text/HTML, not Markdown needing full conversion
      cleaned_item_desc = TextProcessingUtils.clean_text_from_html(item_desc_fm)
      item_reviewed["description"] = cleaned_item_desc unless cleaned_item_desc.empty?
    end

    data["itemReviewed"] = JsonLdUtils.cleanup_data_hash!(item_reviewed) # Clean nested hash

    # Clean final hash
    JsonLdUtils.cleanup_data_hash!(data)
  end
end
