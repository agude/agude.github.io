# frozen_string_literal: true

# _tests/plugins/utils/json_ld_generators/test_generic_review_generator.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/utils/json_ld_generators/generic_review_generator'

class TestGenericReviewLdGenerator < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://myreviews.com',
      'baseurl' => '/stuff',
      'author' => { 'name' => 'Reviewer Name' }
    }
    @site = create_site(@site_config)
    @post_collection = MockCollection.new([], 'posts')
  end

  def test_generate_hash_basic_review
    doc = create_doc(
      {
        'layout' => 'post', 'title' => 'Review of My Gadget',
        'review' => {
          'item_name' => 'My Awesome Gadget',
          'item_type' => 'Product' # Explicitly Product
        },
        'description' => 'This gadget is pretty cool and does things.'
      },
      '/reviews/my-gadget.html', 'Post content', '2024-05-01', @post_collection
    )
    expected = {
      '@context' => 'https://schema.org',
      '@type' => 'Review',
      'author' => { '@type' => 'Person', 'name' => 'Reviewer Name' },
      'publisher' => { '@type' => 'Person', 'name' => 'Reviewer Name', 'url' => 'https://myreviews.com/stuff/' },
      'datePublished' => Time.parse('2024-05-01').xmlschema,
      'reviewBody' => 'This gadget is pretty cool and does things.',
      'url' => 'https://myreviews.com/stuff/reviews/my-gadget.html',
      'itemReviewed' => {
        '@type' => 'Product',
        'name' => 'My Awesome Gadget'
      }
    }
    assert_equal expected, GenericReviewLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_review_with_all_item_fields
    doc = create_doc(
      {
        'layout' => 'post', 'title' => 'Full Review of Service X',
        'review' => {
          'item_name' => 'Service X',
          'item_type' => 'Service',
          'item_url' => 'https://servicex.com',
          'item_description' => 'A revolutionary new service for tasks.'
        },
        'description' => 'My thoughts on Service X.', # This is reviewBody
        'image' => '/images/service_x_logo.png' # This becomes itemReviewed.image
      },
      '/reviews/service-x.html', 'Post content', '2024-05-02', @post_collection
    )
    expected = {
      '@context' => 'https://schema.org',
      '@type' => 'Review',
      'author' => { '@type' => 'Person', 'name' => 'Reviewer Name' },
      'publisher' => { '@type' => 'Person', 'name' => 'Reviewer Name', 'url' => 'https://myreviews.com/stuff/' },
      'datePublished' => Time.parse('2024-05-02').xmlschema,
      'reviewBody' => 'My thoughts on Service X.',
      'url' => 'https://myreviews.com/stuff/reviews/service-x.html',
      'itemReviewed' => {
        '@type' => 'Service',
        'name' => 'Service X',
        'image' => 'https://myreviews.com/stuff/images/service_x_logo.png',
        'url' => 'https://myreviews.com/stuff/servicex.com', # UrlUtils will add baseurl if path is relative
        'description' => 'A revolutionary new service for tasks.'
      }
    }
    # Adjust itemReviewed.url if servicex.com was intended as absolute
    # For this test, assume item_url is a path relative to site if not absolute
    expected['itemReviewed']['url'] = if doc.data['review']['item_url'].start_with?('http')
                                        doc.data['review']['item_url']
                                      else
                                        UrlUtils.absolute_url(doc.data['review']['item_url'], @site)
                                      end

    assert_equal expected, GenericReviewLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_review_default_item_type
    doc = create_doc(
      {
        'layout' => 'post', 'title' => 'Review of Thingy',
        'review' => { 'item_name' => 'A Thingamajig' }, # No item_type, should default to Product
        'description' => 'It is a thing.'
      },
      '/reviews/thingy.html', 'Post content', '2024-05-03', @post_collection
    )
    result_hash = GenericReviewLdGenerator.generate_hash(doc, @site)
    assert_equal 'Product', result_hash.dig('itemReviewed', '@type')
    assert_equal 'A Thingamajig', result_hash.dig('itemReviewed', 'name')
    assert_equal 'It is a thing.', result_hash['reviewBody']
  end

  def test_generate_hash_review_missing_optional_fields
    doc = create_doc(
      {
        'layout' => 'post', 'title' => 'Minimal Review',
        'review' => { 'item_name' => 'Basic Item' }
        # No description, no page.image, no item_url, no item_description
      },
      '/reviews/minimal.html', 'Post content', '2024-05-04', @post_collection
    )
    expected = {
      '@context' => 'https://schema.org',
      '@type' => 'Review',
      'author' => { '@type' => 'Person', 'name' => 'Reviewer Name' },
      'publisher' => { '@type' => 'Person', 'name' => 'Reviewer Name', 'url' => 'https://myreviews.com/stuff/' },
      'datePublished' => Time.parse('2024-05-04').xmlschema,
      'url' => 'https://myreviews.com/stuff/reviews/minimal.html',
      'itemReviewed' => {
        '@type' => 'Product', # Default
        'name' => 'Basic Item'
      }
      # reviewBody will be missing
    }
    assert_equal expected, GenericReviewLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_returns_empty_if_item_name_is_missing_in_generator_guard
    # This test assumes the injector *might* somehow call it,
    # so the generator's internal guard should return empty.
    doc_missing_item_name = create_doc(
      {
        'layout' => 'post', 'title' => 'Bad Review Data',
        'review' => { 'item_type' => 'Product' } # item_name is missing
      },
      '/reviews/bad-data.html', 'Post content', '2024-05-05', @post_collection
    )
    # Mock logger to ensure error is logged by the generator itself
    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil) do |prefix, message|
      prefix == 'JSON-LD (GenericReviewGen):' && message.include?('missing or empty')
    end

    actual_hash = nil
    Jekyll.stub :logger, mock_logger do
      actual_hash = GenericReviewLdGenerator.generate_hash(doc_missing_item_name, @site)
    end

    assert_equal({}, actual_hash)
    mock_logger.verify
  end
end
