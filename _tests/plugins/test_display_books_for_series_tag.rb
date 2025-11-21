# frozen_string_literal: true

# _tests/plugins/test_display_books_for_series_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_books_for_series_tag'

class TestDisplayBooksForSeriesTag < Minitest::Test
  def setup
    create_test_books
    setup_site_and_context
    @silent_logger_stub = create_silent_logger_stub
  end

  def render_tag(markup, context = @context)
    output = ''
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% display_books_for_series #{markup} %}").render!(context)
    end
    output
  end

  def test_render_books_for_existing_series_literal
    output = render_tag("'Series One'")
    assert_match(/<div class="card-grid">/, output)
    assert_match %r{<cite class="book-title">Series One Book 1</cite>}, output
    assert_match %r{<cite class="book-title">Series One Book 2</cite>}, output
    refute_match(/Other Series Book 1/, output)
    # Expect no log comment because books were found
    refute_match(/<!--.*BOOK_LIST_SERIES_DISPLAY_FAILURE.*-->/, output)
  end

  def test_render_books_for_existing_series_variable
    output = render_tag('page_series_var') # page_series_var is 'Series One'
    assert_match(/<div class="card-grid">/, output)
    assert_match %r{<cite class="book-title">Series One Book 1</cite>}, output
    assert_match %r{<cite class="book-title">Series One Book 2</cite>}, output
    refute_match(/<!--.*BOOK_LIST_SERIES_DISPLAY_FAILURE.*-->/, output)
  end

  def test_render_no_books_for_non_existent_series
    @site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true
    output = render_tag("'NonExistent Series'")
    # BookListUtils logs with :info level and "No books found for the specified series."
    assert_match(
      /<!-- \[INFO\] BOOK_LIST_SERIES_DISPLAY_FAILURE:.*Reason='No books found for the specified series\.'.*SeriesFilter='NonExistent Series'.*SourcePage='current\.html' -->/,
      output
    )
    refute_match(/<div class="card-grid">/, output)
  end

  def test_render_no_books_for_series_with_no_books
    empty_series_site = create_site({ 'url' => 'http://example.com' }, { 'books' => [@book_other_series] })
    empty_series_context = create_context(
      {},
      { site: empty_series_site, page: create_doc({ 'path' => 'current.html' }, '/current.html') }
    )
    empty_series_site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true

    output = render_tag("'Series One'", empty_series_context)
    # BookListUtils logs with :info level
    assert_match(
      /<!-- \[INFO\] BOOK_LIST_SERIES_DISPLAY_FAILURE:.*Reason='No books found for the specified series\.'.*SeriesFilter='Series One'.*SourcePage='current\.html' -->/,
      output
    )
    refute_match(/<div class="card-grid">/, output)
  end

  def test_render_empty_for_nil_series_name_variable
    @context['nil_series_var'] = nil
    @site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true
    output = render_tag('nil_series_var')
    assert_match(
      %r{<!-- \[WARN\] BOOK_LIST_SERIES_DISPLAY_FAILURE:.*Reason='Series name filter was empty or nil\.'.*SeriesFilterInput='N/A'.*SourcePage='current\.html' -->},
      output
    )
    refute_match(/<div class="card-grid">/, output)
  end

  def test_render_empty_for_empty_series_name_literal
    @site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true
    output = render_tag("''")
    assert_match(
      /<!-- \[WARN\] BOOK_LIST_SERIES_DISPLAY_FAILURE:.*Reason='Series name filter was empty or nil\.'.*SeriesFilterInput=''.*SourcePage='current\.html' -->/,
      output
    )
    refute_match(/<div class="card-grid">/, output)
  end

  def test_syntax_error_missing_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_books_for_series %}')
    end
    assert_match(/Series name .* is required/, err.message)
  end

  private

  def create_test_books
    @book1_s1 = create_doc(
      { 'title' => 'Series One Book 1', 'series' => 'Series One', 'book_number' => 1,
        'published' => true }, '/s1b1.html'
    )
    @book2_s1 = create_doc(
      { 'title' => 'Series One Book 2', 'series' => 'Series One', 'book_number' => 2,
        'published' => true }, '/s1b2.html'
    )
    @book_other_series = create_doc(
      { 'title' => 'Other Series Book 1', 'series' => 'Other Series', 'book_number' => 1,
        'published' => true }, '/osb1.html'
    )
  end

  def setup_site_and_context
    # Ensure site has a URL for UrlUtils called by BookCardUtils->CardDataExtractorUtils
    @site = create_site(
      { 'url' => 'http://example.com' },
      { 'books' => [@book1_s1, @book2_s1, @book_other_series] }
    )
    # Added path for SourcePage
    @context = create_context(
      { 'page_series_var' => 'Series One' },
      { site: @site, page: create_doc({ 'path' => 'current.html' }, '/current.html') }
    )
  end

  def create_silent_logger_stub
    Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end

      def logger.log_level=(level); end

      def logger.progname=(name); end
    end
  end
end
