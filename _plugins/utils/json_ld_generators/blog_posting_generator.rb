# frozen_string_literal: true

# _plugins/utils/json_ld_generators/blog_posting_generator.rb
require_relative '../json_ld_utils'
require_relative '../../src/infrastructure/url_utils'
require 'jekyll' # For logger

# Generates JSON-LD BlogPosting schema for blog posts.
module BlogPostingLdGenerator
  def self.generate_hash(document, site)
    data = base_data_hash
    add_headline(data, document)
    add_author_and_publisher(data, site)
    add_dates(data, document)
    add_image(data, document, site)
    add_url_and_main_entity(data, document, site)
    add_description_and_body(data, document)
    add_keywords(data, document)
    JsonLdUtils.cleanup_data_hash!(data)
  end

  private_class_method def self.base_data_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'BlogPosting'
    }
  end

  private_class_method def self.add_headline(data, document)
    headline = document.data['title']
    data['headline'] = headline if headline && !headline.strip.empty?
  end

  private_class_method def self.add_author_and_publisher(data, site)
    author_entity = JsonLdUtils.build_site_person_entity(site)
    data['author'] = author_entity if author_entity

    publisher_entity = JsonLdUtils.build_site_person_entity(site, include_site_url: true)
    data['publisher'] = publisher_entity if publisher_entity
  end

  private_class_method def self.add_dates(data, document)
    return unless document.date

    data['datePublished'] = document.date.to_time.xmlschema
    # Use last_modified_at if available, else fallback to page date
    modified_date_source = document.data['last_modified_at'] || document.date
    data['dateModified'] = modified_date_source.to_time.xmlschema
  end

  private_class_method def self.add_image(data, document, site)
    image_entity = JsonLdUtils.build_image_object_entity(document.data['image'], site)
    data['image'] = image_entity if image_entity
  end

  private_class_method def self.add_url_and_main_entity(data, document, site)
    doc_url_abs = UrlUtils.absolute_url(document.url, site)
    return unless doc_url_abs && !doc_url_abs.strip.empty?

    data['url'] = doc_url_abs
    data['mainEntityOfPage'] = { '@type' => 'WebPage', '@id' => doc_url_abs }
  end

  private_class_method def self.add_description_and_body(data, document)
    add_description(data, document)
    add_article_body(data, document)
  end

  private_class_method def self.add_description(data, document)
    # Description (Use helper: excerpt -> description, truncate)
    description = JsonLdUtils.extract_descriptive_text(
      document,
      field_priority: %w[excerpt description],
      truncate_options: { words: 50, omission: '...' }
    )
    data['description'] = description if description # Helper already returns nil if empty
  end

  private_class_method def self.add_article_body(data, document)
    # Article Body (Use helper: content, no truncation)
    article_body = JsonLdUtils.extract_descriptive_text(
      document,
      field_priority: ['content'] # Only check document.content (post-conversion)
    )
    data['articleBody'] = article_body if article_body # Helper already returns nil if empty
  end

  private_class_method def self.add_keywords(data, document)
    keywords_list = []
    keywords_list.concat(document.data['categories'] || [])
    keywords_list.concat(document.data['tags'] || [])
    keywords_list.uniq!
    data['keywords'] = keywords_list.join(', ') if keywords_list.any?
  end
end
