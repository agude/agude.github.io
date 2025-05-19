# _tests/plugins/test_units_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/units_tag' # Load the tag

class TestUnitsTag < Minitest::Test
  THIN_NBSP = "&#x202F;"

  def setup
    # Site with default logging off, but specific tags can be enabled in tests
    @site = create_site({ 'url' => 'http://example.com' })
    @context = create_context(
      { 'page_num' => "37.5", 'page_unit' => "C", 'nil_val' => nil, 'empty_val' => "" },
      { site: @site, page: create_doc({ 'path' => 'current_test_page.html' }, '/current.html') } # Page path for SourcePage
    )

    # Silent logger for tests not asserting specific console output
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
      def logger.log_level=(level); end;    def logger.progname=(name); end
    end
  end

  def render_tag(markup, context = @context)
    output = ""
    # Stub Jekyll.logger to silence console output from PluginLoggerUtils during tests
    # unless a specific test is designed to capture it.
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% units #{markup} %}").render!(context)
    end
    output
  end

  # --- Success Cases ---
  def test_render_known_unit_fahrenheit_literal
    output = render_tag('number="98.6" unit="F"')
    expected = "<span class=\"nowrap unit\">98.6#{THIN_NBSP}<abbr class=\"unit-abbr\" title=\"Degrees Fahrenheit\">°F</abbr></span>"
    assert_equal expected, output
  end

  def test_render_known_unit_celsius_variable
    output = render_tag('number=page_num unit=page_unit') # page_num="37.5", page_unit="C"
    expected = "<span class=\"nowrap unit\">37.5#{THIN_NBSP}<abbr class=\"unit-abbr\" title=\"Degrees Celsius\">°C</abbr></span>"
    assert_equal expected, output
  end

  def test_render_known_unit_kilograms
    output = render_tag('number="2.5" unit="kg"')
    expected = "<span class=\"nowrap unit\">2.5#{THIN_NBSP}<abbr class=\"unit-abbr\" title=\"Kilograms\">kg</abbr></span>"
    assert_equal expected, output
  end

  def test_render_number_with_html_chars_is_escaped
    output = render_tag('number="<100" unit="g"')
    expected = "<span class=\"nowrap unit\">&lt;100#{THIN_NBSP}<abbr class=\"unit-abbr\" title=\"Grams\">g</abbr></span>"
    assert_equal expected, output
  end

  # --- Fallback and Warning for Unknown Unit ---
  def test_render_unknown_unit_fallback_and_logs_warning
    @site.config['plugin_logging']['UNITS_TAG_WARNING'] = true
    output = render_tag('number="42" unit="XYZ"')
    expected_html_part = "<span class=\"nowrap unit\">42#{THIN_NBSP}<abbr class=\"unit-abbr\" title=\"XYZ\">XYZ</abbr></span>"

    # Check for the warning comment
    assert_match %r{<!-- \[WARN\] UNITS_TAG_WARNING_FAILURE: Reason='Unit key not found in internal definitions\. Using key as symbol/name\.'\s*UnitKey='XYZ'\s*Number='42'\s*SourcePage='current_test_page\.html' -->}, output

    # Check for the rendered HTML span directly (without Regexp.escape)
    assert_match expected_html_part, output, "Rendered HTML part mismatch"
  end

  # --- Error Logging for Missing Resolved Values ---
  def test_logs_error_if_number_resolves_to_nil
    @site.config['plugin_logging']['UNITS_TAG_ERROR'] = true
    output = render_tag('number=nil_val unit="C"') # nil_val is nil
    expected_log = "<!-- [ERROR] UNITS_TAG_ERROR_FAILURE: Reason='Argument &#39;number&#39; resolved to nil or empty.' number_markup='nil_val' SourcePage='current_test_page.html' -->"
    assert_equal expected_log, output.strip
  end

  def test_logs_error_if_number_resolves_to_empty
    @site.config['plugin_logging']['UNITS_TAG_ERROR'] = true
    output = render_tag('number=empty_val unit="C"') # empty_val is ""
    expected_log = "<!-- [ERROR] UNITS_TAG_ERROR_FAILURE: Reason='Argument &#39;number&#39; resolved to nil or empty.' number_markup='empty_val' SourcePage='current_test_page.html' -->"
    assert_equal expected_log, output.strip
  end

  def test_logs_error_if_unit_resolves_to_nil
    @site.config['plugin_logging']['UNITS_TAG_ERROR'] = true
    output = render_tag('number="10" unit=nil_val')
    expected_log = "<!-- [ERROR] UNITS_TAG_ERROR_FAILURE: Reason='Argument &#39;unit&#39; resolved to nil or empty.' unit_markup='nil_val' number_val='10' SourcePage='current_test_page.html' -->"
    assert_equal expected_log, output.strip
  end

  def test_logs_error_if_unit_resolves_to_empty
    @site.config['plugin_logging']['UNITS_TAG_ERROR'] = true
    output = render_tag('number="10" unit=empty_val')
    expected_log = "<!-- [ERROR] UNITS_TAG_ERROR_FAILURE: Reason='Argument &#39;unit&#39; resolved to nil or empty.' unit_markup='empty_val' number_val='10' SourcePage='current_test_page.html' -->"
    assert_equal expected_log, output.strip
  end

  # --- Syntax Errors (Raised by initialize) ---
  def test_syntax_error_missing_number_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% units unit=\"C\" %}")
    end
    assert_match "Required argument 'number' is missing", err.message
  end

  def test_syntax_error_missing_unit_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% units number=\"10\" %}")
    end
    assert_match "Required argument 'unit' is missing", err.message
  end

  def test_syntax_error_invalid_arguments
    err = assert_raises Liquid::SyntaxError do
      # This will now be caught by the unknown argument check
      Liquid::Template.parse("{% units number=\"10\" unit=\"C\" extra='bad' %}")
    end
    assert_match "Unknown argument 'extra'", err.message
  end

  def test_syntax_error_trailing_garbage_arguments
    err = assert_raises Liquid::SyntaxError do
      # This will be caught by the scanner.eos? check after valid args
      Liquid::Template.parse("{% units number=\"10\" unit=\"C\" this is garbage %}")
    end
    assert_match "Invalid or unexpected trailing arguments near 'this is garbage'", err.message
  end


  def test_syntax_error_no_arguments
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% units %}")
    end
    # Will fail on 'number' first
    assert_match "Required argument 'number' is missing", err.message
  end
end
