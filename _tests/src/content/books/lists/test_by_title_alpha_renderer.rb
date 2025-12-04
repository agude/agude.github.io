# frozen_string_literal: true

# _tests/plugins/logic/book_lists/renderers/test_by_title_alpha_renderer.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/lists/renderers/by_title_alpha_renderer'

# Tests for Jekyll::Books::Lists::Renderers::BookLists::ByTitleAlphaRenderer
#
# Tests HTML generation from alphabetically-grouped book data.
class TestByTitleAlphaRenderer < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({}, { site: @site })
  end

  def test_renders_empty_string_when_no_alpha_groups
    data = { alpha_groups: [] }

    Jekyll::Books::Core::BookCardUtils.stub :render, ->(_book, _ctx) { '<!-- Book Card -->' } do
      renderer = Jekyll::Books::Lists::Renderers::BookLists::ByTitleAlphaRenderer.new(@context, data)
      output = renderer.render
      assert_equal '', output
    end
  end

  def test_renders_alpha_groups_with_full_navigation
    book_a = create_doc({ 'title' => 'A Book' })
    book_z = create_doc({ 'title' => 'Z Book' })

    data = {
      alpha_groups: [
        { letter: 'A', books: [book_a] },
        { letter: 'Z', books: [book_z] }
      ]
    }

    Jekyll::Books::Core::BookCardUtils.stub :render, ->(_book, _ctx) { '<!-- Book Card -->' } do
      renderer = Jekyll::Books::Lists::Renderers::BookLists::ByTitleAlphaRenderer.new(@context, data)
      output = renderer.render

      # Assert navigation exists with all A-Z letters plus #
      assert_match(/<nav class="alpha-jump-links">/, output)
      assert_match %r{<a href="#letter-a">A</a>}, output
      assert_match %r{<a href="#letter-z">Z</a>}, output
      # Letters without books should be spans, not links
      assert_match %r{<span>B</span>}, output
      assert_match %r{</nav>}, output

      # Assert letter headings exist with correct IDs
      assert_match %r{<h2 class="book-list-headline" id="letter-a">A</h2>}, output
      assert_match %r{<h2 class="book-list-headline" id="letter-z">Z</h2>}, output

      # Assert card grids exist
      assert_match(/<div class="card-grid">/, output)

      # Assert correct number of book cards
      assert_equal 2, output.scan('<!-- Book Card -->').count
    end
  end

  def test_handles_hash_symbol_for_non_alpha_books
    book = create_doc({ 'title' => '1984' })

    data = {
      alpha_groups: [
        { letter: '#', books: [book] }
      ]
    }

    Jekyll::Books::Core::BookCardUtils.stub :render, ->(_book, _ctx) { '<!-- Book Card -->' } do
      renderer = Jekyll::Books::Lists::Renderers::BookLists::ByTitleAlphaRenderer.new(@context, data)
      output = renderer.render

      # Assert # symbol uses "hash" as ID
      assert_match %r{<a href="#letter-hash">#</a>}, output
      assert_match %r{<h2 class="book-list-headline" id="letter-hash">#</h2>}, output
    end
  end

  def test_escapes_html_in_letter_values
    book = create_doc({ 'title' => 'Book' })
    data = {
      alpha_groups: [
        { letter: '<script>X</script>', books: [book] }
      ]
    }

    Jekyll::Books::Core::BookCardUtils.stub :render, ->(_book, _ctx) { '<!-- Book Card -->' } do
      renderer = Jekyll::Books::Lists::Renderers::BookLists::ByTitleAlphaRenderer.new(@context, data)
      output = renderer.render

      # Assert the letter is escaped
      refute_match %r{<script>X</script>}, output
      assert_match %r{&lt;script&gt;X&lt;/script&gt;}, output
    end
  end
end
