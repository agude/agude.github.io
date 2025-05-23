# _tests/plugins/test_log_failure_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/log_failure_tag' # Load the tag

class TestLogFailureTag < Minitest::Test

  def setup
    @site = create_site
    @context = create_context(
      {
        'page_path_var' => 'path/from/variable.html',
        'user_id_var' => 12345,
        'status_var' => 'pending'
      },
      { site: @site, page: create_doc({ 'path' => 'current_test_page.html' }, '/current.html') }
    )
    @site.config['plugin_logging']['MY_CUSTOM_ERROR'] = true
    @site.config['plugin_logging']['TEMPLATE_INFO'] = true
  end

  def render_tag(markup_inside_tag, context = @context)
    Liquid::Template.parse("{% log_failure #{markup_inside_tag} %}").render!(context)
  end

  # --- Tests for initialize (Syntax Errors) ---

  def test_syntax_error_missing_type_argument
    markup = "reason='Something happened'"
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% log_failure #{markup} %}")
    end
    assert_match "Required argument 'type' is missing", err.message
  end

  def test_syntax_error_missing_reason_argument
    markup = "type='MY_ERROR'"
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% log_failure #{markup} %}")
    end
    assert_match "Required argument 'reason' is missing", err.message
  end

  def test_syntax_error_invalid_arguments_near
    markup = "type='T' reason='R' this_is_not_key_value"
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% log_failure #{markup} %}")
    end
    assert_match "Invalid arguments near 'this_is_not_key_value'", err.message
  end

  # --- Tests for render (Argument Resolution and Delegation) ---

  def test_render_basic_type_and_reason_delegates_correctly
    markup = "type='MY_CUSTOM_ERROR' reason='A basic failure occurred.'"
    expected_log_type = "MY_CUSTOM_ERROR"
    expected_reason = "A basic failure occurred."
    expected_identifiers = {}
    mock_return_value = "<!-- MY_CUSTOM_ERROR LOGGED -->"

    captured_args = nil
    PluginLoggerUtils.stub :log_liquid_failure, lambda { |args| captured_args = args; mock_return_value } do
      output = render_tag(markup)
      assert_equal mock_return_value, output
    end

    refute_nil captured_args, "PluginLoggerUtils.log_liquid_failure should have been called"
    assert_equal @context, captured_args[:context]
    assert_equal expected_log_type, captured_args[:tag_type]
    assert_equal expected_reason, captured_args[:reason]
    assert_equal expected_identifiers, captured_args[:identifiers]
    assert_nil captured_args[:level], "Level should be nil to use default, or explicitly :warn"
  end

  def test_render_with_literal_identifiers
    # Removed unused variables, using markup_corrected and expected_identifiers_corrected directly
    markup_corrected = "type='MY_CUSTOM_ERROR' reason='Failure with details.' id='item123' status='failed' count='5'"
    expected_identifiers_corrected = {
      "id" => "item123",
      "status" => "failed",
      "count" => "5" # LiquidUtils.resolve_value for "'5'" returns string "5"
    }

    mock_return_value = "<!-- LOGGED WITH LITERALS -->"
    captured_args = nil
    PluginLoggerUtils.stub :log_liquid_failure, lambda { |args| captured_args = args; mock_return_value } do
      output = render_tag(markup_corrected)
      assert_equal mock_return_value, output
    end

    refute_nil captured_args
    # Assertion will now expect original casing due to fix in LogFailureTag
    assert_equal expected_identifiers_corrected, captured_args[:identifiers]
  end

  def test_render_with_variable_identifiers
    markup = "type='TEMPLATE_INFO' reason='User action.' path=page_path_var user=user_id_var current_status=status_var"
    expected_identifiers = {
      "path" => "path/from/variable.html",
      "user" => 12345,
      "current_status" => "pending"
    }
    mock_return_value = "<!-- LOGGED WITH VARIABLES -->"

    captured_args = nil
    PluginLoggerUtils.stub :log_liquid_failure, lambda { |args| captured_args = args; mock_return_value } do
      output = render_tag(markup)
      assert_equal mock_return_value, output
    end

    refute_nil captured_args
    # Assertion will now expect original casing
    assert_equal expected_identifiers, captured_args[:identifiers]
  end

  def test_render_with_mixed_literal_and_variable_identifiers
    markup = "type='MY_CUSTOM_ERROR' reason='Mixed event' literal_id='abc' var_id=user_id_var"
    expected_identifiers = {
      "literal_id" => "abc",
      "var_id" => 12345
    }
    mock_return_value = "<!-- LOGGED MIXED -->"

    captured_args = nil
    PluginLoggerUtils.stub :log_liquid_failure, lambda { |args| captured_args = args; mock_return_value } do
      output = render_tag(markup)
      assert_equal mock_return_value, output
    end

    refute_nil captured_args
    # Assertion will now expect original casing
    assert_equal expected_identifiers, captured_args[:identifiers]
  end

  def test_render_identifier_key_capitalization_is_preserved_by_tag
    markup = "type='T' reason='R' myKey='val' another_Key='val2'"
    expected_identifiers_passed_to_util = {
      "myKey" => "val",
      "another_Key" => "val2"
    }
    mock_return_value = "<!-- KEY TEST -->"
    captured_args = nil
    PluginLoggerUtils.stub :log_liquid_failure, lambda { |args| captured_args = args; mock_return_value } do
      render_tag(markup)
    end
    # Assertion will now expect original casing
    assert_equal expected_identifiers_passed_to_util, captured_args[:identifiers]
  end

  def test_render_handles_empty_markup_gracefully_but_fails_syntax
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% log_failure %}")
    end
    assert_match "Required argument 'type' is missing", err.message
  end
end
