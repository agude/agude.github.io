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

    assert_equal "- [The Great Gatsby](/books/the-great-gatsby/) by F. Scott Fitzgerald --- \u2605\u2605\u2605\u2605\u2606",
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

    assert_equal "- [Collaborative Work](/books/collab/) by Author One, Author Two, Author Three --- \u2605\u2605\u2605\u2605\u2605",
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

    assert_equal "- [Anonymous](/books/anon/) --- \u2605\u2605\u2605\u2606\u2606", result
  end

  def test_render_book_card_md_no_rating
    data = {
      title: 'Unrated Book',
      authors: ['Author'],
      rating: nil,
      url: '/books/unrated/',
    }

    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_book_card_md(data)

    assert_equal '- [Unrated Book](/books/unrated/) by Author', result
  end

  def test_render_book_card_md_no_authors_no_rating
    data = {
      title: 'Minimal',
      authors: nil,
      rating: nil,
      url: '/books/minimal/',
    }

    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_book_card_md(data)

    assert_equal '- [Minimal](/books/minimal/)', result
  end

  def test_render_article_card_md
    data = {
      title: 'My Blog Post',
      url: '/blog/my-blog-post/',
    }

    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_article_card_md(data)

    assert_equal '- [My Blog Post](/blog/my-blog-post/)', result
  end
end
