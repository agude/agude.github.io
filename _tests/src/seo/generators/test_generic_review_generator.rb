# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::SEO::Generators::GenericReviewLdGenerator module.
#
# Verifies that the generator correctly creates JSON-LD structured data for generic product reviews.
#
# `review-post` pages have no numeric rating. A Review without reviewRating
# is valid schema.org. Google's review-snippet guidelines list reviewRating
# as required, so these standalone pages do not meet that requirement. The
# page is still a blog post, so the Review carries the CreativeWork fields a
# BlogPosting would have (headline, image, dateModified, mainEntityOfPage,
# keywords, encoding). articleBody is an Article property and does not apply
# to Review; reviewBody, the full post text, fills that role.
class TestGenericReviewLdGenerator < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://myreviews.com',
      'baseurl' => '/stuff',
      'author' => { 'name' => 'Reviewer Name', 'url' => '/resume/' },
    }
    @site = create_site(@site_config)
    @post_collection = MockCollection.new([], 'posts')
  end

  def test_generate_hash_review_with_all_item_fields
    doc = create_doc(
      {
        'layout' => 'review-post',
        'title' => 'Full Review of Service X',
        'review' => {
          'item_name' => 'Service X',
          'item_type' => 'Service',
          'item_url' => 'https://servicex.com',
          'item_description' => 'A revolutionary new service for tasks.',
        },
        'description' => 'My thoughts on Service X.',
        'image' => '/images/service_x_logo.png',
        'categories' => ['Reviews'],
        'tags' => ['services'],
        'markdown_alternate_href' => '/reviews/service-x.md',
        'last_modified_at' => Time.utc(2025, 3, 15),
      },
      '/reviews/service-x.html',
      "<p>First paragraph.</p>\n<p>Second <strong>paragraph</strong>.</p>",
      '2024-05-02',
      @post_collection,
    )
    expected = {
      '@context' => 'https://schema.org',
      '@type' => 'Review',
      'license' => 'https://creativecommons.org/licenses/by-sa/4.0/',
      'author' => { '@type' => 'Person', 'name' => 'Reviewer Name', '@id' => 'https://myreviews.com/stuff/resume/#person', 'url' => 'https://myreviews.com/stuff/resume/' },
      'publisher' => { '@type' => 'Person', 'name' => 'Reviewer Name', '@id' => 'https://myreviews.com/stuff/resume/#person', 'url' => 'https://myreviews.com/stuff/resume/' },
      'headline' => 'Full Review of Service X',
      'datePublished' => Time.parse('2024-05-02').xmlschema,
      'dateModified' => '2025-03-15T00:00:00Z',
      'image' => { '@type' => 'ImageObject', 'url' => 'https://myreviews.com/stuff/images/service_x_logo.png' },
      'reviewBody' => 'First paragraph. Second paragraph.',
      'keywords' => 'Reviews, services',
      'encoding' => {
        '@type' => 'MediaObject',
        'encodingFormat' => 'text/markdown',
        'contentUrl' => 'https://myreviews.com/stuff/reviews/service-x.md',
      },
      'url' => 'https://myreviews.com/stuff/reviews/service-x.html',
      'mainEntityOfPage' => { '@type' => 'WebPage', '@id' => 'https://myreviews.com/stuff/reviews/service-x.html' },
      'itemReviewed' => {
        '@type' => 'Service',
        'name' => 'Service X',
        'image' => 'https://myreviews.com/stuff/images/service_x_logo.png',
        'url' => 'https://servicex.com',
        'description' => 'A revolutionary new service for tasks.',
      },
    }
    assert_equal expected, generate(doc)
  end

  def test_generate_hash_review_missing_optional_fields
    doc = create_doc(
      { 'layout' => 'review-post', 'title' => 'Minimal Review', 'review' => { 'item_name' => 'Basic Item' } },
      '/reviews/minimal.html',
      'Post content',
      '2024-05-04',
      @post_collection,
    )

    result = generate(doc)
    assert_equal({ '@type' => 'Product', 'name' => 'Basic Item' }, result['itemReviewed'])
    assert_equal 'Post content', result['reviewBody']
    assert_equal result['datePublished'], result['dateModified']
    assert_empty result.keys & %w[description image keywords encoding reviewRating]

    doc.data['review'].merge!('item_type' => 'Product', 'item_url' => ' ', 'item_description' => ' ')
    assert_equal result, generate(doc)
  end

  def test_generate_hash_rejects_missing_item_name
    doc_missing_item_name = create_doc(
      {
        'layout' => 'review-post',
        'title' => 'Bad Review Data',
        'review' => { 'item_type' => 'Product' }, # item_name is missing
      },
      '/reviews/bad-data.html',
      'Post content',
      '2024-05-05',
      @post_collection,
    )
    error = assert_raises(Jekyll::Errors::FatalException) do
      generate(doc_missing_item_name)
    end

    assert_match '/reviews/bad-data.html', error.message
    assert_match 'review.item_name', error.message
  end

  private

  def generate(doc)
    Jekyll::SEO::JsonLdInjector.generate_hash(doc, @site)
  end
end
