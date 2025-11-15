# _tests/plugins/utils/test_card_data_extractor_utils.rb
require_relative '../../test_helper'

class TestCardDataExtractorUtils < Minitest::Test
  def setup
    @site_with_baseurl = create_site({ 'url' => 'http://example.com', 'baseurl' => '/blog' })
    @site_no_baseurl = create_site({ 'url' => 'http://example.com' })
    @context_with_baseurl = create_context({}, { site: @site_with_baseurl, page: create_doc({ 'path' => 'current.html' }, '/current.html') }) # Added path
    @context_no_baseurl = create_context({}, { site: @site_no_baseurl, page: create_doc({ 'path' => 'current.html' }, '/current.html') }) # Added path

    # General silent logger for tests not focusing on specific log output content
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end

      def logger.log_level=(level); end

      def logger.progname=(name); end
    end
  end

  # Helper to strip ANSI escape codes
  def strip_ansi(str)
    str.gsub(/\e\[([;\d]+)?m/, '')
  end

  # --- Tests for extract_base_data ---

  def test_extract_base_data_valid_item_no_baseurl
    doc = create_doc(
      { 'title' => 'Test Post', 'image' => 'images/test.jpg' },
      '/test-post.html'
    )
    result = nil
    Jekyll.stub :logger, @silent_logger_stub do
      result = CardDataExtractorUtils.extract_base_data(doc, @context_no_baseurl, default_title: 'Default',
                                                                                  log_tag_type: 'TEST_CARD')
    end

    assert_equal '', result[:log_output], 'Expected no log output for valid item'
    assert_equal @site_no_baseurl, result[:site]
    # If item is Jekyll::Document, data_source_for_keys is doc.data
    assert_equal doc.data, result[:data_source_for_keys], 'data_source_for_keys should be doc.data'
    assert_equal doc.data, result[:data_for_description], 'data_for_description should be doc.data'
    assert_equal 'Test Post', result[:raw_title]
    assert_equal 'http://example.com/test-post.html', result[:absolute_url]
    assert_equal 'http://example.com/images/test.jpg', result[:absolute_image_url]
  end

  def test_extract_base_data_valid_item_with_baseurl
    doc = create_doc(
      { 'title' => 'Blog Post', 'image' => '/assets/image.png' }, # Image path starts with /
      '/my-article/' # URL also starts with /
    )
    result = nil
    Jekyll.stub :logger, @silent_logger_stub do
      result = CardDataExtractorUtils.extract_base_data(doc, @context_with_baseurl)
    end

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
    result = nil
    Jekyll.stub :logger, @silent_logger_stub do
      result = CardDataExtractorUtils.extract_base_data(doc, @context_no_baseurl, default_title: 'My Default Title')
    end
    assert_equal '', result[:log_output]
    assert_equal 'My Default Title', result[:raw_title]
  end

  def test_extract_base_data_item_empty_string_title_uses_default
    doc = create_doc({ 'title' => '  ' }, '/empty-title.html') # Title is whitespace only
    result = nil
    Jekyll.stub :logger, @silent_logger_stub do
      result = CardDataExtractorUtils.extract_base_data(doc, @context_no_baseurl, default_title: 'Another Default')
    end
    assert_equal '', result[:log_output]
    assert_equal 'Another Default', result[:raw_title] # Now expects default
  end

  def test_extract_base_data_item_no_image
    doc = create_doc({ 'title' => 'No Image Here' }, '/no-image.html')
    result = nil
    Jekyll.stub :logger, @silent_logger_stub do
      result = CardDataExtractorUtils.extract_base_data(doc, @context_no_baseurl)
    end
    assert_equal '', result[:log_output]
    assert_nil result[:absolute_image_url]
  end

  def test_extract_base_data_item_empty_image_path
    doc = create_doc({ 'title' => 'Test', 'image' => '  ' }, '/item.html')
    result = nil
    Jekyll.stub :logger, @silent_logger_stub do
      result = CardDataExtractorUtils.extract_base_data(doc, @context_no_baseurl)
    end
    assert_equal '', result[:log_output]
    assert_nil result[:absolute_image_url] # Empty string for image path results in nil absolute_image_url
  end

  def test_extract_base_data_item_empty_url_uses_hash_symbol
    doc = create_doc({ 'title' => 'Test' }, '') # Empty URL string for the document
    result = nil
    Jekyll.stub :logger, @silent_logger_stub do
      result = CardDataExtractorUtils.extract_base_data(doc, @context_no_baseurl)
    end
    assert_equal '', result[:log_output]
    assert_equal '#', result[:absolute_url]
  end

  def test_extract_base_data_invalid_item_object_does_not_respond_to_data
    @site_no_baseurl.config['plugin_logging']['BAD_ITEM_CARD'] = true
    result = nil
    _stdout_str, stderr_str = capture_io do # Capture stderr for PluginLoggerUtils internal error
      Jekyll.stub :logger, @silent_logger_stub do # Stub for extract_base_data's own logger calls
        result = CardDataExtractorUtils.extract_base_data('not_a_doc_object', @context_no_baseurl,
                                                          log_tag_type: 'BAD_ITEM_CARD')
      end
    end

    # PluginLoggerUtils called by extract_base_data will get a valid context, so it produces an HTML comment
    refute_empty result[:log_output], 'Expected HTML log comment from extract_base_data'
    assert_match %r{<!-- \[WARN\] BAD_ITEM_CARD_FAILURE: Reason='Invalid item_object: Expected a Jekyll Document/Page or Drop with \.url and data access capabilities\.'\s*item_class='String'.*SourcePage='current\.html' -->},
                 result[:log_output]
    assert_nil result[:data_source_for_keys]
    assert_nil result[:raw_title]
    assert_equal @site_no_baseurl, result[:site]
    assert_empty stderr_str
  end

  def test_extract_base_data_invalid_item_object_does_not_respond_to_url
    @site_no_baseurl.config['plugin_logging']['BAD_ITEM_CARD_NO_URL'] = true
    item_no_url = Struct.new(:data).new({ 'title' => 'Some Title' })
    result = nil
    _stdout_str, stderr_str = capture_io do
      Jekyll.stub :logger, @silent_logger_stub do
        result = CardDataExtractorUtils.extract_base_data(item_no_url, @context_no_baseurl,
                                                          log_tag_type: 'BAD_ITEM_CARD_NO_URL')
      end
    end

    refute_empty result[:log_output]
    assert_match %r{<!-- \[WARN\] BAD_ITEM_CARD_NO_URL_FAILURE: Reason='Invalid item_object: Expected a Jekyll Document/Page or Drop with \.url and data access capabilities\.'\s*item_class=''.*SourcePage='current\.html' -->},
                 result[:log_output]
    assert_equal @site_no_baseurl, result[:site]
    assert_empty stderr_str
  end

  def test_extract_base_data_nil_item_object
    @site_no_baseurl.config['plugin_logging']['NIL_ITEM_CARD'] = true
    result = nil
    _stdout_str, stderr_str = capture_io do
      Jekyll.stub :logger, @silent_logger_stub do
        result = CardDataExtractorUtils.extract_base_data(nil, @context_no_baseurl, log_tag_type: 'NIL_ITEM_CARD')
      end
    end
    refute_empty result[:log_output]
    assert_match %r{<!-- \[WARN\] NIL_ITEM_CARD_FAILURE: Reason='Invalid item_object: Expected a Jekyll Document/Page or Drop with \.url and data access capabilities\.'\s*item_class='NilClass'.*SourcePage='current\.html' -->},
                 result[:log_output]
    assert_equal @site_no_baseurl, result[:site]
    assert_empty stderr_str
  end

  def test_extract_base_data_missing_context
    result_nil_context = nil
    # Capture STDERR because PluginLoggerUtils will log its internal error there when context is nil
    _stdout_str, stderr_str = capture_io do
      # PluginLoggerUtils.log_liquid_failure handles nil context by logging to STDERR
      # and returning an empty string for the HTML comment.
      # The extract_base_data method will capture this empty string in log_output.
      # To make this test more robust for checking the *intent* if context was available,
      # we'd need a way for PluginLoggerUtils to "know" about a site config for logging
      # even if context is nil. This is a limitation of the current logging setup.
      # For now, we expect log_output to be non-empty due to the internal logger error.
      # The actual content of log_output here will be "" because PluginLoggerUtils returns ""
      # when context is nil. The STDERR output is what indicates the problem.
      # Let's adjust the test to reflect that log_output will be the specific message from extract_base_data.
      # We need to enable logging for the tag type on some site instance for PluginLoggerUtils to produce a comment.
      # This test is tricky because the thing being tested (extract_base_data) calls the logger,
      # and the logger itself needs a context.
      # If context is nil, PluginLoggerUtils logs its own error and returns "".
      # extract_base_data then assigns this "" to log_output.
      # The test should check that extract_base_data correctly identifies the nil context.
      # The log message from extract_base_data itself is what we assert.

      # To test the log message from extract_base_data, we need a valid context for PluginLoggerUtils to work.
      # This means we can't test the "context is nil" path of extract_base_data AND get its specific log message
      # through the normal PluginLoggerUtils HTML comment mechanism simultaneously.
      # The PluginLoggerUtils will log its own error to STDERR if context is nil.
      # Let's simplify: extract_base_data should return a log message if context is nil.

      # Create a site object just to enable logging for the test
      create_site('plugin_logging' => { 'CTX_TEST' => true })
      # Create a context that *has* this site, so PluginLoggerUtils can work if called
      # But we will pass `nil` as context to `extract_base_data`
      # This is still a bit convoluted. The primary check is that extract_base_data handles nil context.

      # Re-think: The log_failure in extract_base_data will get nil context.
      # PluginLoggerUtils will then log its own internal error to STDERR and return "".
      # So, result_nil_context[:log_output] will be "".
      # The important thing is that extract_base_data *tried* to log.
      # We can't easily assert the content of that log_output if context is truly nil for PluginLoggerUtils.

      # Let's test the return structure when context is nil.
      result_nil_context = CardDataExtractorUtils.extract_base_data(create_doc, nil, log_tag_type: 'CTX_TEST')
    end

    # When context is nil, PluginLoggerUtils returns "" for the HTML comment.
    # extract_base_data's log_output_accumulator gets this "".
    assert_equal '', result_nil_context[:log_output]
    assert_nil result_nil_context[:site]
    assert_nil result_nil_context[:data_source_for_keys]
    cleaned_stderr = strip_ansi(stderr_str).strip
    # CardDataExtractorUtils calls PluginLoggerUtils with default level :warn for its own message part
    expected_text = 'PluginLogger: [PLUGIN LOGGER ERROR] Context, Site, or Site Config unavailable for logging. Original Call: CTX_TEST - warn: Context or Site object unavailable for card data extraction.'
    assert_equal expected_text, cleaned_stderr
  end

  def test_extract_base_data_context_missing_site_register
    context_no_site = create_context({}, {}) # No :site register
    # Enable logging for the specific tag_type on a temporary site object
    # that PluginLoggerUtils will find if context was valid.
    # Since context.registers[:site] is nil, PluginLoggerUtils will log its internal error.
    # And extract_base_data will also log its specific error.
    # The log_output we get back will be from extract_base_data's call.

    # To make PluginLoggerUtils produce an HTML comment for extract_base_data's log call,
    # extract_base_data needs to pass a context where context.registers[:site] is valid.
    # This test is about context_no_site being passed to extract_base_data.
    # extract_base_data will detect this and its call to PluginLoggerUtils will pass context_no_site.
    # PluginLoggerUtils will then see context.registers[:site] is nil, log its own internal error, and return "".
    # So, result_no_site_reg[:log_output] will be "".

    # Corrected approach: extract_base_data's *own* log call is what we test.
    # It will pass `context_no_site` to `PluginLoggerUtils`.
    # `PluginLoggerUtils` will see `context_no_site.registers[:site]` is `nil`.
    # `PluginLoggerUtils` will then log its internal error (to STDERR) and return `""`.
    # `extract_base_data` will assign this `""` to `log_output_accumulator`.
    # The test below needs to reflect this. The important part is that `extract_base_data`
    # correctly identifies the issue and attempts to log.

    result_no_site_reg = nil
    # Capture STDERR for PluginLoggerUtils's internal error
    _stdout_str, stderr_str = capture_io do
      # No Jekyll.stub here for the same reason as above
      result_no_site_reg = CardDataExtractorUtils.extract_base_data(create_doc, context_no_site,
                                                                    log_tag_type: 'CTX_NO_SITE')
    end

    # Similar to above, log_output from extract_base_data will be ""
    assert_equal '', result_no_site_reg[:log_output]
    assert_nil result_no_site_reg[:site]
    cleaned_stderr = strip_ansi(stderr_str).strip
    # CardDataExtractorUtils calls PluginLoggerUtils with default level :warn
    expected_text = 'PluginLogger: [PLUGIN LOGGER ERROR] Context, Site, or Site Config unavailable for logging. Original Call: CTX_NO_SITE - warn: Context or Site object unavailable for card data extraction.'
    assert_equal expected_text, cleaned_stderr
  end

  # --- Tests for extract_description_html ---

  def test_extract_description_html_article_priority
    data_desc_only = { 'description' => 'Article Description.' }
    data_excerpt_only = { 'excerpt' => Struct.new(:output).new('<p>Article Excerpt Output</p>') }
    data_both = { 'description' => 'Article Description Wins.',
                  'excerpt' => Struct.new(:output).new('<p>Excerpt Ignored</p>') }
    data_desc_empty_fallback_excerpt = { 'description' => '  ',
                                         'excerpt' => Struct.new(:output).new('Fallback Excerpt.') }
    data_neither = {}
    data_excerpt_nil_output = { 'excerpt' => Struct.new(:output).new(nil) }

    assert_equal 'Article Description.', CardDataExtractorUtils.extract_description_html(data_desc_only, type: :article)
    assert_equal '<p>Article Excerpt Output</p>',
                 CardDataExtractorUtils.extract_description_html(data_excerpt_only, type: :article)
    assert_equal 'Article Description Wins.', CardDataExtractorUtils.extract_description_html(data_both, type: :article)
    assert_equal 'Fallback Excerpt.',
                 CardDataExtractorUtils.extract_description_html(data_desc_empty_fallback_excerpt, type: :article)
    assert_equal '', CardDataExtractorUtils.extract_description_html(data_neither, type: :article)
    assert_equal '', CardDataExtractorUtils.extract_description_html(data_excerpt_nil_output, type: :article)
  end

  def test_extract_description_html_book_priority
    data_desc_only = { 'description' => 'Book Description (ignored).' }
    data_excerpt_only = { 'excerpt' => Struct.new(:output).new('<p>Book Excerpt Output</p>') }
    data_both = { 'description' => 'Book Description (ignored).',
                  'excerpt' => Struct.new(:output).new('Actual Book Excerpt.') }
    data_neither = {}
    data_excerpt_nil_output = { 'excerpt' => Struct.new(:output).new(nil) }
    data_nil_item_data = nil

    assert_equal '', CardDataExtractorUtils.extract_description_html(data_desc_only, type: :book)
    assert_equal '<p>Book Excerpt Output</p>',
                 CardDataExtractorUtils.extract_description_html(data_excerpt_only, type: :book)
    assert_equal 'Actual Book Excerpt.', CardDataExtractorUtils.extract_description_html(data_both, type: :book)
    assert_equal '', CardDataExtractorUtils.extract_description_html(data_neither, type: :book)
    assert_equal '', CardDataExtractorUtils.extract_description_html(data_excerpt_nil_output, type: :book)
    assert_equal '', CardDataExtractorUtils.extract_description_html(data_nil_item_data, type: :book)
  end

  def test_extract_description_html_strips_whitespace
    data_book = { 'excerpt' => Struct.new(:output).new("  <p>Content</p>  \n") }
    assert_equal '<p>Content</p>', CardDataExtractorUtils.extract_description_html(data_book, type: :book)

    data_article = { 'description' => '  Article Desc  ' }
    assert_equal 'Article Desc', CardDataExtractorUtils.extract_description_html(data_article, type: :article)
  end

  def test_extract_description_html_handles_nil_data_hash
    assert_equal '', CardDataExtractorUtils.extract_description_html(nil, type: :article)
    assert_equal '', CardDataExtractorUtils.extract_description_html(nil, type: :book)
  end
end
