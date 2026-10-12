# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/seo/generators/generic_review_generator'

# Tests for Jekyll::SEO::Generators::GenericReviewLdGenerator module.
#
# Verifies that the generator correctly creates JSON-LD structured data for generic product reviews.
#
# `review-post` pages have no numeric rating. A Review without reviewRating
# is valid schema.org. Google's review-snippet guidelines list reviewRating
# as required, so these standalone pages do not meet that requirement.
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

  def test_generate_hash_basic_review
    doc = create_doc(
      {
        'layout' => 'post',
        'title' => 'Review of My Gadget',
        'review' => {
          'item_name' => 'My Awesome Gadget',
          'item_type' => 'Product', # Explicitly Product
        },
        'description' => 'This gadget is pretty cool and does things.',
      },
      '/reviews/my-gadget.html',
      'Post content',
      '2024-05-01',
      @post_collection,
    )
    expected = {
      '@context' => 'https://schema.org',
      '@type' => 'Review',
      'license' => 'https://creativecommons.org/licenses/by-sa/4.0/',
      'author' => { '@type' => 'Person', 'name' => 'Reviewer Name', '@id' => 'https://myreviews.com/stuff/resume/#person', 'url' => 'https://myreviews.com/stuff/resume/' },
      'publisher' => { '@type' => 'Person', 'name' => 'Reviewer Name', '@id' => 'https://myreviews.com/stuff/resume/#person', 'url' => 'https://myreviews.com/stuff/resume/' },
      'datePublished' => Time.parse('2024-05-01').xmlschema,
      'reviewBody' => 'Post content',
      'url' => 'https://myreviews.com/stuff/reviews/my-gadget.html',
      'itemReviewed' => {
        '@type' => 'Product',
        'name' => 'My Awesome Gadget',
      },
    }
    assert_equal expected, Jekyll::SEO::Generators::GenericReviewLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_review_with_all_item_fields
    doc = create_doc(
      {
        'layout' => 'post',
        'title' => 'Full Review of Service X',
        'review' => {
          'item_name' => 'Service X',
          'item_type' => 'Service',
          'item_url' => 'https://servicex.com',
          'item_description' => 'A revolutionary new service for tasks.',
        },
        'description' => 'My thoughts on Service X.',
        'image' => '/images/service_x_logo.png', # This becomes itemReviewed.image
      },
      '/reviews/service-x.html',
      'Post content',
      '2024-05-02',
      @post_collection,
    )
    expected = {
      '@context' => 'https://schema.org',
      '@type' => 'Review',
      'license' => 'https://creativecommons.org/licenses/by-sa/4.0/',
      'author' => { '@type' => 'Person', 'name' => 'Reviewer Name', '@id' => 'https://myreviews.com/stuff/resume/#person', 'url' => 'https://myreviews.com/stuff/resume/' },
      'publisher' => { '@type' => 'Person', 'name' => 'Reviewer Name', '@id' => 'https://myreviews.com/stuff/resume/#person', 'url' => 'https://myreviews.com/stuff/resume/' },
      'datePublished' => Time.parse('2024-05-02').xmlschema,
      'reviewBody' => 'Post content',
      'url' => 'https://myreviews.com/stuff/reviews/service-x.html',
      'itemReviewed' => {
        '@type' => 'Service',
        'name' => 'Service X',
        'image' => 'https://myreviews.com/stuff/images/service_x_logo.png',
        'url' => 'https://myreviews.com/stuff/servicex.com', # Jekyll::Infrastructure::UrlUtils will add baseurl if path is relative
        'description' => 'A revolutionary new service for tasks.',
      },
    }
    # Adjust itemReviewed.url if servicex.com was intended as absolute
    # For this test, assume item_url is a path relative to site if not absolute
    expected['itemReviewed']['url'] = if doc.data['review']['item_url'].start_with?('http')
                                        doc.data['review']['item_url']
                                      else
                                        Jekyll::Infrastructure::UrlUtils.absolute_url(doc.data['review']['item_url'], @site)
                                      end

    assert_equal expected, Jekyll::SEO::Generators::GenericReviewLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_review_default_item_type
    doc = create_doc(
      {
        'layout' => 'post',
        'title' => 'Review of Thingy',
        'review' => { 'item_name' => 'A Thingamajig' }, # No item_type, should default to Product
      },
      '/reviews/thingy.html',
      'Post content',
      '2024-05-03',
      @post_collection,
    )
    result_hash = Jekyll::SEO::Generators::GenericReviewLdGenerator.generate_hash(doc, @site)
    assert_equal 'Product', result_hash.dig('itemReviewed', '@type')
    assert_equal 'A Thingamajig', result_hash.dig('itemReviewed', 'name')
  end

  def test_generate_hash_review_missing_optional_fields
    doc = create_doc(
      {
        'layout' => 'post',
        'title' => 'Minimal Review',
        'review' => { 'item_name' => 'Basic Item' },
        # No description, no page.image, no item_url, no item_description
      },
      '/reviews/minimal.html',
      'Post content',
      '2024-05-04',
      @post_collection,
    )
    expected = {
      '@context' => 'https://schema.org',
      '@type' => 'Review',
      'license' => 'https://creativecommons.org/licenses/by-sa/4.0/',
      'author' => { '@type' => 'Person', 'name' => 'Reviewer Name', '@id' => 'https://myreviews.com/stuff/resume/#person', 'url' => 'https://myreviews.com/stuff/resume/' },
      'publisher' => { '@type' => 'Person', 'name' => 'Reviewer Name', '@id' => 'https://myreviews.com/stuff/resume/#person', 'url' => 'https://myreviews.com/stuff/resume/' },
      'datePublished' => Time.parse('2024-05-04').xmlschema,
      'reviewBody' => 'Post content',
      'url' => 'https://myreviews.com/stuff/reviews/minimal.html',
      'itemReviewed' => {
        '@type' => 'Product', # Default
        'name' => 'Basic Item',
      },
    }
    assert_equal expected, Jekyll::SEO::Generators::GenericReviewLdGenerator.generate_hash(doc, @site)
  end

  # reviewBody is the review text itself, not the front-matter summary.
  def test_generate_hash_review_body_is_full_content_not_description
    doc = create_doc(
      {
        'layout' => 'review-post',
        'title' => 'Chair Review',
        'review' => { 'item_name' => 'Chair' },
        'description' => 'A summary.',
      },
      '/reviews/chair.html',
      "<p>First paragraph.</p>\n<p>Second <strong>paragraph</strong>.</p>", # Kramdown separates blocks
      '2024-05-06',
      @post_collection,
    )
    result = Jekyll::SEO::Generators::GenericReviewLdGenerator.generate_hash(doc, @site)
    assert_equal 'First paragraph. Second paragraph.', result['reviewBody']
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
      Jekyll::SEO::Generators::GenericReviewLdGenerator.generate_hash(doc_missing_item_name, @site)
    end

    assert_match '/reviews/bad-data.html', error.message
    assert_match 'review.item_name', error.message
  end
end
