# _tests/plugins/utils/test_plugin_logger_utils.rb
require_relative '../../test_helper'
require 'minitest/mock' # For mocking Jekyll.logger methods

class TestPluginLoggerUtils < Minitest::Test

  def setup
    @page_mock = create_doc({ 'path' => 'path/page.html' }, '/page.html')
    # @silent_logger_stub is not needed here as we'll use Minitest::Mock for Jekyll.logger
  end

  # Helper to create a context with a site having specific logging configs
  def create_test_context(site_config_overrides = {})
    site = create_site(site_config_overrides)
    create_context({}, { site: site, page: @page_mock })
  end

  # --- Test Cases ---

  # --- Testing Tag Enable/Disable (Master Switch) ---
  def test_logging_disabled_for_tag_type_overrides_level
    # Site config: tag enabled=false, global level=debug
    # Message level: warn
    # Expected: No console, No HTML
    ctx = create_test_context({
      'plugin_log_level' => 'debug',
      'plugin_logging' => { 'MY_TAG' => false }
    })
    mock_logger = Minitest::Mock.new # Expect no calls

    html_output = ""
    stdout_str, _ = capture_io do
      Jekyll.stub :logger, mock_logger do
        html_output = PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Test", level: :warn)
      end
    end
    assert_equal "", html_output
    assert_empty stdout_str # Minitest::Mock would raise if methods were called
    mock_logger.verify # Ensure no methods on the mock logger were called
  end

  # --- Testing Console Output Based on Global Level vs. Message Level ---
  def test_console_log_when_message_level_meets_global_threshold
    # Site config: tag enabled=true, global level=info
    # Message level: warn (warn > info, so should log)
    # Expected: Console log, HTML comment (if not prod)
    ctx = create_test_context({
      'plugin_log_level' => 'info',
      'plugin_logging' => { 'MY_TAG' => true }
    })

    mock_logger = Minitest::Mock.new
    # Expect :warn to be called because message level is :warn
    mock_logger.expect(:warn, nil, ["PluginLiquid:", "[WARN] MY_TAG_FAILURE: Reason='Test' SourcePage='path/page.html'"])

    html_output = ""
    Jekyll.stub :logger, mock_logger do
      html_output = PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Test", level: :warn)
    end

    mock_logger.verify
    assert_match %r{<!-- \[WARN\] MY_TAG_FAILURE: Reason='Test' SourcePage='path/page.html' -->}, html_output
  end

  def test_console_log_suppressed_when_message_level_below_global_threshold
    # Site config: tag enabled=true, global level=warn
    # Message level: info (info < warn, so should NOT log to console)
    # Expected: No console log, BUT HTML comment still generated (if not prod)
    ctx = create_test_context({
      'plugin_log_level' => 'warn',
      'plugin_logging' => { 'MY_TAG' => true }
    })
    mock_logger = Minitest::Mock.new # Expect no calls to :info, :warn, etc.

    html_output = ""
    Jekyll.stub :logger, mock_logger do
      html_output = PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Test", level: :info)
    end

    mock_logger.verify # Verifies no methods were called on the mock
    assert_match %r{<!-- \[INFO\] MY_TAG_FAILURE: Reason='Test' SourcePage='path/page.html' -->}, html_output, "HTML comment should still be generated"
  end

  def test_console_log_uses_default_global_level_if_not_set
    # Site config: tag enabled=true, global level NOT SET (should default to "warn")
    # Message level: warn (warn == default_warn, so should log)
    ctx = create_test_context({ 'plugin_logging' => { 'MY_TAG' => true } }) # No 'plugin_log_level'

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:warn, nil, ["PluginLiquid:", "[WARN] MY_TAG_FAILURE: Reason='Test' SourcePage='path/page.html'"])

    Jekyll.stub :logger, mock_logger do
      PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Test", level: :warn)
    end
    mock_logger.verify
  end

  def test_console_log_uses_default_message_level_if_not_passed
    # Site config: tag enabled=true, global level=debug
    # Message level: NOT PASSED (should default to :warn; warn > debug, so should log)
    ctx = create_test_context({
      'plugin_log_level' => 'debug',
      'plugin_logging' => { 'MY_TAG' => true }
    })

    mock_logger = Minitest::Mock.new
    # Expect :warn because default message level is :warn
    mock_logger.expect(:warn, nil, ["PluginLiquid:", "[WARN] MY_TAG_FAILURE: Reason='Test' SourcePage='path/page.html'"])

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
      'plugin_log_level' => 'debug',
      'plugin_logging' => { 'MY_TAG' => true }
    })
    html_output = PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Debug Test", level: :debug)
    assert_match %r{<!-- \[DEBUG\] MY_TAG_FAILURE: Reason='Debug Test' SourcePage='path/page.html' -->}, html_output
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
    html_output = PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Warn Test", level: :warn)
    assert_match %r{<!-- \[WARN\] MY_TAG_FAILURE: Reason='Warn Test' SourcePage='path/page.html' -->}, html_output
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
    html_output = PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Prod Test", level: :debug)
    assert_equal "", html_output
  end

  def test_no_html_comment_if_tag_disabled
    # Site config: tag enabled=false, env=test
    # Expected: No HTML comment
    ctx = create_test_context({
      'environment' => 'test',
      'plugin_logging' => { 'MY_TAG' => false }
    })
    html_output = PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Disabled Test")
    assert_equal "", html_output
  end

  # --- Testing Puts Fallback (using existing helper) ---
  def stub_logger_methods_as_unresponsive(logger, methods_to_make_unresponsive)
    methods_to_make_unresponsive.each do |method_name|
      if logger.respond_to?(method_name)
        # Define a singleton method that makes respond_to?(method_name) false
        # This is tricky because we need to modify how the logger *itself* reports respond_to?
        # A simpler way for puts fallback is to ensure Jekyll.logger is nil or doesn't have the method.
        # For this test, we'll make Jekyll.logger a simple object that doesn't have :debug, :info, etc.
      end
    end
    # This helper needs rethinking for specific method unresponsiveness.
    # For now, test_puts_fallback_used will set Jekyll.logger to a basic object.
  end

  def test_puts_fallback_used_when_jekyll_logger_cannot_handle_level
    ctx = create_test_context({
      'plugin_log_level' => 'debug', # Ensure console logging is attempted
      'plugin_logging' => { 'MY_TAG' => true }
    })

    # Create a mock logger that doesn't respond to :debug, :info, :warn, :error
    simple_logger = Object.new
    # No methods defined on it.

    stdout_str, _ = capture_io do
      Jekyll.stub :logger, simple_logger do
        PluginLoggerUtils.log_liquid_failure(context: ctx, tag_type: "MY_TAG", reason: "Puts Test", level: :warn)
      end
    end
    assert_match %r{\[PLUGIN_LIQUID_LOG\] \[WARN\] MY_TAG_FAILURE: Reason='Puts Test' SourcePage='path/page.html'}, stdout_str
  end

  # --- Test for internal logger error when context/site is bad ---
  def test_internal_logger_error_if_context_is_nil
    _stdout_str, stderr_str = capture_io do
      PluginLoggerUtils.log_liquid_failure(context: nil, tag_type: "CTX_NIL", reason: "Bad context")
    end
    assert_match "[PLUGIN LOGGER ERROR] Context or Site unavailable.", stderr_str
  end

  def test_internal_logger_error_if_context_has_no_site
    context_no_site = create_context({}, {}) # No :site register
    _stdout_str, stderr_str = capture_io do
      PluginLoggerUtils.log_liquid_failure(context: context_no_site, tag_type: "CTX_NO_SITE", reason: "Bad context")
    end
    assert_match "[PLUGIN LOGGER ERROR] Context or Site unavailable.", stderr_str
  end
end
