# _tests/plugins/test_series_text_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/series_text_tag' # Load the tag class

class TestSeriesTextTag < Minitest::Test
  def setup
    # Create some mock series pages
    @series1_page = create_doc({ 'title' => 'Foundation', 'layout' => 'series_page' }, '/series/foundation.html')
    @series2_page = create_doc({ 'title' => 'The Expanse', 'layout' => 'series_page' }, '/series/expanse.html')
    @series3_page = create_doc({ 'title' => 'Dune Saga', 'layout' => 'series_page' }, '/series/dune.html')
    @series4_page = create_doc({ 'title' => 'The Wheel of Time Saga', 'layout' => 'series_page' }, '/series/wot.html')
    @series5_page = create_doc({ 'title' => 'Saga', 'layout' => 'series_page' }, '/series/saga-comic.html') # Series named 'Saga'
    # Add pages needed for the previously failing tests
    @arcane_page = create_doc({ 'title' => 'Arcane', 'layout' => 'series_page' }, '/series/arcane.html')
    @test_series_page = create_doc({ 'title' => 'Test Series', 'layout' => 'series_page' }, '/series/test.html')

    # Create mock site and context. create_site now runs the LinkCacheGenerator automatically.
    @site = create_site({}, {}, [
                          @series1_page, @series2_page, @series3_page, @series4_page, @series5_page,
                          @arcane_page, @test_series_page
                        ])
    @current_page = create_doc({}, '/current-page.html')
    @context = create_context({}, { site: @site, page: @current_page })
  end

  # Helper to render the tag
  def render_tag(markup)
    Liquid::Template.parse("{% series_text #{markup} %}").render!(@context)
  end

  # --- Test Cases ---

  def test_basic_series_linked
    markup = '"Foundation"'
    expected_link = '<a href="/series/foundation.html"><span class="book-series">Foundation</span></a>'
    expected_output = "the #{expected_link} series"
    assert_equal expected_output, render_tag(markup)
  end

  def test_series_starting_with_the_linked
    markup = '"The Expanse"'
    expected_link = '<a href="/series/expanse.html"><span class="book-series">The Expanse</span></a>'
    expected_output = "#{expected_link} series" # No "the " prefix
    assert_equal expected_output, render_tag(markup)
  end

  def test_series_starting_with_the_case_insensitive_linked
    markup = '"the expanse"' # Input is lowercase
    expected_link = '<a href="/series/expanse.html"><span class="book-series">The Expanse</span></a>' # Output uses canonical title
    expected_output = "#{expected_link} series" # No "the " prefix
    assert_equal expected_output, render_tag(markup)
  end

  def test_series_containing_keyword_linked
    markup = '"Dune Saga"'
    expected_link = '<a href="/series/dune.html"><span class="book-series">Dune Saga</span></a>'
    expected_output = "the #{expected_link}" # No " series" suffix
    assert_equal expected_output, render_tag(markup)
  end

  def test_series_containing_keyword_case_insensitive_linked
    markup = '"dune saga"' # Input is lowercase
    expected_link = '<a href="/series/dune.html"><span class="book-series">Dune Saga</span></a>' # Output uses canonical title
    expected_output = "the #{expected_link}" # No " series" suffix
    assert_equal expected_output, render_tag(markup)
  end

  def test_series_starting_with_the_and_containing_keyword_linked
    markup = '"The Wheel of Time Saga"'
    expected_link = '<a href="/series/wot.html"><span class="book-series">The Wheel of Time Saga</span></a>'
    expected_output = "#{expected_link}" # No "the " prefix, no " series" suffix
    assert_equal expected_output, render_tag(markup)
  end

  def test_series_name_is_keyword_linked
    markup = '"Saga"'
    expected_link = '<a href="/series/saga-comic.html"><span class="book-series">Saga</span></a>'
    expected_output = "the #{expected_link}" # No " series" suffix
    assert_equal expected_output, render_tag(markup)
  end

  def test_series_not_found_unlinked
    markup = '"Unknown"'
    expected_span = '<span class="book-series">Unknown</span>' # render_series_link returns unlinked span
    expected_output = "the #{expected_span} series"
    assert_equal expected_output, render_tag(markup)
  end

  def test_series_not_found_starting_with_the
    markup = '"The Unknown"'
    expected_span = '<span class="book-series">The Unknown</span>'
    expected_output = "#{expected_span} series" # No "the " prefix
    assert_equal expected_output, render_tag(markup)
  end

  def test_series_not_found_containing_keyword
    markup = '"Unknown Saga"'
    expected_span = '<span class="book-series">Unknown Saga</span>'
    expected_output = "the #{expected_span}" # No " series" suffix
    assert_equal expected_output, render_tag(markup)
  end

  def test_series_not_found_starting_with_the_and_containing_keyword
    markup = '"The Unknown Saga"'
    expected_span = '<span class="book-series">The Unknown Saga</span>'
    expected_output = "#{expected_span}" # No prefix or suffix
    assert_equal expected_output, render_tag(markup)
  end

  def test_series_not_found_middle_word_unlinked
    markup = '"The Chronicles of Narnia"'
    expected_span = '<span class="book-series">The Chronicles of Narnia</span>'
    expected_output = "#{expected_span}"
    assert_equal expected_output, render_tag(markup)
  end

  def test_series_not_found_starts_with_a
    markup = '"A Song of Ice and Fire"'
    expected_span = '<span class="book-series">A Song of Ice and Fire</span>'
    expected_output = "#{expected_span}"
    assert_equal expected_output, render_tag(markup)
  end

  def test_series_with_variable
    @context['my_series_var'] = 'Foundation'
    markup = 'my_series_var'
    expected_link = '<a href="/series/foundation.html"><span class="book-series">Foundation</span></a>'
    expected_output = "the #{expected_link} series"
    assert_equal expected_output, render_tag(markup)
  end

  def test_empty_input_string
    markup = '""'
    assert_equal '', render_tag(markup)
  end

  def test_empty_input_variable
    @context['empty_var'] = ''
    markup = 'empty_var'
    assert_equal '', render_tag(markup)
  end

  def test_nil_input_variable
    @context['nil_var'] = nil
    markup = 'nil_var'
    assert_equal '', render_tag(markup)
  end

  def test_whitespace_input_string
    markup = '"   "'
    assert_equal '', render_tag(markup)
  end

  def test_keyword_as_substring_does_not_prevent_suffix
    markup = '"Arcane"' # Contains "arc" but not " arc "
    expected_link = '<a href="/series/arcane.html"><span class="book-series">Arcane</span></a>'
    expected_output = "the #{expected_link} series" # Should still get " series" suffix
    assert_equal expected_output, render_tag(markup)
  end

  def test_syntax_error_missing_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% series_text %}')
    end
    assert_match(/Could not find series name/, err.message)
  end

  def test_syntax_error_extra_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% series_text "Foundation" extra=arg %}')
    end
    assert_match(/Unexpected arguments/, err.message)
  end

  def test_series_ending_with_series_word
    markup = '"Test Series"'
    expected_link = '<a href="/series/test.html"><span class="book-series">Test Series</span></a>'
    # Now expect NO " series" suffix because the input ends with it (after fix)
    expected_output = "the #{expected_link}"
    assert_equal expected_output, render_tag(markup)
  end
end
