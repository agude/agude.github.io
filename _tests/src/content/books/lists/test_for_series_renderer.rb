# frozen_string_literal: true

# _tests/plugins/logic/book_lists/renderers/test_for_series_renderer.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/lists/renderers/for_series_renderer'

# Tests for Jekyll::BookLists::ForSeriesRenderer
#
# Tests HTML generation for series book lists.
class TestForSeriesRenderer < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({}, { site: @site })
  end

  def test_renders_empty_string_when_no_books
    data = { books: [] }

    BookCardUtils.stub :render, ->(_book, _ctx) { '<!-- Book Card -->' } do
      renderer = Jekyll::BookLists::ForSeriesRenderer.new(@context, data)
      output = renderer.render
      assert_equal '', output
    end
  end

  def test_renders_books_in_card_grid
    book1 = create_doc({ 'title' => 'Book 1' })
    book2 = create_doc({ 'title' => 'Book 2' })
    book3 = create_doc({ 'title' => 'Book 3' })

    data = {
      books: [book1, book2, book3]
    }

    BookCardUtils.stub :render, ->(_book, _ctx) { '<!-- Book Card -->' } do
      renderer = Jekyll::BookLists::ForSeriesRenderer.new(@context, data)
      output = renderer.render

      # Assert card grid wrapper exists
      assert_match(/<div class="card-grid">/, output)
      assert_match %r{</div>}, output

      # Assert correct number of book cards
      assert_equal 3, output.scan('<!-- Book Card -->').count
    end
  end

  def test_handles_single_book
    book = create_doc({ 'title' => 'Solo Book' })

    data = { books: [book] }

    BookCardUtils.stub :render, ->(_book, _ctx) { '<!-- Book Card -->' } do
      renderer = Jekyll::BookLists::ForSeriesRenderer.new(@context, data)
      output = renderer.render

      # Assert card grid exists
      assert_match(/<div class="card-grid">/, output)

      # Assert single book card rendered
      assert_equal 1, output.scan('<!-- Book Card -->').count
    end
  end

  def test_handles_missing_books_key
    data = {}

    BookCardUtils.stub :render, ->(_book, _ctx) { '<!-- Book Card -->' } do
      renderer = Jekyll::BookLists::ForSeriesRenderer.new(@context, data)
      output = renderer.render

      # Should return empty string when books key is missing
      assert_equal '', output
    end
  end
end
