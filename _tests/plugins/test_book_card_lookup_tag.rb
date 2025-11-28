# frozen_string_literal: true

# _tests/plugins/test_book_card_lookup_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/book_card_lookup_tag' # Load the tag

# Tests for BookCardLookupTag Liquid tag.
#
# Verifies that the tag correctly orchestrates between argument parsing,
# BookFinder, and BookCardUtils.
class TestBookCardLookupTag < Minitest::Test
  def setup
    create_test_books
    @site = create_test_site
    @context = create_test_context
    @silent_logger_stub = create_silent_logger_stub
  end

  # Helper to render the tag, stubs BookCardUtils.render by default
  def render_tag(markup, context = @context, &)
    output = ''
    stub_logic = determine_stub_logic(&)

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
      Liquid::Template.parse('{% book_card_lookup %}')
    end
    assert_match 'Could not find title value', err.message
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

  # --- Orchestration Tests ---

  def test_calls_book_finder_with_correct_arguments
    captured_args = {}
    mock_result = { book: @book1, error: nil }

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_result

    Jekyll::CardLookups::BookFinder.stub :new, lambda { |args|
      captured_args = args
      mock_finder
    } do
      BookCardUtils.stub :render, ->(_book, _ctx) { '<div>Card</div>' } do
        Jekyll.stub :logger, @silent_logger_stub do
          Liquid::Template.parse("{% book_card_lookup 'The First Book' %}").render!(@context)

          assert_equal @site, captured_args[:site]
          assert_equal 'The First Book', captured_args[:title]
          mock_finder.verify
        end
      end
    end
  end

  def test_calls_book_card_utils_with_found_book
    captured_book = nil
    captured_context = nil
    mock_result = { book: @book1, error: nil }

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_result

    Jekyll::CardLookups::BookFinder.stub :new, ->(_args) { mock_finder } do
      BookCardUtils.stub :render, lambda { |book, ctx|
        captured_book = book
        captured_context = ctx
        '<div>Card</div>'
      } do
        Jekyll.stub :logger, @silent_logger_stub do
          Liquid::Template.parse("{% book_card_lookup 'The First Book' %}").render!(@context)

          assert_equal @book1, captured_book
          assert_equal @context, captured_context
          mock_finder.verify
        end
      end
    end
  end

  def test_returns_output_from_book_card_utils
    mock_output = '<div class="custom-card">Custom Card HTML</div>'
    mock_result = { book: @book1, error: nil }

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_result

    Jekyll::CardLookups::BookFinder.stub :new, ->(_args) { mock_finder } do
      BookCardUtils.stub :render, ->(_book, _ctx) { mock_output } do
        Jekyll.stub :logger, @silent_logger_stub do
          output = Liquid::Template.parse("{% book_card_lookup 'The First Book' %}").render!(@context)

          assert_equal mock_output, output
          mock_finder.verify
        end
      end
    end
  end

  private

  # Creates test book documents
  def create_test_books
    @book1 = create_doc({ 'title' => 'The First Book', 'published' => true }, '/books/first.html')
    @book2 = create_doc({ 'title' => 'The Second Book', 'published' => true }, '/books/second.html')
    @unpublished_book = create_doc({ 'title' => 'Unpublished Title', 'published' => false },
                                   '/books/unpublished.html')
  end

  # Creates test site with books collection
  def create_test_site
    create_site(
      { 'url' => 'http://example.com' }, # For BookCardUtils -> CardDataExtractorUtils -> UrlUtils
      { 'books' => [@book1, @book2, @unpublished_book] }
    )
  end

  # Creates test context with variables
  def create_test_context
    create_context(
      {
        'page_book_title_var' => 'The First Book',
        'page_book_title_var_alt_case' => 'the second book',
        'nil_title_var' => nil
      },
      # Page path for SourcePage identifier in PluginLoggerUtils
      { site: @site, page: create_doc({ 'path' => 'current_lookup_page.md' }, '/current-lookup-page.html') }
    )
  end

  # Creates a silent logger stub
  def create_silent_logger_stub
    Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
  end

  # Determines the stub logic for BookCardUtils.render
  def determine_stub_logic(&book_card_utils_stub_block)
    if block_given?
      book_card_utils_stub_block
    else
      ->(book_obj, _ctx) { "<!-- BookCardUtils.render called for #{book_obj.data['title']} -->" }
    end
  end
end
