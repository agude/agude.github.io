# frozen_string_literal: true

# _tests/plugins/utils/test_plugin_logger_utils.rb
require_relative '../../test_helper'
require 'minitest/mock'

# Base test class with shared setup and helpers
class TestPluginLoggerUtilsBase < Minitest::Test
  def setup
    @page_mock = create_doc({ 'path' => 'path/page.html' }, '/page.html')
  end

  private

  def create_test_context(site_config_overrides = {})
    full_config_overrides = {
      'environment' => 'test',
      'plugin_log_level' => Jekyll::Infrastructure::PluginLoggerUtils::DEFAULT_SITE_CONSOLE_LEVEL_STRING,
    }.merge(site_config_overrides)
    site = create_site(full_config_overrides)
    create_context({}, { site: site, page: @page_mock })
  end

  def strip_ansi(str)
    str.gsub(/\e\[([;\d]+)?m/, '')
  end

  def call_log_liquid_failure(ctx, tag_type:, reason:, level: :warn)
    ::Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: tag_type, reason: reason, level: level)
  end
end

# Tests for tag enable/disable functionality
class TestPluginLoggerUtilsTagEnable < TestPluginLoggerUtilsBase
  def test_logging_disabled_for_tag_type_overrides_level
    ctx = create_test_context(
      'plugin_log_level' => 'debug',
      'plugin_logging' => { 'MY_TAG' => false },
    )
    mock_logger = Minitest::Mock.new

    html_output = ''
    Jekyll.stub :logger, mock_logger do
      html_output = call_log_liquid_failure(ctx, tag_type: 'MY_TAG', reason: 'Test', level: :warn)
    end
    assert_equal '', html_output, 'HTML output should be empty when tag logging is false'
    mock_logger.verify
  end
end

# Tests for console output based on global level vs message level
class TestPluginLoggerUtilsConsoleOutput < TestPluginLoggerUtilsBase
  def test_console_log_when_message_level_meets_global_threshold
    ctx, mock_logger, = setup_console_log_test
    html_output = run_log_with_mock(ctx, mock_logger, :warn)

    mock_logger.verify
    assert_match expected_html_pattern, html_output
  end

  def test_console_log_suppressed_when_message_level_below_global_threshold
    ctx = create_test_context('plugin_log_level' => 'warn', 'plugin_logging' => { 'MY_TAG' => true })
    mock_logger = Minitest::Mock.new

    html_output = run_log_with_mock(ctx, mock_logger, :info)

    mock_logger.verify
    assert_match %r{<!-- \[INFO\] MY_TAG_FAILURE: Reason='Test'\s*SourcePage='path/page\.html' -->},
                 html_output,
                 'HTML comment should still be generated'
  end

  def test_console_log_uses_default_global_level_if_not_set
    ctx = create_test_context('plugin_logging' => { 'MY_TAG' => true })

    mock_logger = create_mock_logger_expecting_warn

    Jekyll.stub :logger, mock_logger do
      call_log_liquid_failure(ctx, tag_type: 'MY_TAG', reason: 'Test', level: :warn)
    end
    mock_logger.verify
  end

  def test_console_log_uses_default_message_level_if_not_passed
    ctx = create_test_context('plugin_log_level' => 'debug', 'plugin_logging' => { 'MY_TAG' => true })
    mock_logger = create_mock_logger_expecting_warn

    Jekyll.stub :logger, mock_logger do
      Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: 'MY_TAG', reason: 'Test')
    end
    mock_logger.verify
  end

  private

  def setup_console_log_test
    ctx = create_test_context('plugin_log_level' => 'info', 'plugin_logging' => { 'MY_TAG' => true })
    mock_logger = create_mock_logger_expecting_warn
    expected_msg = "[WARN] MY_TAG_FAILURE: Reason='Test'  SourcePage='path/page.html'"
    [ctx, mock_logger, expected_msg]
  end

  def run_log_with_mock(ctx, mock_logger, level)
    html_output = ''
    Jekyll.stub :logger, mock_logger do
      html_output = call_log_liquid_failure(ctx, tag_type: 'MY_TAG', reason: 'Test', level: level)
    end
    html_output
  end

  def expected_html_pattern
    %r{<!-- \[WARN\] MY_TAG_FAILURE: Reason='Test'\s*SourcePage='path/page\.html' -->}
  end

  def create_mock_logger_expecting_warn
    mock = Minitest::Mock.new
    expected_console_msg = "[WARN] MY_TAG_FAILURE: Reason='Test'  SourcePage='path/page.html'"
    mock.expect(:warn, nil, ['PluginLiquid:', expected_console_msg])
    mock
  end
end

