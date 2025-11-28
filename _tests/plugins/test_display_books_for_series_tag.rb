# frozen_string_literal: true

# _tests/plugins/test_display_books_for_series_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_books_for_series_tag'

# Tests for DisplayBooksForSeriesTag Liquid tag.
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
      log_messages: ''
    }

    # 2. Define the mock HTML that the Renderer will "return"
    mock_renderer_html = '<div class="card-grid">Book Cards</div>'

    # 3. Set up mocks for the Finder and Renderer
    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_finder_data

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, mock_renderer_html

    # Stub the .new methods to return our mock instances
    Jekyll::BookLists::SeriesFinder.stub :new, lambda { |args|
      # Verify the series_name_filter is passed correctly
      assert_equal 'Test Series', args[:series_name_filter]
      mock_finder
    } do
      Jekyll::BookLists::ForSeriesRenderer.stub :new, lambda { |context, data|
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
      log_messages: ''
    }
    mock_renderer_html = '<div class="card-grid">Book Cards</div>'

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_finder_data

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, mock_renderer_html

    Jekyll::BookLists::SeriesFinder.stub :new, lambda { |args|
      # Verify the series_name_filter is resolved from the variable
      assert_equal 'Test Series', args[:series_name_filter]
      mock_finder
    } do
      Jekyll::BookLists::ForSeriesRenderer.stub :new, ->(_context, _data) { mock_renderer } do
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
      log_messages: '<!-- Log Message -->'
    }
    mock_renderer_html = ''

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_finder_data

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, mock_renderer_html

    Jekyll::BookLists::SeriesFinder.stub :new, ->(_args) { mock_finder } do
      Jekyll::BookLists::ForSeriesRenderer.stub :new, ->(_context, _data) { mock_renderer } do
        output = Liquid::Template.parse("{% display_books_for_series 'Empty Series' %}").render!(@context)

        # Log messages should come before rendered HTML
        assert_equal '<!-- Log Message -->', output
      end
    end

    mock_finder.verify
    mock_renderer.verify
  end
end
