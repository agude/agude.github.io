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

  def test_render_book_card_md_escapes_brackets_in_title
    data = {
      title: 'We Are Legion (We Are Bob)',
      authors: ['Dennis E. Taylor'],
      rating: 4,
      url: '/books/we_are_legion_we_are_bob/',
    }
    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_book_card_md(data)
    # Parentheses in text don't need escaping, but brackets would
    assert_includes result, '[_We Are Legion (We Are Bob)_]'
  end

  def test_render_book_card_md_escapes_bracket_in_title
    data = {
      title: 'Anthology [Vol. 2]',
      authors: ['Editor'],
      rating: 3,
      url: '/books/anthology-vol-2/',
    }
    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_book_card_md(data)
    assert_includes result, 'Anthology \[Vol. 2\]'
  end

  def test_render_article_card_md_escapes_bracket_in_title
    data = { title: 'Post [Update]', url: '/blog/post/' }
    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_article_card_md(data)
    assert_equal '- [Post \[Update\]](/blog/post/)', result
  end

  # --- description in cards ---

  def test_render_book_card_md_with_description
    data = {
      title: 'Dune',
      authors: ['Frank Herbert'],
      rating: 5,
      url: '/books/dune/',
      description: 'A desert planet epic',
    }
    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_book_card_md(data)
    assert_includes result, ': A desert planet epic'
    assert_match(/\u2605{5}: A desert/, result)
  end

  def test_render_book_card_md_without_description
    data = {
      title: 'Dune',
      authors: ['Frank Herbert'],
      rating: 5,
      url: '/books/dune/',
    }
    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_book_card_md(data)
    refute_includes result, ':'
  end

  def test_render_article_card_md_with_description
    data = { title: 'My Post', url: '/blog/post/', description: 'A great article' }
    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_article_card_md(data)
    assert_equal '- [My Post](/blog/post/): A great article', result
  end

  def test_render_article_card_md_without_description
    data = { title: 'My Post', url: '/blog/post/' }
    result = Jekyll::MarkdownOutput::MarkdownCardUtils.render_article_card_md(data)
    assert_equal '- [My Post](/blog/post/)', result
  end

  # --- extract_plain_description ---

  def test_extract_plain_description_from_description_field
    data = { 'description' => 'A plain text description' }
    result = Jekyll::MarkdownOutput::MarkdownCardUtils.extract_plain_description(data)
    assert_equal 'A plain text description', result
  end

  def test_extract_plain_description_from_html_excerpt
    data = { 'excerpt' => '<p>HTML <strong>excerpt</strong> text</p>' }
    result = Jekyll::MarkdownOutput::MarkdownCardUtils.extract_plain_description(data)
    assert_equal 'HTML excerpt text', result
  end

  def test_extract_plain_description_nil_when_empty
    data = {}
    result = Jekyll::MarkdownOutput::MarkdownCardUtils.extract_plain_description(data)
    assert_nil result
  end

  def test_extract_plain_description_collapses_whitespace
    data = { 'description' => "Line one.\nLine two.\n  Extra   spaces." }
    result = Jekyll::MarkdownOutput::MarkdownCardUtils.extract_plain_description(data)
    assert_equal 'Line one. Line two. Extra spaces.', result
  end

  def test_extract_plain_description_book_type_uses_excerpt
    data = { 'description' => 'Ignored for books', 'excerpt' => '<p>Book excerpt</p>' }
    result = Jekyll::MarkdownOutput::MarkdownCardUtils.extract_plain_description(data, type: :book)
    assert_equal 'Book excerpt', result
  end

  def test_book_doc_to_card_data_includes_description
    doc = create_doc(
      {
        'title' => 'Dune',
        'book_authors' => ['Frank Herbert'],
        'rating' => 5,
        'excerpt' => '<p>A review of Dune</p>',
      },
      '/books/dune/',
    )
    card = Jekyll::MarkdownOutput::MarkdownCardUtils.book_doc_to_card_data(doc)
    assert_equal 'A review of Dune', card[:description]
  end
end
