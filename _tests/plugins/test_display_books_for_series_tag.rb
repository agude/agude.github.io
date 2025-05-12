# _tests/plugins/test_display_books_for_series_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_books_for_series_tag'

class TestDisplayBooksForSeriesTag < Minitest::Test
  def setup
    @book1_s1 = create_doc({ 'title' => 'Series One Book 1', 'series' => 'Series One', 'book_number' => 1, 'published' => true }, '/s1b1.html')
    @book2_s1 = create_doc({ 'title' => 'Series One Book 2', 'series' => 'Series One', 'book_number' => 2, 'published' => true }, '/s1b2.html')
    @book_other_series = create_doc({ 'title' => 'Other Series Book 1', 'series' => 'Other Series', 'book_number' => 1, 'published' => true }, '/osb1.html')

    @site = create_site({}, { 'books' => [@book1_s1, @book2_s1, @book_other_series] })
    @context = create_context({ 'page_series_var' => 'Series One' }, { site: @site, page: create_doc({}, '/current.html') })

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
      def logger.log_level=(level); end;    def logger.progname=(name); end
    end
  end

  def render_tag(markup, context = @context)
    output = ""
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% display_books_for_series #{markup} %}").render!(context)
    end
    output
  end

  def test_render_books_for_existing_series_literal
    output = render_tag("'Series One'")
    assert_match %r{<div class="card-grid">}, output
    assert_match %r{<cite class="book-title">Series One Book 1</cite>}, output
    assert_match %r{<cite class="book-title">Series One Book 2</cite>}, output
    refute_match %r{Other Series Book 1}, output
    refute_match %r{<!--.*BOOK_LIST_SERIES_DISPLAY_FAILURE.*-->}, output
  end

  def test_render_books_for_existing_series_variable
    output = render_tag("page_series_var") # page_series_var is 'Series One'
    assert_match %r{<div class="card-grid">}, output
    assert_match %r{<cite class="book-title">Series One Book 1</cite>}, output
    assert_match %r{<cite class="book-title">Series One Book 2</cite>}, output
    refute_match %r{<!--.*BOOK_LIST_SERIES_DISPLAY_FAILURE.*-->}, output
  end

  def test_render_no_books_for_non_existent_series
    @site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true # Enable logging for this tag type
    output = render_tag("'NonExistent Series'")
    assert_match %r{<!-- BOOK_LIST_SERIES_DISPLAY_FAILURE: Reason='No books found for series or series name was empty\/nil' SeriesFilter='NonExistent Series'.* -->}, output
    refute_match %r{<div class="card-grid">}, output
  end

  def test_render_no_books_for_series_with_no_books
    empty_series_site = create_site({}, { 'books' => [@book_other_series] }) # Site where 'Series One' has no books
    empty_series_context = create_context({}, { site: empty_series_site, page: create_doc({}, '/current.html') })
    empty_series_site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true

    output = render_tag("'Series One'", empty_series_context)
    assert_match %r{<!-- BOOK_LIST_SERIES_DISPLAY_FAILURE: Reason='No books found for series or series name was empty\/nil' SeriesFilter='Series One'.* -->}, output
    refute_match %r{<div class="card-grid">}, output
  end

  def test_render_empty_for_nil_series_name_variable
    @context['nil_series_var'] = nil
    @site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true
    output = render_tag("nil_series_var")
    assert_match %r{<!-- BOOK_LIST_SERIES_DISPLAY_FAILURE: Reason='No books found for series or series name was empty\/nil' SeriesFilter='N/A'.* -->}, output
    refute_match %r{<div class="card-grid">}, output
  end

  def test_render_empty_for_empty_series_name_literal
    @site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true
    output = render_tag("''") # Empty string literal
    assert_match %r{<!-- BOOK_LIST_SERIES_DISPLAY_FAILURE: Reason='No books found for series or series name was empty\/nil' SeriesFilter=''.* -->}, output
    refute_match %r{<div class="card-grid">}, output
  end

  def test_syntax_error_missing_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_books_for_series %}")
    end
    assert_match(/Series name .* is required/, err.message)
  end
end