# Tests for HTML comment generation
class TestPluginLoggerUtilsHtmlComments < TestPluginLoggerUtilsBase
  def test_html_comment_in_non_production_when_enabled_and_level_met
    ctx = create_test_context(
      'environment' => 'test', 'plugin_log_level' => 'debug', 'plugin_logging' => { 'MY_TAG' => true },
    )

    html_output = run_with_debug_logger(ctx, 'Debug Test')

    assert_match expected_debug_html_pattern, html_output
  end

  def test_html_comment_in_non_production_even_if_console_suppressed_by_level
    ctx = create_test_context(
      'environment' => 'test', 'plugin_log_level' => 'error', 'plugin_logging' => { 'MY_TAG' => true },
    )

    html_output = run_with_no_console(ctx, 'Warn Test', :warn)

    assert_match expected_warn_html_pattern, html_output
  end

  def test_no_html_comment_in_production_even_if_enabled_and_level_met
    ctx = create_test_context(
      'environment' => 'production', 'plugin_log_level' => 'debug', 'plugin_logging' => { 'MY_TAG' => true },
    )

    html_output = run_with_debug_logger(ctx, 'Prod Test')

    assert_equal '', html_output, 'HTML output should be empty in production'
  end

  def test_no_html_comment_if_tag_disabled
    ctx = create_test_context('environment' => 'test', 'plugin_logging' => { 'MY_TAG' => false })

    html_output = run_with_no_console(ctx, 'Disabled Test')

    assert_equal '', html_output, 'HTML output should be empty when tag logging is disabled'
  end

  private

  def run_with_debug_logger(ctx, reason)
    logger_responds_to_debug = Minitest::Mock.new
    logger_responds_to_debug.expect(:debug, nil, [String, String])

    html_output = ''
    Jekyll.stub :logger, logger_responds_to_debug do
      html_output = call_log_liquid_failure(ctx, tag_type: 'MY_TAG', reason: reason, level: :debug)
    end
    logger_responds_to_debug.verify
    html_output
  end

  def run_with_no_console(ctx, reason, level = :warn)
    mock_logger = Minitest::Mock.new
    html_output = ''
    Jekyll.stub :logger, mock_logger do
      html_output = call_log_liquid_failure(ctx, tag_type: 'MY_TAG', reason: reason, level: level)
    end
    mock_logger.verify
    html_output
  end

  def expected_debug_html_pattern
    %r{<!-- \[DEBUG\] MY_TAG_FAILURE: Reason='Debug Test'\s*SourcePage='path/page\.html' -->}
  end

  def expected_warn_html_pattern
    %r{<!-- \[WARN\] MY_TAG_FAILURE: Reason='Warn Test'\s*SourcePage='path/page\.html' -->}
  end
end

