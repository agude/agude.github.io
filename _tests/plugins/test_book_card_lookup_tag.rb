# _tests/plugins/test_book_card_lookup_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/book_card_lookup_tag' # Load the tag

class TestBookCardLookupTag < Minitest::Test

  def setup
    @book1 = create_doc({ 'title' => 'The First Book', 'published' => true }, '/books/first.html')
    @book2 = create_doc({ 'title' => 'The Second Book', 'published' => true }, '/books/second.html')
    @unpublished_book = create_doc({ 'title' => 'Unpublished Title', 'published' => false }, '/books/unpublished.html')

    @site = create_site(
      { 'url' => 'http://example.com' }, # For BookCardUtils -> CardDataExtractorUtils -> UrlUtils
      { 'books' => [@book1, @book2, @unpublished_book] }
    )
    @context = create_context(
      {
        'page_book_title_var' => 'The First Book',
        'page_book_title_var_alt_case' => 'the second book',
        'nil_title_var' => nil
      },
      # Page path for SourcePage identifier in PluginLoggerUtils
      { site: @site, page: create_doc({ 'path' => 'current_lookup_page.md' }, '/current-lookup-page.html') }
    )

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
    end
  end

  # Helper to render the tag, stubs BookCardUtils.render by default
  def render_tag(markup, context = @context, &book_card_utils_stub_block)
    output = ""
    stub_logic = if block_given?
                   book_card_utils_stub_block
                 else
                   ->(book_obj, _ctx) { "<!-- BookCardUtils.render called for #{book_obj.data['title']} -->" }
                 end

    Jekyll.stub :logger, @silent_logger_stub do # Silence PluginLoggerUtils console output
      BookCardUtils.stub :render, stub_logic do
        output = Liquid::Template.parse("{% book_card_lookup #{markup} %}").render!(context)
      end
    end
    output
  end

  # --- Syntax Error Tests (Initialize) ---
  def test_syntax_error_missing_title_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% book_card_lookup %}")
    end
    assert_match "Could not find title value", err.message
  end

  def test_syntax_error_unknown_extra_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% book_card_lookup 'My Book' extra='bad' %}")
    end
    assert_match "Unknown argument(s) 'extra='bad''", err.message

    err_named = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% book_card_lookup title='My Book' extra='bad' %}")
    end
    assert_match "Unknown argument(s) 'extra='bad''", err_named.message
  end


  # --- Argument Parsing and Lookup Success Tests ---
  def test_lookup_with_named_title_literal_quoted
    output = render_tag("title='The First Book'")
    assert_match "<!-- BookCardUtils.render called for The First Book -->", output
  end

  def test_lookup_with_named_title_literal_unquoted_variable_value
    # This tests if title=variable (where variable is a string) works.
    # The parser for named args in the tag allows unquoted values if they don't contain spaces.
    # However, LiquidUtils.resolve_value will treat an unquoted value as a variable name.
    # So, title=the first book would try to look up a var `the first book`.
    # This test should be for title=page_book_title_var
    output = render_tag("title=page_book_title_var") # page_book_title_var = "The First Book"
    assert_match "<!-- BookCardUtils.render called for The First Book -->", output
  end

  def test_lookup_with_positional_title_literal_quoted
    output = render_tag("'The Second Book'")
    assert_match "<!-- BookCardUtils.render called for The Second Book -->", output
  end

  def test_lookup_with_positional_title_variable
    output = render_tag("page_book_title_var") # "The First Book"
    assert_match "<!-- BookCardUtils.render called for The First Book -->", output
  end

  def test_lookup_is_case_insensitive_and_normalizes_whitespace
    output_pos = render_tag("'  the FiRsT     BoOk  '")
    assert_match "<!-- BookCardUtils.render called for The First Book -->", output_pos

    output_named = render_tag("title=page_book_title_var_alt_case") # "the second book"
    assert_match "<!-- BookCardUtils.render called for The Second Book -->", output_named
  end

  def test_lookup_ignores_unpublished_books
    @site.config['plugin_logging']['BOOK_CARD_LOOKUP'] = true # Enable logging
    # 'Unpublished Title' exists but is unpublished.
    output = render_tag("'Unpublished Title'")
    assert_match %r{<!-- \[WARN\] BOOK_CARD_LOOKUP_FAILURE: Reason='Could not find book\.'\s*Title='Unpublished Title'\s*SourcePage='current_lookup_page\.md' -->}, output
    refute_match "BookCardUtils.render called", output
  end

  # --- Failure and Logging Tests ---
  def test_logs_error_if_title_resolves_to_nil
    @site.config['plugin_logging']['BOOK_CARD_LOOKUP'] = true
    output = render_tag("nil_title_var") # nil_title_var is nil
    assert_match %r{<!-- \[ERROR\] BOOK_CARD_LOOKUP_FAILURE: Reason='Title markup resolved to empty or nil\.'\s*Markup='nil_title_var'\s*SourcePage='current_lookup_page\.md' -->}, output
    refute_match "BookCardUtils.render called", output
  end

  def test_logs_error_if_title_resolves_to_empty_string
    @context['empty_title_var'] = "   "
    @site.config['plugin_logging']['BOOK_CARD_LOOKUP'] = true
    output = render_tag("empty_title_var")
    assert_match %r{<!-- \[ERROR\] BOOK_CARD_LOOKUP_FAILURE: Reason='Title markup resolved to empty or nil\.'\s*Markup='empty_title_var'\s*SourcePage='current_lookup_page\.md' -->}, output
    refute_match "BookCardUtils.render called", output
  end

  def test_logs_warn_if_book_not_found
    @site.config['plugin_logging']['BOOK_CARD_LOOKUP'] = true
    output = render_tag("'NonExistent Book Of Wonders'")
    assert_match %r{<!-- \[WARN\] BOOK_CARD_LOOKUP_FAILURE: Reason='Could not find book\.'\s*Title='NonExistent Book Of Wonders'\s*SourcePage='current_lookup_page\.md' -->}, output
    refute_match "BookCardUtils.render called", output
  end

  def test_logs_error_if_books_collection_missing
    site_no_books = create_site({ 'url' => 'http://example.com' }, {}) # No 'books' collection
    site_no_books.config['plugin_logging']['BOOK_CARD_LOOKUP'] = true
    context_no_books = create_context({}, { site: site_no_books, page: create_doc({ 'path' => 'current_lookup_page.md' }, '/current-lookup-page.html') })

    output = render_tag("'Any Book Title'", context_no_books)
    assert_match %r{<!-- \[ERROR\] BOOK_CARD_LOOKUP_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*Title='Any Book Title'\s*SourcePage='current_lookup_page\.md' -->}, output
    refute_match "BookCardUtils.render called", output
  end

  def test_logs_error_if_book_card_utils_render_fails
    @site.config['plugin_logging']['BOOK_CARD_LOOKUP'] = true
    error_message = "Utility render failed!"

    # Custom stub for BookCardUtils.render that raises an error
    failing_stub = ->(_book_obj, _ctx) { raise StandardError, error_message }

    output = render_tag("'The First Book'", @context, &failing_stub)

    assert_match %r{<!-- \[ERROR\] BOOK_CARD_LOOKUP_FAILURE: Reason='Error calling BookCardUtils\.render utility: #{error_message}'\s*Title='The First Book'\s*ErrorClass='StandardError'\s*ErrorMessage='#{error_message.slice(0,100)}'\s*SourcePage='current_lookup_page\.md' -->}, output
  end
end
