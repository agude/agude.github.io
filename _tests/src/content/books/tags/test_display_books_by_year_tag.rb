# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/tags/display_books_by_year_tag'

# Tests for Jekyll::Books::Tags::DisplayBooksByYearTag Liquid tag.
#
# Verifies the tag's Liquid syntax and rendered output.
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

  # --- Markdown mode ---

  def test_markdown_mode_renders_year_headings_and_book_links
    books = [
      create_doc({ 'title' => 'Old Book', 'book_authors' => ['Auth'], 'rating' => 4, 'date' => Time.utc(2022, 1, 1) }, '/books/old.html'),
      create_doc({ 'title' => 'New Book', 'book_authors' => ['Auth'], 'rating' => 5, 'date' => Time.utc(2024, 1, 1) }, '/books/new.html'),
    ]
    site = create_site({}, { 'books' => books })
    md_context = create_context(
      {},
      { site: site, page: create_doc({}, '/test.html'), render_mode: :markdown },
    )
    output = Liquid::Template.parse('{% display_books_by_year %}').render!(md_context)
    assert_includes output, '## 2024'
    assert_includes output, '[_New Book_](/books/new.html)'
    assert_includes output, '## 2022'
    assert_includes output, '[_Old Book_](/books/old.html)'
    assert_operator output.index('## 2024'), :<, output.index('## 2022')
    refute_match(/<div/, output)
  end

  def test_html_mode_renders_book_groups
    book = create_doc({ 'title' => 'Year Book', 'book_authors' => ['Auth'], 'date' => Time.utc(2024, 1, 1) }, '/books/year.html')
    site = create_site({}, { 'books' => [book] })
    context = create_context({}, { site: site })

    output = Liquid::Template.parse('{% display_books_by_year %}').render!(context)

    assert_includes output, '2024'
    assert_includes output, 'Year Book'
  end
end