# Tests for internal logger errors and fallbacks
class TestPluginLoggerUtilsInternalErrors < TestPluginLoggerUtilsBase
  def test_puts_fallback_used_when_jekyll_logger_cannot_handle_level
    ctx = create_test_context('plugin_log_level' => 'debug', 'plugin_logging' => { 'MY_TAG' => true })
    simple_logger = Object.new

    stdout_str, = capture_io do
      Jekyll.stub :logger, simple_logger do
        call_log_liquid_failure(ctx, tag_type: 'MY_TAG', reason: 'Puts Test', level: :warn)
      end
    end

    expected_pattern = %r{\[PLUGIN_LIQUID_LOG\] \[WARN\] MY_TAG_FAILURE: Reason='Puts Test'\s*SourcePage='path/page\.html'}
    assert_match expected_pattern, stdout_str
  end

  def test_internal_logger_error_if_context_is_nil
    _, stderr_str = capture_io do
      call_log_liquid_failure(nil, tag_type: 'CTX_NIL', reason: 'Bad context', level: :error)
    end
    cleaned_stderr = strip_ansi(stderr_str).strip

    expected_text = 'PluginLogger: [PLUGIN LOGGER ERROR] Context, Site, or Site Config unavailable for logging. ' \
                    'Original Call: CTX_NIL - error: Bad context'
    assert_equal expected_text, cleaned_stderr
  end

  def test_internal_logger_error_if_context_has_no_site
    context_no_site = create_context({}, {})
    _, stderr_str = capture_io do
      call_log_liquid_failure(context_no_site, tag_type: 'CTX_NO_SITE', reason: 'Bad context', level: :error)
    end
    cleaned_stderr = strip_ansi(stderr_str).strip

    expected_text = 'PluginLogger: [PLUGIN LOGGER ERROR] Context, Site, or Site Config unavailable for logging. ' \
                    'Original Call: CTX_NO_SITE - error: Bad context'
    assert_equal expected_text, cleaned_stderr
  end

  def test_fallback_to_warn_when_jekyll_logger_undefined
    # Tests line 48 'else' and line 51
    # When Jekyll.logger is not defined or doesn't respond to error, uses warn
    # We'll test this by passing nil context which triggers handle_missing_config

    # Capture stderr to see the warn output
    _, stderr_str = capture_io do
      # Get a reference to the method before undefining Jekyll
      method_ref = ::Jekyll::Infrastructure::PluginLoggerUtils.method(:log_liquid_failure)

      # Undefine Jekyll temporarily
      jekyll_backup = Jekyll
      begin
        Object.send(:remove_const, :Jekyll)
        method_ref.call(context: nil, tag_type: 'NO_LOGGER', reason: 'Test', level: :error)
      ensure
        Object.const_set(:Jekyll, jekyll_backup)
      end
    end

    # The warn should output to stderr
    assert_match(/Context, Site, or Site Config unavailable/, stderr_str)
  end

  def test_invalid_log_level_uses_default
    # Tests line 62 'else' and line 98 'else'
    ctx = create_test_context('plugin_log_level' => 'debug', 'plugin_logging' => { 'MY_TAG' => true })
    mock_logger = Minitest::Mock.new
    # Invalid level should default to :warn
    mock_logger.expect(:warn, nil, ['PluginLiquid:', String])

    html_output = ''
    Jekyll.stub :logger, mock_logger do
      # Pass an invalid level symbol
      html_output = call_log_liquid_failure(ctx, tag_type: 'MY_TAG', reason: 'Test', level: :invalid_level)
    end

    mock_logger.verify
    # Should use DEFAULT_MESSAGE_LEVEL_SYMBOL which is :warn
    assert_match(/\[WARN\] MY_TAG_FAILURE/, html_output)
  end

  def test_page_exists_but_has_no_path
    # Tests line 76 'then' and line 77
    # Create a mock class for the page
    mock_class = Class.new do
      def self.name
        'MockPageClass'
      end
    end

    page_no_path = Object.new
    page_no_path.define_singleton_method(:respond_to?) { |method| method == :[] }
    page_no_path.define_singleton_method(:[]) { |_key| nil } # No 'path' key
    page_no_path.define_singleton_method(:class) { mock_class }

    site = create_site({ 'plugin_logging' => { 'MY_TAG' => true } })
    ctx = create_context({}, { site: site, page: page_no_path })

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:warn, nil, ['PluginLiquid:', String])

    html_output = ''
    Jekyll.stub :logger, mock_logger do
      html_output = call_log_liquid_failure(ctx, tag_type: 'MY_TAG', reason: 'Test', level: :warn)
    end

    mock_logger.verify
    # Should contain the fallback message about page_exists_no_path
    assert_match(/page_exists_no_path \(class: MockPageClass\)/, html_output)
  end

  def test_page_register_is_nil_shows_unknown_page
    site = create_site({ 'plugin_logging' => { 'MY_TAG' => true } })
    ctx = create_context({}, { site: site })

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:warn, nil, ['PluginLiquid:', String])

    html_output = ''
    Jekyll.stub :logger, mock_logger do
      html_output = call_log_liquid_failure(ctx, tag_type: 'MY_TAG', reason: 'Test', level: :warn)
    end

    mock_logger.verify
    assert_match(/SourcePage='unknown_page'/, html_output)
  end

  def test_plugin_logging_config_missing_entirely
    ctx = create_test_context({})
    # Remove plugin_logging entirely from site config
    ctx.registers[:site].config.delete('plugin_logging')

    result = call_log_liquid_failure(ctx, tag_type: 'MY_TAG', reason: 'Test', level: :warn)
    assert_equal '', result, 'Should return empty string when plugin_logging config is absent'
  end
end

# Tests for identifiers and CGI escaping in log messages
class TestPluginLoggerUtilsIdentifiersAndEscaping < TestPluginLoggerUtilsBase
  def test_identifiers_appear_in_output_message
    ctx = create_test_context('plugin_log_level' => 'debug', 'plugin_logging' => { 'MY_TAG' => true })
    mock_logger = Minitest::Mock.new
    mock_logger.expect(:warn, nil, ['PluginLiquid:', String])

    html_output = ''
    Jekyll.stub :logger, mock_logger do
      html_output = Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
        context: ctx,
        tag_type: 'MY_TAG',
        reason: 'Test',
        identifiers: { 'book' => 'Dune', 'author' => 'Herbert' },
        level: :warn,
      )
    end

    mock_logger.verify
    assert_match(/book='Dune'/, html_output)
    assert_match(/author='Herbert'/, html_output)
  end

  def test_cgi_escaping_of_special_characters
    ctx = create_test_context('plugin_log_level' => 'debug', 'plugin_logging' => { 'MY_TAG' => true })
    mock_logger = Minitest::Mock.new
    mock_logger.expect(:warn, nil, ['PluginLiquid:', String])

    html_output = ''
    Jekyll.stub :logger, mock_logger do
      html_output = Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
        context: ctx,
        tag_type: 'MY_TAG',
        reason: '<script>alert("xss")</script>',
        identifiers: { 'key' => '<b>bold</b>' },
        level: :warn,
      )
    end

    mock_logger.verify
    # Reason should be CGI-escaped
    assert_match(/&lt;script&gt;/, html_output)
    refute_match(/<script>/, html_output)
    # Identifier values should be CGI-escaped
    assert_match(%r{&lt;b&gt;bold&lt;/b&gt;}, html_output)
    refute_match(%r{<b>bold</b>}, html_output)
  end
end
