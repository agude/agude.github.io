# _tests/plugins/liquid_utils/test_log_failure.rb
require_relative '../../test_helper' # Adjust path if your helper is elsewhere

class TestLiquidUtilsLogFailure < Minitest::Test

  # Helper method to temporarily stub respond_to?(:warn) on Jekyll.logger
  # This forces the log_failure method to use its 'puts' fallback for testing.
  def stub_logger_respond_to_warn_as_false
    # Ensure Jekyll module and logger method exist before stubbing
    unless defined?(Jekyll) && Jekyll.respond_to?(:logger) && Jekyll.logger
      # If logger isn't defined, the 'puts' fallback will be used anyway.
      # So, we can just yield without stubbing in this case.
      yield
      return
    end

    original_logger = Jekyll.logger
    # Store the original method implementation if it exists
    original_respond_to = original_logger.respond_to?(:respond_to?) ? original_logger.method(:respond_to?) : nil

    # Define a temporary singleton method 'respond_to?' on the logger instance
    original_logger.define_singleton_method(:respond_to?) do |method_name, include_private = false|
       if method_name == :warn
         false # Pretend it doesn't respond to :warn
       elsif original_respond_to # If original method was captured
         # Call the original respond_to? for other methods
         original_respond_to.call(method_name, include_private)
       else
         # Fallback if original couldn't be captured (shouldn't happen with standard Jekyll)
         # Use super to call the original method lookup chain
         defined?(super) ? super(method_name, include_private) : false
       end
    end

    begin
      yield # Execute the code block with the stubbed logger
    ensure
      # Restore original respond_to? by removing the singleton method
      # Check if the method exists on the singleton class before trying to remove it
      if original_logger.singleton_class.method_defined?(:respond_to?) || original_logger.singleton_class.private_method_defined?(:respond_to?)
         original_logger.singleton_class.send(:remove_method, :respond_to?)
      end
    end
  end


  # --- log_failure Tests ---

  def test_log_failure_test_env_enabled
    site = create_site({ 'plugin_logging' => { 'TEST_TAG' => true } }) # Explicitly enable
    page_mock = create_doc({ 'path' => 'path/page.html' }, '/page.html')
    ctx = create_context({}, { site: site, page: page_mock })

    html_output = nil
    stdout_str, stderr_str = capture_io do
      # Force puts fallback by stubbing respond_to?(:warn)
      stub_logger_respond_to_warn_as_false do
         html_output = LiquidUtils.log_failure(context: ctx, tag_type: "TEST_TAG", reason: "It broke", identifiers: { Key: "Val<>" })
      end
    end

    # Assert the returned HTML comment (should still be generated in test env)
    expected_comment = "<!-- TEST_TAG_FAILURE: Reason='It broke' Key='Val&lt;&gt;' SourcePage='path/page.html' -->"
    assert_equal expected_comment, html_output

    # Assert that the 'puts' fallback was used for console output
    # Use \s+ for spacing, \n? for optional newline, escape regex chars . /
    assert_match(/\[PLUGIN LOG\] TEST_TAG_FAILURE: Reason='It broke'\s+Key='Val&lt;&gt;'\s+SourcePage='path\/page\.html'\n?$/, stdout_str)
    assert_empty stderr_str # Should be no errors
  end

  def test_log_failure_test_env_disabled_via_config
    site = create_site({ 'plugin_logging' => { 'TEST_TAG' => false } }) # Explicitly disable
    page_mock = create_doc({ 'path' => 'path/page.html' }, '/page.html')
    ctx = create_context({}, { site: site, page: page_mock })

    html_output = nil
    stdout_str, stderr_str = capture_io do
       # No need to stub logger if nothing should be logged anyway
       html_output = LiquidUtils.log_failure(context: ctx, tag_type: "TEST_TAG", reason: "It broke", identifiers: {})
    end

    # Assert the returned value is empty
    assert_equal "", html_output
    # Assert nothing was printed to console
    assert_empty stdout_str
    assert_empty stderr_str
  end

  def test_log_failure_test_env_disabled_by_default
    # Logging is disabled by default in test_helper's create_site
    site = create_site
    page_mock = create_doc({ 'path' => 'path/page.html' }, '/page.html')
    ctx = create_context({}, { site: site, page: page_mock })

    html_output = nil
    stdout_str, stderr_str = capture_io do
       # No need to stub logger if nothing should be logged anyway
       html_output = LiquidUtils.log_failure(context: ctx, tag_type: "ANY_TAG", reason: "It broke", identifiers: {})
    end

    # Assert the returned value is empty
    assert_equal "", html_output
    # Assert nothing was printed to console
    assert_empty stdout_str
    assert_empty stderr_str
  end

  def test_log_failure_production_env
    # Override helper default to enable logging, but set production env
    site = create_site({ 'environment' => 'production', 'plugin_logging' => { 'PROD_TAG' => true } })
    page_mock = create_doc({ 'path' => 'path/page.html' }, '/page.html')
    ctx = create_context({}, { site: site, page: page_mock })

    html_output = nil
    stdout_str, stderr_str = capture_io do
      # Force puts fallback by stubbing respond_to?(:warn)
      stub_logger_respond_to_warn_as_false do
        html_output = LiquidUtils.log_failure(context: ctx, tag_type: "PROD_TAG", reason: "Prod issue", identifiers: {})
      end
    end

    # Assert HTML comment is disabled in production
    assert_equal "", html_output
    # Assert console logging still happened via 'puts' fallback
    # Use \s+ for spacing, \n? for optional newline, escape regex chars . /
    assert_match(/\[PLUGIN LOG\] PROD_TAG_FAILURE: Reason='Prod issue'\s+SourcePage='path\/page\.html'\n?$/, stdout_str)
    assert_empty stderr_str
  end

end
