# _tests/plugins/utils/test_plugin_logger_utils.rb
require_relative '../../test_helper'
require 'minitest/mock'

class TestPluginLoggerUtils < Minitest::Test

  def setup
    @page_mock = create_doc({ 'path' => 'path/page.html' }, '/page.html')
    # @silent_logger_stub is not needed here as we'll use Minitest::Mock for Jekyll.logger
  end

  # Helper to create a context with a site having specific logging configs
  def create_test_context(site_config_overrides = {})
    # Ensure default environment is 'test' unless overridden
    # And ensure a default plugin_log_level for predictability if not overridden
    full_config_overrides = {
      'environment' => 'test',
      'plugin_log_level' => PluginLoggerUtils::DEFAULT_SITE_CONSOLE_LEVEL_STRING
    }.merge(site_config_overrides)
    site = create_site(full_config_overrides)
    create_context({}, { site: site, page: @page_mock })
  end

  # Helper to strip ANSI escape codes
  def strip_ansi(str)
    str.gsub(/\e\[([;\d]+)?m/, '')
  end

  # --- Test Cases ---

  # --- Testing Tag Enable/Disable (Master Switch) ---
  def test_logging_disabled_for_tag_type_overrides_level
    # Site config: tag enabled=false, global level=debug
    # Message level: warn
    # Expected: No console, No HTML
    ctx = create_test_context({
      'plugin_log_level' => 'debug', # Global level is permissive
      'plugin_logging' => { 'MY_TAG' => false } # But this tag is OFF
    })
    mock_logger = Minitest::Mock.new # Expect no calls

    html_output = ""
    # No need to capture_io if we expect no console output and mock_logger verifies no calls
    Jekyll.stub :logger, mock_logger do
      html_output = PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Test", level: :warn)
    end
    assert_equal "", html_output, "HTML output should be empty when tag logging is false"
    mock_logger.verify
  end

  # --- Testing Console Output Based on Global Level vs. Message Level ---
  def test_console_log_when_message_level_meets_global_threshold
    # Site config: tag enabled=true, global level=info
    # Message level: warn (warn > info, so should log)
    # Expected: Console log, HTML comment (if not prod)
    ctx = create_test_context({
      'plugin_log_level' => 'info', # Global threshold
      'plugin_logging' => { 'MY_TAG' => true }
    })

    mock_logger = Minitest::Mock.new
    # Expected message now includes the level prefix
    expected_console_msg = "[WARN] MY_TAG_FAILURE: Reason='Test'  SourcePage='path/page.html'"
    mock_logger.expect(:warn, nil, ["PluginLiquid:", expected_console_msg])

    html_output = ""
    Jekyll.stub :logger, mock_logger do
      html_output = PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Test", level: :warn)
    end

    mock_logger.verify
    assert_match %r{<!-- \[WARN\] MY_TAG_FAILURE: Reason='Test'\s*SourcePage='path/page\.html' -->}, html_output
  end

  def test_console_log_suppressed_when_message_level_below_global_threshold
    # Site config: tag enabled=true, global level=warn
    # Message level: info (info < warn, so should NOT log to console)
    # Expected: No console log, BUT HTML comment still generated (if not prod)
    ctx = create_test_context({
      'plugin_log_level' => 'warn', # Global threshold
      'plugin_logging' => { 'MY_TAG' => true }
    })
    mock_logger = Minitest::Mock.new # Expect no calls to :info, :warn, etc.

    html_output = ""
    Jekyll.stub :logger, mock_logger do
      html_output = PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Test", level: :info)
    end

    mock_logger.verify # Verifies no methods were called on the mock
    # HTML comment should still include the original message level
    assert_match %r{<!-- \[INFO\] MY_TAG_FAILURE: Reason='Test'\s*SourcePage='path/page\.html' -->}, html_output, "HTML comment should still be generated"
  end

  def test_console_log_uses_default_global_level_if_not_set
    ctx = create_test_context({ 'plugin_logging' => { 'MY_TAG' => true } })

    mock_logger = Minitest::Mock.new
    expected_console_msg = "[WARN] MY_TAG_FAILURE: Reason='Test'  SourcePage='path/page.html'"
    mock_logger.expect(:warn, nil, ["PluginLiquid:", expected_console_msg])

    Jekyll.stub :logger, mock_logger do
      PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Test", level: :warn)
    end
    mock_logger.verify
  end

  def test_console_log_uses_default_message_level_if_not_passed
    # Default message level is :warn (PluginLoggerUtils::DEFAULT_MESSAGE_LEVEL_SYMBOL)
    ctx = create_test_context({
      'plugin_log_level' => 'debug', # Global console level is permissive
      'plugin_logging' => { 'MY_TAG' => true }
    })

    mock_logger = Minitest::Mock.new
    # Default message level is :warn
    expected_console_msg = "[WARN] MY_TAG_FAILURE: Reason='Test'  SourcePage='path/page.html'"
    mock_logger.expect(:warn, nil, ["PluginLiquid:", expected_console_msg])

    Jekyll.stub :logger, mock_logger do
      PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Test") # No level passed
    end
    mock_logger.verify
  end

  # --- Testing HTML Comment Generation ---
  def test_html_comment_in_non_production_when_enabled_and_level_met
    # Site config: tag enabled=true, global level=debug, env=test
    # Message level: debug
    # Expected: HTML comment
    ctx = create_test_context({
      'environment' => 'test',
      'plugin_log_level' => 'debug', # Console level
      'plugin_logging' => { 'MY_TAG' => true }
    })
    html_output = ""
    # Use a mock that responds to :debug to prevent puts fallback
    logger_responds_to_debug = Minitest::Mock.new
    logger_responds_to_debug.expect(:debug, nil, [String, String]) # Allow any two string args

    Jekyll.stub :logger, logger_responds_to_debug do
      html_output = PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Debug Test", level: :debug)
    end
    logger_responds_to_debug.verify # Ensure it was called (or not, if level filtering suppressed it)
    assert_match %r{<!-- \[DEBUG\] MY_TAG_FAILURE: Reason='Debug Test'\s*SourcePage='path/page\.html' -->}, html_output
  end

  def test_html_comment_in_non_production_even_if_console_suppressed_by_level
    # Site config: tag enabled=true, global level=error, env=test
    # Message level: warn (warn < error, so console suppressed)
    # Expected: HTML comment still generated
    ctx = create_test_context({
      'environment' => 'test',
      'plugin_log_level' => 'error', # Console only shows errors
      'plugin_logging' => { 'MY_TAG' => true }
    })
    html_output = ""
    # We expect no console output for a :warn message because global level is :error.
    # So, mock_logger should have no expectations for :warn.
    mock_logger_for_html_test = Minitest::Mock.new
    Jekyll.stub :logger, mock_logger_for_html_test do
      html_output = PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Warn Test", level: :warn)
    end
    mock_logger_for_html_test.verify # Verify no console methods were called
    assert_match %r{<!-- \[WARN\] MY_TAG_FAILURE: Reason='Warn Test'\s*SourcePage='path/page\.html' -->}, html_output
  end

  def test_no_html_comment_in_production_even_if_enabled_and_level_met
    # Site config: tag enabled=true, global level=debug, env=production
    # Message level: debug
    # Expected: NO HTML comment
    ctx = create_test_context({
      'environment' => 'production',
      'plugin_log_level' => 'debug',
      'plugin_logging' => { 'MY_TAG' => true }
    })
    html_output = ""
    # Use a mock that responds to :debug to prevent puts fallback, even though HTML is off
    logger_responds_to_debug = Minitest::Mock.new
    logger_responds_to_debug.expect(:debug, nil, [String, String])

    Jekyll.stub :logger, logger_responds_to_debug do
      html_output = PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Prod Test", level: :debug)
    end
    logger_responds_to_debug.verify
    assert_equal "", html_output
  end

  def test_no_html_comment_if_tag_disabled
    # Site config: tag enabled=false, env=test
    # Expected: No HTML comment
    ctx = create_test_context({
      'environment' => 'test',
      'plugin_logging' => { 'MY_TAG' => false } # Logging for MY_TAG is off
    })
    html_output = ""
    Jekyll.stub :logger, Minitest::Mock.new do # Stub to silence potential console output
      html_output = PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Disabled Test")
    end
    assert_equal "", html_output
  end

  def test_puts_fallback_used_when_jekyll_logger_cannot_handle_level
    ctx = create_test_context({
      'plugin_log_level' => 'debug', # Ensure console logging is attempted
      'plugin_logging' => { 'MY_TAG' => true }
    })
    simple_logger = Object.new

    stdout_str, _ = capture_io do
      Jekyll.stub :logger, simple_logger do
        PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Puts Test", level: :warn)
      end
    end
    # Puts fallback now includes the level in its output string
    assert_match %r{\[PLUGIN_LIQUID_LOG\] \[WARN\] MY_TAG_FAILURE: Reason='Puts Test'\s*SourcePage='path/page\.html'}, stdout_str
  end

  # --- Test for internal logger error when context/site is bad ---
  def test_internal_logger_error_if_context_is_nil
    _stdout_str, stderr_str = capture_io do
      # This call passes level: :error
      PluginLoggerUtils.log_liquid_failure(context: nil, tag_type: "CTX_NIL", reason: "Bad context", level: :error)
    end
    cleaned_stderr = strip_ansi(stderr_str).strip
    # Define the exact expected string after cleaning
    expected_text = "PluginLogger: [PLUGIN LOGGER ERROR] Context or Site unavailable. Original Call: CTX_NIL - error: Bad context"
    assert_equal expected_text, cleaned_stderr
  end

  def test_internal_logger_error_if_context_has_no_site
    context_no_site = create_context({}, {}) # No :site register
    _stdout_str, stderr_str = capture_io do
      PluginLoggerUtils.log_liquid_failure(context: context_no_site, tag_type: "CTX_NO_SITE", reason: "Bad context", level: :error)
    end
    cleaned_stderr = strip_ansi(stderr_str).strip
    # Define the exact expected string after cleaning
    expected_text = "PluginLogger: [PLUGIN LOGGER ERROR] Context or Site unavailable. Original Call: CTX_NO_SITE - error: Bad context"
    assert_equal expected_text, cleaned_stderr
  end
end
