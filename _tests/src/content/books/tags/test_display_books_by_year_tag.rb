# frozen_string_literal: true

# _tests/plugins/test_display_books_by_year_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/tags/display_books_by_year_tag'

# Tests for Jekyll::Books::Tags::DisplayBooksByYearTag Liquid tag.
#
# Verifies that the tag correctly orchestrates the Finder and Renderer.
class TestDisplayBooksByYearTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({}, { site: @site })
  end

  def test_syntax_error_if_arguments_provided
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_books_by_year some_arg %}')
    end
    assert_match 'This tag does not accept any arguments', err.message
  end

  def test_render_orchestrates_finder_and_renderer
    # 1. Define the mock data that the Finder will "return"
    mock_book = create_doc({ 'title' => 'Test Book' })
    mock_finder_data = {
      year_groups: [{ year: '2024', books: [mock_book] }],
      log_messages: ''
    }

    # 2. Define the mock HTML that the Renderer will "return"
    mock_renderer_html = '<h1>Rendered HTML</h1>'

    # 3. Set up mocks for the Finder and Renderer
    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_finder_data

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, mock_renderer_html

    # Stub the .new methods to return our mock instances
    Jekyll::Books::Lists::Renderers::BookLists::ByYearFinder.stub :new, ->(_args) { mock_finder } do
      Jekyll::Books::Lists::Renderers::BookLists::ByYearRenderer.stub :new, lambda { |context, data|
        # This is a key assertion: ensure the data from the finder is what the renderer receives
        assert_equal mock_finder_data, data
        assert_equal @context, context
        mock_renderer # Return our mock renderer instance
      } do
        # Execute the tag
        output = Liquid::Template.parse('{% display_books_by_year %}').render!(@context)

        # Assert that the final output is composed correctly (log_messages + rendered HTML)
        assert_equal '<h1>Rendered HTML</h1>', output
      end
    end

    # Verify that both find and render methods were called exactly once
    mock_finder.verify
    mock_renderer.verify
  end

  def test_render_includes_log_messages_from_finder
    # Test that log messages from the finder are prepended to the renderer output
    mock_finder_data = {
      year_groups: [],
      log_messages: '<!-- Log Message -->'
    }
    mock_renderer_html = '<div>No books</div>'

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_finder_data

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, mock_renderer_html

    Jekyll::Books::Lists::Renderers::BookLists::ByYearFinder.stub :new, ->(_args) { mock_finder } do
      Jekyll::Books::Lists::Renderers::BookLists::ByYearRenderer.stub :new, ->(_context, _data) { mock_renderer } do
        output = Liquid::Template.parse('{% display_books_by_year %}').render!(@context)

        # Log messages should come before rendered HTML
        assert_equal '<!-- Log Message --><div>No books</div>', output
      end
    end

    mock_finder.verify
    mock_renderer.verify
  end
end
