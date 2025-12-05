# frozen_string_literal: true

# _tests/plugins/utils/test_card_data_extractor_utils.rb
require_relative '../../../test_helper'

# Tests for Jekyll::UI::Cards::CardDataExtractorUtils module.
#
# Verifies that the utility correctly extracts and validates card data from documents.
class TestCardDataExtractorUtils < Minitest::Test
  def setup
    setup_sites_and_contexts
    @silent_logger_stub = create_silent_logger_stub
  end

  def test_extract_base_data_valid_item_no_baseurl
    doc = create_doc({ 'title' => 'Test Post', 'image' => 'images/test.jpg' }, '/test-post.html')
    result = extract_base_data_with_silent_logger(doc, @context_no_baseurl,
                                                  default_title: 'Default', log_tag_type: 'TEST_CARD')

    assert_valid_base_data_result(result, @site_no_baseurl, doc, 'Test Post',
                                  'http://example.com/test-post.html',
                                  'http://example.com/images/test.jpg')
  end

  def test_extract_base_data_valid_item_with_baseurl
    doc = create_doc({ 'title' => 'Blog Post', 'image' => '/assets/image.png' }, '/my-article/')
    result = extract_base_data_with_silent_logger(doc, @context_with_baseurl)

    assert_equal '', result[:log_output]
    assert_equal @site_with_baseurl, result[:site]
    assert_equal 'Blog Post', result[:raw_title]
    assert_equal 'http://example.com/blog/my-article/', result[:absolute_url]
    assert_equal 'http://example.com/blog/assets/image.png', result[:absolute_image_url]
    assert_equal doc.data, result[:data_source_for_keys]
    assert_equal doc.data, result[:data_for_description]
  end

  def test_extract_base_data_item_no_title_uses_default
    doc = create_doc({ 'title' => nil, 'image' => 'img.jpg' }, '/no-title.html')
    result = extract_base_data_with_silent_logger(doc, @context_no_baseurl,
                                                  default_title: 'My Default Title')
    assert_equal '', result[:log_output]
    assert_equal 'My Default Title', result[:raw_title]
  end

  def test_extract_base_data_item_empty_string_title_uses_default
    doc = create_doc({ 'title' => '  ' }, '/empty-title.html')
    result = extract_base_data_with_silent_logger(doc, @context_no_baseurl,
                                                  default_title: 'Another Default')
    assert_equal '', result[:log_output]
    assert_equal 'Another Default', result[:raw_title]
  end

  def test_extract_base_data_item_no_image
    doc = create_doc({ 'title' => 'No Image Here' }, '/no-image.html')
    result = extract_base_data_with_silent_logger(doc, @context_no_baseurl)
    assert_equal '', result[:log_output]
    assert_nil result[:absolute_image_url]
  end

  def test_extract_base_data_item_empty_image_path
    doc = create_doc({ 'title' => 'Test', 'image' => '  ' }, '/item.html')
    result = extract_base_data_with_silent_logger(doc, @context_no_baseurl)
    assert_equal '', result[:log_output]
    assert_nil result[:absolute_image_url]
  end

  def test_extract_base_data_item_empty_url_uses_hash_symbol
    doc = create_doc({ 'title' => 'Test' }, '')
    result = extract_base_data_with_silent_logger(doc, @context_no_baseurl)
    assert_equal '', result[:log_output]
    assert_equal '#', result[:absolute_url]
  end

  def test_extract_base_data_invalid_item_object_does_not_respond_to_data
    @site_no_baseurl.config['plugin_logging']['BAD_ITEM_CARD'] = true
    result, stderr_str = extract_base_data_capturing_io('not_a_doc_object', @context_no_baseurl,
                                                        log_tag_type: 'BAD_ITEM_CARD')

    assert_invalid_item_result(result, @site_no_baseurl, 'BAD_ITEM_CARD',
                               "item_class='String'", 'current.html')
    assert_empty stderr_str
  end

  def test_extract_base_data_invalid_item_object_does_not_respond_to_url
    @site_no_baseurl.config['plugin_logging']['BAD_ITEM_CARD_NO_URL'] = true
    item_no_url = Struct.new(:data).new({ 'title' => 'Some Title' })
    result, stderr_str = extract_base_data_capturing_io(item_no_url, @context_no_baseurl,
                                                        log_tag_type: 'BAD_ITEM_CARD_NO_URL')

    assert_invalid_item_result(result, @site_no_baseurl, 'BAD_ITEM_CARD_NO_URL',
                               "item_class=''", 'current.html')
    assert_empty stderr_str
  end

  def test_extract_base_data_nil_item_object
    @site_no_baseurl.config['plugin_logging']['NIL_ITEM_CARD'] = true
    result, stderr_str = extract_base_data_capturing_io(nil, @context_no_baseurl,
                                                        log_tag_type: 'NIL_ITEM_CARD')

    assert_invalid_item_result(result, @site_no_baseurl, 'NIL_ITEM_CARD',
                               "item_class='NilClass'", 'current.html')
    assert_empty stderr_str
  end

  def test_extract_base_data_missing_context
    expected_msg = '[PLUGIN LOGGER ERROR] Context, Site, or Site Config unavailable for logging. ' \
                   'Original Call: CTX_TEST - warn: Context or Site object unavailable for card data extraction.'

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil, ['PluginLogger:', expected_msg])

    result = nil
    Jekyll.stub :logger, mock_logger do
      result = Jekyll::UI::Cards::CardDataExtractorUtils.extract_base_data(create_doc, nil, log_tag_type: 'CTX_TEST')
    end

    assert_equal '', result[:log_output]
    assert_nil result[:site]
    assert_nil result[:data_source_for_keys]

    mock_logger.verify
  end

  def test_extract_base_data_context_missing_site_register
    expected_msg = '[PLUGIN LOGGER ERROR] Context, Site, or Site Config unavailable for logging. ' \
                   'Original Call: CTX_NO_SITE - warn: Context or Site object unavailable for card data extraction.'

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil, ['PluginLogger:', expected_msg])

    context_no_site = create_context({}, {})
    result = nil
    Jekyll.stub :logger, mock_logger do
      result = Jekyll::UI::Cards::CardDataExtractorUtils.extract_base_data(create_doc, context_no_site, log_tag_type: 'CTX_NO_SITE')
    end

    assert_equal '', result[:log_output]
    assert_nil result[:site]

    mock_logger.verify
  end

  def test_extract_description_html_article_priority
    data_sets = build_article_description_test_data
    assert_article_description_results(data_sets)
  end

  def test_extract_description_html_book_priority
    data_sets = build_book_description_test_data
    assert_book_description_results(data_sets)
  end

  def test_extract_description_html_strips_whitespace
    data_book = { 'excerpt' => Struct.new(:output).new("  <p>Content</p>  \n") }
    assert_equal '<p>Content</p>', Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(data_book, type: :book)

    data_article = { 'description' => '  Article Desc  ' }
    assert_equal 'Article Desc', Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(data_article, type: :article)
  end

  def test_extract_description_html_handles_nil_data_hash
    assert_equal '', Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(nil, type: :article)
    assert_equal '', Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(nil, type: :book)
  end

  def test_extract_description_html_excerpt_as_plain_string
    # This tests line 49 where excerpt exists but doesn't respond to :output
    data_with_string_excerpt = { 'excerpt' => 'Plain string excerpt content' }
    assert_equal 'Plain string excerpt content',
                 Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(data_with_string_excerpt, type: :book)

    # For articles, if description is missing, should fall back to excerpt
    assert_equal 'Plain string excerpt content',
                 Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(data_with_string_excerpt, type: :article)
  end

  def test_extract_base_data_with_drop_object
    # This tests lines 86-87 (the valid_drop? branch)
    # Create a mock Drop that inherits from Jekyll::Drops::Drop
    doc = create_doc({ 'title' => 'Drop Title', 'image' => '/drop_img.jpg' }, '/drop-page.html')
    drop = Jekyll::Drops::DocumentDrop.new(doc)

    result = extract_base_data_with_silent_logger(drop, @context_no_baseurl,
                                                  default_title: 'Default Drop Title')

    assert_equal '', result[:log_output], 'Expected no log output for valid Drop'
    assert_equal @site_no_baseurl, result[:site]
    assert_equal drop, result[:data_source_for_keys], 'data_source should be the Drop itself'
    assert_equal 'Drop Title', result[:raw_title]
    assert_equal 'http://example.com/drop-page.html', result[:absolute_url]
    assert_equal 'http://example.com/drop_img.jpg', result[:absolute_image_url]
  end

  private

  def setup_sites_and_contexts
    @site_with_baseurl = create_site({ 'url' => 'http://example.com', 'baseurl' => '/blog' })
    @site_no_baseurl = create_site({ 'url' => 'http://example.com' })
    @context_with_baseurl = create_context({},
                                           { site: @site_with_baseurl,
                                             page: create_doc({ 'path' => 'current.html' }, '/current.html') })
    @context_no_baseurl = create_context({},
                                         { site: @site_no_baseurl,
                                           page: create_doc({ 'path' => 'current.html' }, '/current.html') })
  end

  def create_silent_logger_stub
    Object.new.tap do |logger|
      def logger.warn(_topic, _message = nil); end
      def logger.error(_topic, _message = nil); end
      def logger.info(_topic, _message = nil); end
      def logger.debug(_topic, _message = nil); end
      def logger.log_level=(_level); end
      def logger.progname=(_name); end
    end
  end

  def extract_base_data_with_silent_logger(item, context, **options)
    Jekyll.stub :logger, @silent_logger_stub do
      Jekyll::UI::Cards::CardDataExtractorUtils.extract_base_data(item, context, **options)
    end
  end

  def extract_base_data_capturing_io(item, context, log_tag_type:)
    result = nil
    _stdout_str, stderr_str = capture_io do
      Jekyll.stub :logger, @silent_logger_stub do
        result = Jekyll::UI::Cards::CardDataExtractorUtils.extract_base_data(item, context, log_tag_type: log_tag_type)
      end
    end
    [result, stderr_str]
  end

  def assert_valid_base_data_result(result, expected_site, doc, expected_title,
                                    expected_url, expected_image_url)
    assert_equal '', result[:log_output], 'Expected no log output for valid item'
    assert_equal expected_site, result[:site]
    assert_equal doc.data, result[:data_source_for_keys], 'data_source_for_keys should be doc.data'
    assert_equal doc.data, result[:data_for_description], 'data_for_description should be doc.data'
    assert_equal expected_title, result[:raw_title]
    assert_equal expected_url, result[:absolute_url]
    assert_equal expected_image_url, result[:absolute_image_url]
  end

  def assert_invalid_item_result(result, expected_site, tag_type, item_class_fragment, source_page)
    refute_empty result[:log_output], 'Expected HTML log comment from extract_base_data'
    expected_pattern = /<!-- \[WARN\] #{tag_type}_FAILURE: Reason='Invalid item_object: .+'\s*#{item_class_fragment}.*SourcePage='#{source_page}' -->/
    assert_match expected_pattern, result[:log_output]
    assert_nil result[:data_source_for_keys]
    assert_nil result[:raw_title]
    assert_equal expected_site, result[:site]
  end

  def build_article_description_test_data
    {
      desc_only: { 'description' => 'Article Description.' },
      excerpt_only: { 'excerpt' => Struct.new(:output).new('<p>Article Excerpt Output</p>') },
      both: { 'description' => 'Article Description Wins.',
              'excerpt' => Struct.new(:output).new('<p>Excerpt Ignored</p>') },
      desc_empty_fallback: { 'description' => '  ',
                             'excerpt' => Struct.new(:output).new('Fallback Excerpt.') },
      neither: {},
      excerpt_nil_output: { 'excerpt' => Struct.new(:output).new(nil) }
    }
  end

  def assert_article_description_results(data_sets)
    assert_equal 'Article Description.',
                 Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(data_sets[:desc_only], type: :article)
    assert_equal '<p>Article Excerpt Output</p>',
                 Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(data_sets[:excerpt_only], type: :article)
    assert_equal 'Article Description Wins.',
                 Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(data_sets[:both], type: :article)
    assert_equal 'Fallback Excerpt.',
                 Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(data_sets[:desc_empty_fallback], type: :article)
    assert_equal '', Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(data_sets[:neither], type: :article)
    assert_equal '', Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(data_sets[:excerpt_nil_output], type: :article)
  end

  def build_book_description_test_data
    {
      desc_only: { 'description' => 'Book Description (ignored).' },
      excerpt_only: { 'excerpt' => Struct.new(:output).new('<p>Book Excerpt Output</p>') },
      both: { 'description' => 'Book Description (ignored).',
              'excerpt' => Struct.new(:output).new('Actual Book Excerpt.') },
      neither: {},
      excerpt_nil_output: { 'excerpt' => Struct.new(:output).new(nil) },
      nil_item_data: nil
    }
  end

  def assert_book_description_results(data_sets)
    assert_equal '', Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(data_sets[:desc_only], type: :book)
    assert_equal '<p>Book Excerpt Output</p>',
                 Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(data_sets[:excerpt_only], type: :book)
    assert_equal 'Actual Book Excerpt.',
                 Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(data_sets[:both], type: :book)
    assert_equal '', Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(data_sets[:neither], type: :book)
    assert_equal '', Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(data_sets[:excerpt_nil_output], type: :book)
    assert_equal '', Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(data_sets[:nil_item_data], type: :book)
  end
end
