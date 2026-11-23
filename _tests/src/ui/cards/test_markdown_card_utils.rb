# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/cards/markdown_card_utils'

# Markdown card data, rendered list items, and rating validation.
class TestMarkdownCardUtils < Minitest::Test
  Cards = Jekyll::UI::Cards::MarkdownCardUtils

  def test_book_doc_to_card_data_basic
    book = create_doc(
      {
        'title' => 'Part<br/>Two',
        'book_authors' => %w[A B],
        'rating' => 5,
        'description' => 'Ignored for books.',
        'excerpt' => '<p>A review of <cite>Part Two</cite>.</p>',
      },
      '/books/part-two/',
    )
    urls = { 'A' => '/books/authors/a/' }

    assert_equal(
      {
        title: 'Part<br/>Two',
        url: '/books/part-two/',
        authors: %w[A B],
        author_urls: urls,
        rating: 5,
        description: 'A review of Part Two.',
      },
      Cards.book_doc_to_card_data(book, author_urls: urls),
    )
    assert_empty Cards.book_doc_to_card_data(book)[:author_urls]
  end

  def test_render_book_card_md_mixed_author_links
    book = create_doc(
      {
        'title' => 'Part<br/>Two [Anthology] (Revised)',
        'book_authors' => ['A [Editor]', 'B', 'C'],
        'rating' => '4',
        'excerpt' => "<p>A <strong>collaborative</strong>\n   work.</p>",
      },
      '/books/part-two(v2)/',
    )
    card = Cards.book_doc_to_card_data(book, author_urls: { 'A [Editor]' => '/authors/a(editor)/' })
    expected = '- [_Part Two \[Anthology\] (Revised)_](/books/part-two\(v2\)/) ' \
               'by [A \[Editor\]](/authors/a\(editor\)/), B, C --- ★★★★☆: A collaborative work.'

    assert_equal expected, Cards.render_card_md(card, book: true)
  end

  def test_render_book_card_md_no_authors_no_rating
    book = create_doc({ 'title' => 'Minimal', 'book_authors' => nil, 'rating' => nil, 'excerpt' => nil }, '/books/minimal/')
    card = Cards.book_doc_to_card_data(book)

    assert_empty card[:authors]
    assert_nil card[:description]
    assert_equal '- [_Minimal_](/books/minimal/)', Cards.render_card_md(card, book: true)
  end

  def test_render_book_card_md_no_authors
    assert_equal '- [_Anonymous_](/books/anon/) --- ★☆☆☆☆',
                 Cards.render_card_md({ title: 'Anonymous', url: '/books/anon/', authors: [], rating: 1 }, book: true)
  end

  def test_render_book_card_md_no_rating
    book = create_doc({ 'title' => 'Unrated Book', 'book_authors' => 'Author', 'excerpt' => '' }, '/books/unrated/')
    card = Cards.book_doc_to_card_data(book)

    assert_equal ['Author'], card[:authors]
    assert_equal '- [_Unrated Book_](/books/unrated/) by Author', Cards.render_card_md(card, book: true)
  end

  def test_render_article_card_md_without_description
    card = { title: 'Post [Update]', url: '/blog/post/' }

    assert_equal '- [Post \[Update\]](/blog/post/)', Cards.render_card_md(card)
  end

  def test_extract_plain_description_from_html_excerpt
    data = { 'description' => '  ', 'excerpt' => "<p>HTML <strong>excerpt</strong>\n   text</p>" }
    assert_equal 'HTML excerpt text', Cards.extract_plain_description(data)
  end

  def test_extract_plain_description_nil_when_empty
    [nil, '', '   ', '<p></p>'].each do |blank|
      assert_nil Cards.extract_plain_description({ 'excerpt' => blank })
    end
  end

  def test_render_book_groups_md_standalone_and_series
    standalone = create_doc({ 'title' => 'Solo', 'rating' => 3 }, '/books/solo/')
    entry = create_doc({ 'title' => 'Book 1', 'rating' => 5 }, '/books/b1/')
    data = { standalone_books: [standalone], series_groups: [{ name: 'Epic Series', books: [entry] }] }

    assert_equal(
      ['## Standalone', '- [_Solo_](/books/solo/) --- ★★★☆☆', '## Epic Series', '- [_Book 1_](/books/b1/) --- ★★★★★'],
      Cards.render_book_groups_md(data, heading_level: 2),
    )
  end

  def test_render_book_groups_md_empty_data
    assert_empty Cards.render_book_groups_md({}, heading_level: 3)
  end

  def test_render_book_groups_md_only_series
    entry = create_doc({ 'title' => 'Entry' }, '/books/e/')
    data = { standalone_books: [], series_groups: [{ name: 'Trilogy', books: [entry] }] }

    assert_equal ['### Trilogy', '- [_Entry_](/books/e/)'], Cards.render_book_groups_md(data, heading_level: 3)
  end

  def test_format_stars_out_of_range_raises
    [0, 6].each do |raw|
      assert_raises(Jekyll::Errors::FatalException, raw.inspect) { Cards.format_stars(raw) }
    end
  end

  def test_format_stars_rejects_text_after_the_number
    assert_raises(Jekyll::Errors::FatalException) { Cards.format_stars('4 stars') }
  end

  def test_format_stars_rejects_fractions_and_blank
    ['4.9', '', 4.9].each do |raw|
      assert_raises(Jekyll::Errors::FatalException, raw.inspect) { Cards.format_stars(raw) }
    end
  end
end
