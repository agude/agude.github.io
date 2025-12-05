# frozen_string_literal: true

# _tests/plugins/logic/book_lists/renderers/test_by_author_then_series_renderer.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/lists/renderers/by_author_then_series_renderer'

# Tests for Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer
#
# Tests HTML generation from author-grouped book data with series.
class TestByAuthorThenSeriesRenderer < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({}, { site: @site })
  end

  def test_renders_empty_string_when_no_authors
    data = { authors_data: [] }

    Jekyll::Books::Core::BookCardUtils.stub :render, ->(_book, _ctx) { '<!-- Book Card -->' } do
      renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)
      output = renderer.render
      assert_equal '', output
    end
  end

  def test_renders_author_with_standalone_books_only
    standalone_book = create_doc({ 'title' => 'Standalone' })

    data = {
      authors_data: [
        {
          author_name: 'John Doe',
          standalone_books: [standalone_book],
          series_groups: []
        }
      ]
    }

    Jekyll::Books::Core::BookCardUtils.stub :render, ->(_book, _ctx) { '<!-- Book Card -->' } do
      renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)
      output = renderer.render

      # Assert navigation exists
      assert_match(/<nav class="alpha-jump-links">/, output)
      assert_match %r{<a href="#john-doe">J</a>}, output

      # Assert author heading
      assert_match %r{<h2 class="book-list-headline" id="john-doe">John Doe</h2>}, output

      # Assert standalone books section
      assert_match %r{<h3 class="book-list-headline" id="standalone-books-john-doe">Standalone Books</h3>}, output
      assert_match(/<!-- Book Card -->/, output)
    end
  end

  def test_renders_author_with_series_only
    data = {
      authors_data: [
        {
          author_name: 'Jane Smith',
          standalone_books: [],
          series_groups: [
            { name: 'Series One', books: [create_doc] }
          ]
        }
      ]
    }

    Jekyll::Books::Core::BookCardUtils.stub :render, ->(_book, _ctx) { '<!-- Book Card -->' } do
      Jekyll::Books::Lists::BookListRendererUtils.stub :render_book_groups_html, ->(_groups, _ctx, _heading_level) { '<!-- Series Books -->' } do
        renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)
        output = renderer.render

        # Assert author heading
        assert_match %r{<h2 class="book-list-headline" id="jane-smith">Jane Smith</h2>}, output

        # Assert series books rendered (via Jekyll::Books::Lists::BookListRendererUtils)
        assert_match(/<!-- Series Books -->/, output)

        # Should NOT render standalone section
        refute_match(/Standalone Books/, output)
      end
    end
  end

  def test_renders_multiple_authors_with_navigation
    data = {
      authors_data: [
        {
          author_name: 'Alice Author',
          standalone_books: [],
          series_groups: []
        },
        {
          author_name: 'Bob Writer',
          standalone_books: [],
          series_groups: []
        },
        {
          author_name: 'Zara Last',
          standalone_books: [],
          series_groups: []
        }
      ]
    }

    Jekyll::Books::Core::BookCardUtils.stub :render, ->(_book, _ctx) { '<!-- Book Card -->' } do
      renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)
      output = renderer.render

      # Assert navigation has correct letters (A, B, Z active, others as spans)
      assert_match %r{<a href="#alice-author">A</a>}, output
      assert_match %r{<a href="#bob-writer">B</a>}, output
      assert_match %r{<span>C</span>}, output
      assert_match %r{<a href="#zara-last">Z</a>}, output
    end
  end

  def test_escapes_html_in_author_names
    data = {
      authors_data: [
        {
          author_name: '<script>alert("xss")</script>',
          standalone_books: [],
          series_groups: []
        }
      ]
    }

    Jekyll::Books::Core::BookCardUtils.stub :render, ->(_book, _ctx) { '<!-- Book Card -->' } do
      renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)
      output = renderer.render

      # Assert the author name is escaped
      refute_match(/<script>alert/, output)
      assert_match(/&lt;script&gt;/, output)
    end
  end
end
