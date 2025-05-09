# _plugins/utils/json_ld_generators/blog_posting_generator.rb
require_relative '../json_ld_utils'
require_relative '../url_utils'
require 'jekyll' # For logger

module BlogPostingLdGenerator
  def self.generate_hash(document, site)
    data = {
      "@context" => "https://schema.org",
      "@type" => "BlogPosting"
    }

    # Headline
    headline = document.data['title']
    data["headline"] = headline if headline && !headline.strip.empty?

    # Author (Site default)
    author_entity = JsonLdUtils.build_site_person_entity(site)
    data["author"] = author_entity if author_entity

    # Publisher (Site default)
    publisher_entity = JsonLdUtils.build_site_person_entity(site, include_site_url: true)
    data["publisher"] = publisher_entity if publisher_entity

    # Dates
    if document.date
      data["datePublished"] = document.date.to_time.xmlschema
      # Use last_modified_at if available, else fallback to page date
      modified_date_source = document.data['last_modified_at'] || document.date
      data["dateModified"] = modified_date_source.to_time.xmlschema
    end

    # Image
    image_entity = JsonLdUtils.build_image_object_entity(document.data['image'], site)
    data["image"] = image_entity if image_entity

    # URL & mainEntityOfPage
    doc_url_abs = UrlUtils.absolute_url(document.url, site)
    if doc_url_abs && !doc_url_abs.strip.empty?
      data["url"] = doc_url_abs
      data["mainEntityOfPage"] = { "@type" => "WebPage", "@id" => doc_url_abs }
    end

    # Description (Use helper: excerpt -> description, truncate)
    description = JsonLdUtils.extract_descriptive_text(
      document,
      field_priority: ['excerpt', 'description'],
      truncate_options: { words: 50, omission: "..." }
    )
    data["description"] = description if description # Helper already returns nil if empty

    # Article Body (Use helper: content, no truncation)
    article_body = JsonLdUtils.extract_descriptive_text(
      document,
      field_priority: ['content'] # Only check document.content (post-conversion)
    )
    data["articleBody"] = article_body if article_body # Helper already returns nil if empty

    # Keywords (From categories/tags)
    keywords_list = []
    keywords_list.concat(document.data['categories'] || [])
    keywords_list.concat(document.data['tags'] || [])
    keywords_list.uniq!
    data["keywords"] = keywords_list.join(", ") if keywords_list.any?

    # Clean final hash
    JsonLdUtils.cleanup_data_hash!(data)
  end
end