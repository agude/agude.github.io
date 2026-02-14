# frozen_string_literal: true

require_relative '../../../../test_helper'

# Tests for Jekyll::Books::Lists::BookListRendererUtils
#
# Verifies that book groups are correctly rendered to HTML.
class TestBookListRendererUtils < Minitest::Test
  def setup
    @standalone = create_doc(
      { 'title' => 'Standalone Book', 'published' => true },
      '/books/standalone.html',
    )
    @series_book = create_doc(
      { 'title' => 'Series Book', 'published' => true, 'series' => 'Epic Series' },
      '/books/series.html',
    )
    @series_page = create_doc(
      { 'title' => 'Epic Series', 'layout' => 'series_page' },
      '/series/epic.html',
    )

    @site = create_site({}, { 'books' => [@standalone, @series_book] }, [@series_page])
    @context = create_context({}, { site: @site, page: @standalone })
  end

  def test_returns_empty_when_no_books
    data = { standalone_books: [], series_groups: [] }
    result = Jekyll::Books::Lists::BookListRendererUtils.render_book_groups_html(data, @context)

    assert_equal '', result
  end

  def test_renders_standalone_section
    data = { standalone_books: [@standalone], series_groups: [] }
    result = Jekyll::Books::Lists::BookListRendererUtils.render_book_groups_html(data, @context)

    assert_includes result, 'Standalone Books'
    assert_includes result, 'book-list-headline'
    assert_includes result, 'card-grid'
  end

  def test_renders_series_section
    series_group = { name: 'Epic Series', books: [@series_book] }
    data = { standalone_books: [], series_groups: [series_group] }
    result = Jekyll::Books::Lists::BookListRendererUtils.render_book_groups_html(data, @context)

    assert_includes result, 'series-title'
    assert_includes result, 'card-grid'
  end

  def test_uses_specified_heading_level
    series_group = { name: 'Epic Series', books: [@series_book] }
    data = { standalone_books: [], series_groups: [series_group] }
    result = Jekyll::Books::Lists::BookListRendererUtils.render_book_groups_html(
      data, @context, series_heading_level: 3,
    )

    assert_includes result, '<h3 class="series-title"'
  end

  def test_defaults_to_h2_for_invalid_heading_level
    series_group = { name: 'Epic Series', books: [@series_book] }
    data = { standalone_books: [], series_groups: [series_group] }
    result = Jekyll::Books::Lists::BookListRendererUtils.render_book_groups_html(
      data, @context, series_heading_level: 99,
    )

    assert_includes result, '<h2 class="series-title"'
  end

  def test_generates_alpha_nav_when_requested
    series_group = { name: 'Epic Series', books: [@series_book] }
    data = { standalone_books: [@standalone], series_groups: [series_group] }
    result = Jekyll::Books::Lists::BookListRendererUtils.render_book_groups_html(
      data, @context, generate_nav: true,
    )

    assert_includes result, '<nav class="alpha-jump-links">'
  end

  def test_alpha_nav_includes_links_for_existing_sections
    series_a = { name: 'Alpha Series', books: [@series_book] }
    series_z = { name: 'Zeta Series', books: [@series_book] }
    data = { standalone_books: [], series_groups: [series_a, series_z] }
    result = Jekyll::Books::Lists::BookListRendererUtils.render_book_groups_html(
      data, @context, generate_nav: true,
    )

    # Should have links for A and Z
    assert_includes result, '<a href="#alpha-series">A</a>'
    assert_includes result, '<a href="#zeta-series">Z</a>'
  end

  def test_alpha_nav_uses_spans_for_missing_letters
    series_m = { name: 'Middle Series', books: [@series_book] }
    data = { standalone_books: [], series_groups: [series_m] }
    result = Jekyll::Books::Lists::BookListRendererUtils.render_book_groups_html(
      data, @context, generate_nav: true,
    )

    # A should be a span (no content), M should be a link
    assert_includes result, '<span>A</span>'
    assert_includes result, '<a href="#middle-series">M</a>'
  end

  def test_includes_log_messages_in_output
    data = { standalone_books: [@standalone], series_groups: [], log_messages: '<!-- log -->' }
    result = Jekyll::Books::Lists::BookListRendererUtils.render_book_groups_html(data, @context)

    assert_includes result, '<!-- log -->'
  end

  def test_renders_both_standalone_and_series
    series_group = { name: 'Epic Series', books: [@series_book] }
    data = { standalone_books: [@standalone], series_groups: [series_group] }
    result = Jekyll::Books::Lists::BookListRendererUtils.render_book_groups_html(data, @context)

    assert_includes result, 'Standalone Books'
    assert_includes result, 'Epic Series'
  end

  def test_generates_slugs_for_ids
    series_group = { name: 'The Great Series', books: [@series_book] }
    data = { standalone_books: [], series_groups: [series_group] }
    result = Jekyll::Books::Lists::BookListRendererUtils.render_book_groups_html(data, @context)

    assert_includes result, 'id="the-great-series"'
  end

  def test_standalone_section_gets_hash_anchor
    data = { standalone_books: [@standalone], series_groups: [] }
    result = Jekyll::Books::Lists::BookListRendererUtils.render_book_groups_html(
      data, @context, generate_nav: true,
    )

    assert_includes result, 'id="standalone-books"'
    assert_includes result, '<a href="#standalone-books">#</a>'
  end

  def test_strips_articles_for_nav_sorting
    series_the = { name: 'The Amazing Series', books: [@series_book] }
    data = { standalone_books: [], series_groups: [series_the] }
    result = Jekyll::Books::Lists::BookListRendererUtils.render_book_groups_html(
      data, @context, generate_nav: true,
    )

    # "The Amazing Series" should register under A, not T
    assert_includes result, '<a href="#the-amazing-series">A</a>'
  end
end
