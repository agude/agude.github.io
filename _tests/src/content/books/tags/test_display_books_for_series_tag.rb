# frozen_string_literal: true

# _tests/plugins/test_display_books_for_series_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/tags/display_books_for_series_tag'

# Tests for Jekyll::Books::Tags::DisplayBooksForSeriesTag Liquid tag.
#
# Verifies that the tag correctly orchestrates the Finder and Renderer.
class TestDisplayBooksForSeriesTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({ 'series_var' => 'Test Series' }, { site: @site })
  end

  def test_syntax_error_missing_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_books_for_series %}')
    end
    assert_match(/Series name .* is required/, err.message)
  end

  def test_render_orchestrates_finder_and_renderer_with_literal
    # 1. Define the mock data that the Finder will "return"
    mock_book = create_doc({ 'title' => 'Test Book', 'series' => 'Test Series' })
    mock_finder_data = {
      books: [mock_book],
      log_messages: '',
    }

    # 2. Define the mock HTML that the Renderer will "return"
    mock_renderer_html = '<div class="card-grid">Book Cards</div>'

    # 3. Set up mocks for the Finder and Renderer
    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_finder_data

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, mock_renderer_html

    # Stub the .new methods to return our mock instances
    Jekyll::Books::Lists::SeriesFinder.stub :new,
                                            lambda { |args|
                                              # Verify the series_name_filter is passed correctly
                                              assert_equal 'Test Series', args[:series_name_filter]
                                              mock_finder
                                            } do
      Jekyll::Books::Lists::Renderers::ForSeriesRenderer.stub :new,
                                                              lambda { |context, data|
                                                                # This is a key assertion: ensure the data from the finder is what the renderer receives
                                                                assert_equal mock_finder_data, data
                                                                assert_equal @context, context
                                                                mock_renderer # Return our mock renderer instance
                                                              } do
        # Execute the tag with a literal series name
        output = Liquid::Template.parse("{% display_books_for_series 'Test Series' %}").render!(@context)

        # Assert that the final output is composed correctly (log_messages + rendered HTML)
        assert_equal '<div class="card-grid">Book Cards</div>', output
      end
    end

    # Verify that both find and render methods were called exactly once
    mock_finder.verify
    mock_renderer.verify
  end

  def test_render_orchestrates_finder_and_renderer_with_variable
    # Test with a variable instead of a literal
    mock_book = create_doc({ 'title' => 'Test Book', 'series' => 'Test Series' })
    mock_finder_data = {
      books: [mock_book],
      log_messages: '',
    }
    mock_renderer_html = '<div class="card-grid">Book Cards</div>'

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_finder_data

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, mock_renderer_html

    Jekyll::Books::Lists::SeriesFinder.stub :new,
                                            lambda { |args|
                                              # Verify the series_name_filter is resolved from the variable
                                              assert_equal 'Test Series', args[:series_name_filter]
                                              mock_finder
                                            } do
      Jekyll::Books::Lists::Renderers::ForSeriesRenderer.stub :new, ->(_context, _data) { mock_renderer } do
        # Use the variable defined in setup
        output = Liquid::Template.parse('{% display_books_for_series series_var %}').render!(@context)
        assert_equal '<div class="card-grid">Book Cards</div>', output
      end
    end

    mock_finder.verify
    mock_renderer.verify
  end

  def test_render_includes_log_messages_from_finder
    # Test that log messages from the finder are prepended to the renderer output
    mock_finder_data = {
      books: [],
      log_messages: '<!-- Log Message -->',
    }
    mock_renderer_html = ''

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_finder_data

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, mock_renderer_html

    Jekyll::Books::Lists::SeriesFinder.stub :new, ->(_args) { mock_finder } do
      Jekyll::Books::Lists::Renderers::ForSeriesRenderer.stub :new, ->(_context, _data) { mock_renderer } do
        output = Liquid::Template.parse("{% display_books_for_series 'Empty Series' %}").render!(@context)

        # Log messages should come before rendered HTML
        assert_equal '<!-- Log Message -->', output
      end
    end

    mock_finder.verify
    mock_renderer.verify
  end

  def test_render_with_nil_series_name_variable
    # This tests line 33 and the else branch on line 30
    # When series name resolves to nil, it should be passed as-is (not converted to string)
    context_with_nil = create_context({ 'nil_var' => nil }, { site: @site })

    mock_finder_data = {
      books: [],
      log_messages: '',
    }
    mock_renderer_html = ''

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_finder_data

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, mock_renderer_html

    Jekyll::Books::Lists::SeriesFinder.stub :new,
                                            lambda { |args|
                                              # Verify that nil is passed as the filter (not converted to string)
                                              assert_nil args[:series_name_filter]
                                              mock_finder
                                            } do
      Jekyll::Books::Lists::Renderers::ForSeriesRenderer.stub :new, ->(_context, _data) { mock_renderer } do
        output = Liquid::Template.parse('{% display_books_for_series nil_var %}').render!(context_with_nil)
        assert_equal '', output
      end
    end

    mock_finder.verify
    mock_renderer.verify
  end

  def test_render_with_empty_string_series_name
    # Test when series name is an empty string (after strip)
    context_with_empty = create_context({ 'empty_var' => '   ' }, { site: @site })

    mock_finder_data = {
      books: [],
      log_messages: '',
    }
    mock_renderer_html = ''

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_finder_data

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, mock_renderer_html

    Jekyll::Books::Lists::SeriesFinder.stub :new,
                                            lambda { |args|
                                              # Verify that the empty string (after strip) is passed as-is
                                              assert_equal '   ', args[:series_name_filter]
                                              mock_finder
                                            } do
      Jekyll::Books::Lists::Renderers::ForSeriesRenderer.stub :new, ->(_context, _data) { mock_renderer } do
        output = Liquid::Template.parse('{% display_books_for_series empty_var %}').render!(context_with_empty)
        assert_equal '', output
      end
    end

    mock_finder.verify
    mock_renderer.verify
  end

  # --- Markdown render mode ---

  def test_markdown_mode_outputs_numbered_list
    books = [
      create_doc(
        {
          'title' => 'Book 1',
          'series' => 'Test Series',
          'book_number' => 1,
          'book_authors' => ['Auth A'],
          'rating' => 4,
        },
        '/b1.html',
      ),
      create_doc(
        {
          'title' => 'Book 2',
          'series' => 'Test Series',
          'book_number' => 2,
          'book_authors' => ['Auth A'],
          'rating' => 5,
        },
        '/b2.html',
      ),
    ]
    site = create_site({ 'url' => 'http://example.com' }, { 'books' => books })
    md_context = create_context(
      {},
      {
        site: site,
        page: create_doc({ 'path' => 'test.html' }, '/test.html'),
        render_mode: :markdown,
      },
    )

    silent_logger = Object.new.tap do |l|
      def l.warn(_, _); end
      def l.error(_, _); end
      def l.info(_, _); end
      def l.debug(_, _); end
    end

    output = ''
    Jekyll.stub :logger, silent_logger do
      output = Liquid::Template.parse("{% display_books_for_series 'Test Series' %}").render!(md_context)
    end
    assert_includes output, '1. [Book 1](/b1.html)'
    assert_includes output, '2. [Book 2](/b2.html)'
    assert_includes output, 'by Auth A'
    refute_includes output, '<div'
    refute_includes output, '<cite'
  end
end
