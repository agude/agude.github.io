# frozen_string_literal: true

require_relative '../../test_helper'

# Tests for Jekyll::SEO::JsonLdBuilder class.
# rubocop:disable Style/SymbolProc -- builder DSL requires block form
class TestJsonLdBuilder < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://example.com',
      'baseurl' => '/blog',
      'title' => 'Test Site',
      'author' => { 'name' => 'Site Author' },
    }
    @site = create_site(@site_config)

    @doc_data = {
      'title' => 'Test Document',
      'description' => 'A test description.',
      'image' => '/images/test.jpg',
      'date' => Time.parse('2024-03-15'),
    }
    @document = create_doc(@doc_data, '/test-doc.html')
  end

  # --- Basic Construction ---

  def test_build_returns_hash_with_context_and_type
    result = Jekyll::SEO::JsonLdBuilder.build('BlogPosting')
    assert_equal 'https://schema.org', result['@context']
    assert_equal 'BlogPosting', result['@type']
  end

  def test_build_with_license_adds_license_url
    result = Jekyll::SEO::JsonLdBuilder.build('Review', license: true)
    assert_equal 'https://creativecommons.org/licenses/by-sa/4.0/', result['license']
  end

  def test_build_without_license_omits_license
    result = Jekyll::SEO::JsonLdBuilder.build('WebPage')
    refute result.key?('license')
  end

  def test_build_with_block_yields_builder
    yielded = nil
    Jekyll::SEO::JsonLdBuilder.build('Article') do |builder|
      yielded = builder
    end
    assert_instance_of Jekyll::SEO::JsonLdBuilder, yielded
  end

  # --- Context Binding ---

  def test_build_binds_document_and_site
    Jekyll::SEO::JsonLdBuilder.build('BlogPosting', document: @document, site: @site) do |schema|
      assert_equal @document, schema.document
      assert_equal @site, schema.site
    end
  end

  # --- Simple Fields via method_missing ---

  def test_simple_field_sets_value
    result = Jekyll::SEO::JsonLdBuilder.build('Article') do |schema|
      schema.headline 'My Headline'
    end
    assert_equal 'My Headline', result['headline']
  end

  def test_snake_case_converts_to_camel_case
    result = Jekyll::SEO::JsonLdBuilder.build('Article') do |schema|
      schema.date_published '2024-03-15'
      schema.word_count 500
    end
    assert_equal '2024-03-15', result['datePublished']
    assert_equal 500, result['wordCount']
  end

  def test_nil_value_is_not_added
    result = Jekyll::SEO::JsonLdBuilder.build('Article') do |schema|
      schema.headline nil
    end
    refute result.key?('headline')
  end

  def test_empty_string_is_not_added
    result = Jekyll::SEO::JsonLdBuilder.build('Article') do |schema|
      schema.headline ''
      schema.name '   '
    end
    refute result.key?('headline')
    refute result.key?('name')
  end

  def test_whitespace_is_stripped
    result = Jekyll::SEO::JsonLdBuilder.build('Article') do |schema|
      schema.headline '  My Title  '
    end
    assert_equal 'My Title', result['headline']
  end

  def test_method_missing_preserves_arrays_and_booleans
    result = Jekyll::SEO::JsonLdBuilder.build('Product') do |schema|
      schema.offers [{ 'price' => 10 }]
      schema.is_family_friendly true
    end
    assert_equal [{ 'price' => 10 }], result['offers']
    assert_equal true, result['isFamilyFriendly']
  end

  # --- Explicit URL Method ---

  def test_url_uses_bound_document_and_site
    result = Jekyll::SEO::JsonLdBuilder.build('Article', document: @document, site: @site) do |schema|
      schema.url
    end
    assert_equal 'https://example.com/blog/test-doc.html', result['url']
  end

  def test_url_with_override
    result = Jekyll::SEO::JsonLdBuilder.build('Article', document: @document, site: @site) do |schema|
      schema.url '/custom-path.html'
    end
    assert_equal 'https://example.com/blog/custom-path.html', result['url']
  end

  # --- Site Author Method ---

  def test_site_author_builds_person_entity
    result = Jekyll::SEO::JsonLdBuilder.build('Article', site: @site) do |schema|
      schema.site_author
    end
    expected = { '@type' => 'Person', 'name' => 'Site Author' }
    assert_equal expected, result['author']
  end

  def test_site_author_with_url
    result = Jekyll::SEO::JsonLdBuilder.build('Article', site: @site) do |schema|
      schema.site_author include_url: true
    end
    assert_equal 'https://example.com/blog/', result['author']['url']
  end

  def test_site_publisher_builds_person_with_url
    result = Jekyll::SEO::JsonLdBuilder.build('Article', site: @site) do |schema|
      schema.site_publisher
    end
    expected = {
      '@type' => 'Person',
      'name' => 'Site Author',
      'url' => 'https://example.com/blog/',
    }
    assert_equal expected, result['publisher']
  end

  # --- Image Method ---

  def test_image_builds_image_object
    result = Jekyll::SEO::JsonLdBuilder.build('Article', site: @site) do |schema|
      schema.image '/images/photo.jpg'
    end
    expected = {
      '@type' => 'ImageObject',
      'url' => 'https://example.com/blog/images/photo.jpg',
    }
    assert_equal expected, result['image']
  end

  def test_image_nil_is_not_added
    result = Jekyll::SEO::JsonLdBuilder.build('Article', site: @site) do |schema|
      schema.image nil
    end
    refute result.key?('image')
  end

  def test_image_empty_string_is_not_added
    result = Jekyll::SEO::JsonLdBuilder.build('Article', site: @site) do |schema|
      schema.image ''
    end
    refute result.key?('image')
  end

  # --- Authors Method (handles string or array) ---

  def test_authors_single_string
    result = Jekyll::SEO::JsonLdBuilder.build('Book') do |schema|
      schema.authors 'Jane Doe'
    end
    expected = { '@type' => 'Person', 'name' => 'Jane Doe' }
    assert_equal expected, result['author']
  end

  def test_authors_array
    result = Jekyll::SEO::JsonLdBuilder.build('Book') do |schema|
      schema.authors ['Jane Doe', 'John Smith']
    end
    expected = [
      { '@type' => 'Person', 'name' => 'Jane Doe' },
      { '@type' => 'Person', 'name' => 'John Smith' },
    ]
    assert_equal expected, result['author']
  end

  def test_authors_empty_array_not_added
    result = Jekyll::SEO::JsonLdBuilder.build('Book') do |schema|
      schema.authors []
    end
    refute result.key?('author')
  end

  def test_authors_nil_not_added
    result = Jekyll::SEO::JsonLdBuilder.build('Book') do |schema|
      schema.authors nil
    end
    refute result.key?('author')
  end

  # --- Rating Method ---

  def test_rating_builds_rating_entity
    result = Jekyll::SEO::JsonLdBuilder.build('Review') do |schema|
      schema.rating 4
    end
    expected = {
      '@type' => 'Rating',
      'ratingValue' => '4',
      'bestRating' => '5',
      'worstRating' => '1',
    }
    assert_equal expected, result['reviewRating']
  end

  def test_rating_zero_not_added
    result = Jekyll::SEO::JsonLdBuilder.build('Review') do |schema|
      schema.rating 0
    end
    refute result.key?('reviewRating')
  end

  # --- Series Method ---

  def test_series_builds_book_series_entity
    result = Jekyll::SEO::JsonLdBuilder.build('Book') do |schema|
      schema.series 'The Expanse', 3
    end
    expected = {
      '@type' => 'BookSeries',
      'name' => 'The Expanse',
      'position' => '3',
    }
    assert_equal expected, result['isPartOf']
  end

  def test_series_without_position
    result = Jekyll::SEO::JsonLdBuilder.build('Book') do |schema|
      schema.series 'Dune'
    end
    expected = { '@type' => 'BookSeries', 'name' => 'Dune' }
    assert_equal expected, result['isPartOf']
  end

  def test_series_nil_not_added
    result = Jekyll::SEO::JsonLdBuilder.build('Book') do |schema|
      schema.series nil
    end
    refute result.key?('isPartOf')
  end

  # --- Dates Method ---

  def test_dates_from_document
    doc = create_doc({ 'date' => Time.parse('2024-03-15T10:30:00Z') }, '/post.html')
    result = Jekyll::SEO::JsonLdBuilder.build('BlogPosting', document: doc) do |schema|
      schema.dates
    end
    assert_equal '2024-03-15T10:30:00Z', result['datePublished']
    assert_equal '2024-03-15T10:30:00Z', result['dateModified']
  end

  def test_dates_with_last_modified
    doc = create_doc(
      {
        'date' => Time.parse('2024-03-15T10:30:00Z'),
        'last_modified_at' => Time.parse('2024-04-20T14:00:00Z'),
      },
      '/post.html',
    )
    result = Jekyll::SEO::JsonLdBuilder.build('BlogPosting', document: doc) do |schema|
      schema.dates
    end
    assert_equal '2024-03-15T10:30:00Z', result['datePublished']
    assert_equal '2024-04-20T14:00:00Z', result['dateModified']
  end

  # --- Nested Blocks ---

  def test_nested_block_omits_context
    result = Jekyll::SEO::JsonLdBuilder.build('Review') do |review|
      review.item_reviewed('Book') do |book|
        book.name 'Dune'
      end
    end
    assert_equal 'https://schema.org', result['@context']
    refute result['itemReviewed'].key?('@context')
    assert_equal 'Book', result['itemReviewed']['@type']
    assert_equal 'Dune', result['itemReviewed']['name']
  end

  def test_deeply_nested_blocks
    result = Jekyll::SEO::JsonLdBuilder.build('Review', site: @site) do |review|
      review.item_reviewed('Book') do |book|
        book.name 'Dune'
        book.author('Person') do |person|
          person.name 'Frank Herbert'
        end
      end
    end
    author = result['itemReviewed']['author']
    assert_equal 'Person', author['@type']
    assert_equal 'Frank Herbert', author['name']
    refute author.key?('@context')
  end

  def test_nested_block_inherits_site_context
    result = Jekyll::SEO::JsonLdBuilder.build('Review', site: @site) do |review|
      review.item_reviewed('Book') do |book|
        book.image '/images/dune.jpg'
      end
    end
    assert_equal 'https://example.com/blog/images/dune.jpg', result['itemReviewed']['image']['url']
  end

  def test_empty_nested_block_not_added
    result = Jekyll::SEO::JsonLdBuilder.build('Review') do |review|
      review.item_reviewed('Book') do |_book|
        # No fields added
      end
    end
    refute result.key?('itemReviewed')
  end

  # --- is_part_of_website Helper ---

  def test_is_part_of_website
    result = Jekyll::SEO::JsonLdBuilder.build('CollectionPage', site: @site) do |schema|
      schema.is_part_of_website
    end
    expected = {
      '@type' => 'WebSite',
      'name' => 'Test Site',
      'url' => 'https://example.com/blog/',
    }
    assert_equal expected, result['isPartOf']
  end

  # --- Main Entity of Page ---

  def test_main_entity_of_page
    result = Jekyll::SEO::JsonLdBuilder.build('BlogPosting', document: @document, site: @site) do |schema|
      schema.main_entity_of_page
    end
    expected = {
      '@type' => 'WebPage',
      '@id' => 'https://example.com/blog/test-doc.html',
    }
    assert_equal expected, result['mainEntityOfPage']
  end

  # --- Keywords Method ---

  def test_keywords_from_categories_and_tags
    result = Jekyll::SEO::JsonLdBuilder.build('BlogPosting') do |schema|
      schema.keywords(%w[tech ruby], %w[jekyll seo])
    end
    assert_equal 'tech, ruby, jekyll, seo', result['keywords']
  end

  def test_keywords_deduplicates
    result = Jekyll::SEO::JsonLdBuilder.build('BlogPosting') do |schema|
      schema.keywords(%w[tech ruby], %w[ruby seo])
    end
    assert_equal 'tech, ruby, seo', result['keywords']
  end

  def test_keywords_empty_not_added
    result = Jekyll::SEO::JsonLdBuilder.build('BlogPosting') do |schema|
      schema.keywords([], [])
    end
    refute result.key?('keywords')
  end

  # --- Encoding Method ---

  def test_encoding_builds_media_object
    result = Jekyll::SEO::JsonLdBuilder.build('BlogPosting', site: @site) do |schema|
      schema.encoding '/posts/my-post.md'
    end
    expected = {
      '@type' => 'MediaObject',
      'encodingFormat' => 'text/markdown',
      'contentUrl' => 'https://example.com/blog/posts/my-post.md',
    }
    assert_equal expected, result['encoding']
  end

  def test_encoding_nil_not_added
    result = Jekyll::SEO::JsonLdBuilder.build('BlogPosting', site: @site) do |schema|
      schema.encoding nil
    end
    refute result.key?('encoding')
  end

  # --- Description Method ---

  def test_description_from_document
    doc = create_doc({ 'description' => '<p>A <strong>test</strong> description.</p>' }, '/doc.html')
    result = Jekyll::SEO::JsonLdBuilder.build('Article', document: doc) do |schema|
      schema.description
    end
    assert_equal 'A test description.', result['description']
  end

  def test_description_with_override
    result = Jekyll::SEO::JsonLdBuilder.build('Article') do |schema|
      schema.description 'Custom description'
    end
    assert_equal 'Custom description', result['description']
  end

  # --- Same As Method ---

  def test_same_as_with_array
    result = Jekyll::SEO::JsonLdBuilder.build('Person') do |schema|
      schema.same_as ['https://twitter.com/user', 'https://github.com/user']
    end
    assert_equal ['https://twitter.com/user', 'https://github.com/user'], result['sameAs']
  end

  def test_same_as_cleans_array
    result = Jekyll::SEO::JsonLdBuilder.build('Person') do |schema|
      schema.same_as ['https://twitter.com/user', '', nil, '  ']
    end
    assert_equal ['https://twitter.com/user'], result['sameAs']
  end

  def test_same_as_empty_not_added
    result = Jekyll::SEO::JsonLdBuilder.build('Person') do |schema|
      schema.same_as []
    end
    refute result.key?('sameAs')
  end

  # --- Awards Method ---

  def test_awards_with_array
    result = Jekyll::SEO::JsonLdBuilder.build('Book') do |schema|
      schema.awards ['Hugo Award', 'Nebula Award']
    end
    assert_equal ['Hugo Award', 'Nebula Award'], result['award']
  end

  # --- require! Validation ---

  def test_require_raises_on_missing_field
    error = assert_raises(Jekyll::Errors::FatalException) do
      Jekyll::SEO::JsonLdBuilder.build('BlogPosting') do |schema|
        schema.require! :headline
      end
    end
    assert_includes error.message, 'headline'
    assert_includes error.message, 'BlogPosting'
  end

  def test_require_no_error_when_field_present
    result = Jekyll::SEO::JsonLdBuilder.build('BlogPosting') do |schema|
      schema.headline 'My Post'
      schema.require! :headline
    end
    assert_equal 'My Post', result['headline']
  end

  def test_require_multiple_fields_lists_all_missing
    error = assert_raises(Jekyll::Errors::FatalException) do
      Jekyll::SEO::JsonLdBuilder.build('BlogPosting') do |schema|
        schema.require! :headline, :date_published
      end
    end
    assert_includes error.message, 'headline'
    assert_includes error.message, 'date_published'
  end

  def test_require_converts_snake_case_to_camel_case
    error = assert_raises(Jekyll::Errors::FatalException) do
      Jekyll::SEO::JsonLdBuilder.build('BlogPosting') do |schema|
        schema.require! :date_published
      end
    end
    assert_includes error.message, 'date_published'
  end

  # --- Raw Escape Hatch ---

  def test_raw_sets_field_directly
    result = Jekyll::SEO::JsonLdBuilder.build('Thing') do |schema|
      schema.raw 'customField', { nested: 'value' }
    end
    assert_equal({ nested: 'value' }, result['customField'])
  end

  # --- About Method (for series pages) ---

  def test_about_builds_nested_type
    result = Jekyll::SEO::JsonLdBuilder.build('CollectionPage') do |schema|
      schema.about 'BookSeries', 'The Expanse'
    end
    expected = { '@type' => 'BookSeries', 'name' => 'The Expanse' }
    assert_equal expected, result['about']
  end

  def test_about_nil_not_added
    result = Jekyll::SEO::JsonLdBuilder.build('CollectionPage') do |schema|
      schema.about 'BookSeries', nil
    end
    refute result.key?('about')
  end

  # --- Cleanup Integration ---

  def test_final_hash_is_cleaned
    result = Jekyll::SEO::JsonLdBuilder.build('Article') do |schema|
      schema.headline 'Title'
      schema.raw 'emptyNested', { 'a' => nil, 'b' => '' }
    end
    assert_equal({}, result['emptyNested'])
  end
end
# rubocop:enable Style/SymbolProc
