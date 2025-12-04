# frozen_string_literal: true

# _tests/plugins/logic/book_lists/renderers/test_by_year_renderer.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/lists/renderers/by_year_renderer'

# Tests for Jekyll::Books::Lists::Renderers::ByYearRenderer
#
# Tests HTML generation from year-grouped book data.
class TestByYearRenderer < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({}, { site: @site })
  end

  def test_renders_empty_string_when_no_year_groups
    data = { year_groups: [] }

    Jekyll::Books::Core::BookCardUtils.stub :render, ->(_book, _ctx) { '<!-- Book Card -->' } do
      renderer = Jekyll::Books::Lists::Renderers::ByYearRenderer.new(@context, data)
      output = renderer.render
      assert_equal '', output
    end
  end

  def test_renders_year_groups_with_navigation
    book1 = create_doc({ 'title' => 'Book 1' })
    book2 = create_doc({ 'title' => 'Book 2' })
    book3 = create_doc({ 'title' => 'Book 3' })

    data = {
      year_groups: [
        { year: '2024', books: [book1] },
        { year: '2023', books: [book2, book3] }
      ]
    }

    Jekyll::Books::Core::BookCardUtils.stub :render, ->(_book, _ctx) { '<!-- Book Card -->' } do
      renderer = Jekyll::Books::Lists::Renderers::ByYearRenderer.new(@context, data)
      output = renderer.render

      # Assert navigation exists with both years
      assert_match(/<nav class="alpha-jump-links">/, output)
      assert_match %r{<a href="#year-2024">2024</a>}, output
      assert_match %r{<a href="#year-2023">2023</a>}, output
      assert_match %r{</nav>}, output

      # Assert year headings exist with correct IDs
      assert_match %r{<h2 class="book-list-headline" id="year-2024">2024</h2>}, output
      assert_match %r{<h2 class="book-list-headline" id="year-2023">2023</h2>}, output

      # Assert card grids exist
      assert_match(/<div class="card-grid">/, output)

      # Assert correct number of book cards (3 total: 1 in 2024, 2 in 2023)
      assert_equal 3, output.scan('<!-- Book Card -->').count
    end
  end

  def test_escapes_html_in_year_values
    book = create_doc({ 'title' => 'Book' })
    data = {
      year_groups: [
        { year: '<script>alert("xss")</script>', books: [book] }
      ]
    }

    Jekyll::Books::Core::BookCardUtils.stub :render, ->(_book, _ctx) { '<!-- Book Card -->' } do
      renderer = Jekyll::Books::Lists::Renderers::ByYearRenderer.new(@context, data)
      output = renderer.render

      # Assert the year is escaped in both navigation and heading
      refute_match(/<script>/, output)
      assert_match(/&lt;script&gt;/, output)
    end
  end
end
