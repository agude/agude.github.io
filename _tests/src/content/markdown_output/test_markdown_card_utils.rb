# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/markdown_output/markdown_card_utils'

# Tests for Jekyll::MarkdownOutput::MarkdownCardUtils.
#
# Verifies that card data hashes are correctly formatted as Markdown list items.
class TestMarkdownCardUtils < Minitest::Test
  def test_render_book_card_md_full_data
    data = {
      title: 'The Great Gatsby',
      authors: ['F. Scott Fitzgerald'],
      rating: 4,
      url: '/books/the-great-gatsby/',
    }

    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_book_card_md(data)

    assert_equal "- [_The Great Gatsby_](/books/the-great-gatsby/) by F. Scott Fitzgerald --- \u2605\u2605\u2605\u2605\u2606",
                 result
  end

  def test_render_book_card_md_multiple_authors
    data = {
      title: 'Collaborative Work',
      authors: ['Author One', 'Author Two', 'Author Three'],
      rating: 5,
      url: '/books/collab/',
    }

    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_book_card_md(data)

    assert_equal "- [_Collaborative Work_](/books/collab/) by Author One, Author Two, Author Three --- \u2605\u2605\u2605\u2605\u2605",
                 result
  end

  def test_render_book_card_md_no_authors
    data = {
      title: 'Anonymous',
      authors: [],
      rating: 3,
      url: '/books/anon/',
    }

    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_book_card_md(data)

    assert_equal "- [_Anonymous_](/books/anon/) --- \u2605\u2605\u2605\u2606\u2606", result
  end

  def test_render_book_card_md_no_rating
    data = {
      title: 'Unrated Book',
      authors: ['Author'],
      rating: nil,
      url: '/books/unrated/',
    }

    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_book_card_md(data)

    assert_equal '- [_Unrated Book_](/books/unrated/) by Author', result
  end

  def test_render_book_card_md_no_authors_no_rating
    data = {
      title: 'Minimal',
      authors: nil,
      rating: nil,
      url: '/books/minimal/',
    }

    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_book_card_md(data)

    assert_equal '- [_Minimal_](/books/minimal/)', result
  end

  def test_render_book_card_md_author_linked
    data = {
      title: 'Dune',
      authors: ['Frank Herbert'],
      author_urls: { 'Frank Herbert' => '/books/authors/frank_herbert/' },
      rating: 5,
      url: '/books/dune/',
    }

    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_book_card_md(data)

    assert_equal "- [_Dune_](/books/dune/) by [Frank Herbert](/books/authors/frank_herbert/) --- \u2605\u2605\u2605\u2605\u2605",
                 result
  end

  def test_render_book_card_md_mixed_author_links
    data = {
      title: 'Collab',
      authors: ['Linked Author', 'Unlinked Author'],
      author_urls: { 'Linked Author' => '/books/authors/linked/' },
      rating: 4,
      url: '/books/collab/',
    }

    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_book_card_md(data)

    assert_equal "- [_Collab_](/books/collab/) by [Linked Author](/books/authors/linked/), Unlinked Author --- \u2605\u2605\u2605\u2605\u2606",
                 result
  end

  def test_render_article_card_md
    data = {
      title: 'My Blog Post',
      url: '/blog/my-blog-post/',
    }

    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_article_card_md(data)

    assert_equal '- [My Blog Post](/blog/my-blog-post/)', result
  end

  # --- book_doc_to_card_data ---

  def test_book_doc_to_card_data_basic
    doc = create_doc(
      { 'title' => 'Dune', 'book_authors' => ['Frank Herbert'], 'rating' => 5 },
      '/books/dune/',
    )
    card = Jekyll::MarkdownOutput::MarkdownCardUtils.book_doc_to_card_data(doc)
    assert_equal 'Dune', card[:title]
    assert_equal '/books/dune/', card[:url]
    assert_equal ['Frank Herbert'], card[:authors]
    assert_equal({}, card[:author_urls])
    assert_equal 5, card[:rating]
  end

  def test_book_doc_to_card_data_with_author_urls
    doc = create_doc(
      { 'title' => 'Dune', 'book_authors' => ['Frank Herbert'], 'rating' => 5 },
      '/books/dune/',
    )
    urls = { 'Frank Herbert' => '/books/authors/frank_herbert/' }
    card = Jekyll::MarkdownOutput::MarkdownCardUtils.book_doc_to_card_data(doc, author_urls: urls)
    assert_equal urls, card[:author_urls]
  end

  def test_book_doc_to_card_data_string_authors
    doc = create_doc(
      { 'title' => 'Solo', 'book_authors' => 'Single Author', 'rating' => 3 },
      '/books/solo/',
    )
    card = Jekyll::MarkdownOutput::MarkdownCardUtils.book_doc_to_card_data(doc)
    assert_equal ['Single Author'], card[:authors]
  end

  def test_book_doc_to_card_data_nil_authors
    doc = create_doc(
      { 'title' => 'Anon', 'book_authors' => nil, 'rating' => 4 },
      '/books/anon/',
    )
    card = Jekyll::MarkdownOutput::MarkdownCardUtils.book_doc_to_card_data(doc)
    assert_equal [], card[:authors]
  end

  # --- format_stars ---

  def test_format_stars_full
    assert_equal "\u2605\u2605\u2605\u2605\u2605",
                 Jekyll::MarkdownOutput::MarkdownCardUtils.format_stars(5)
  end

  def test_format_stars_partial
    assert_equal "\u2605\u2605\u2605\u2606\u2606",
                 Jekyll::MarkdownOutput::MarkdownCardUtils.format_stars(3)
  end

  def test_format_stars_one
    assert_equal "\u2605\u2606\u2606\u2606\u2606",
                 Jekyll::MarkdownOutput::MarkdownCardUtils.format_stars(1)
  end

  def test_format_stars_zero_returns_nil
    assert_nil Jekyll::MarkdownOutput::MarkdownCardUtils.format_stars(0)
  end

  def test_format_stars_six_returns_nil
    assert_nil Jekyll::MarkdownOutput::MarkdownCardUtils.format_stars(6)
  end

  def test_format_stars_string_coercion
    assert_equal "\u2605\u2605\u2605\u2605\u2606",
                 Jekyll::MarkdownOutput::MarkdownCardUtils.format_stars('4')
  end
end
