# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::Infrastructure::LinkCache::FavoritesManager
#
# Verifies that favorites list posts are scanned for book_card_lookup tags
# and the correct mappings are built.
class TestFavoritesManager < Minitest::Test
  def setup
    @book = create_doc(
      { 'title' => 'Test Book', 'published' => true, 'date' => Time.parse('2024-01-15') },
      '/books/test-book.html'
    )
  end

  def test_builds_favorites_mentions_from_post
    favorites_post = create_favorites_post(
      '2024',
      "{% book_card_lookup title='Test Book' date='2024-01-15' %}"
    )

    site = create_site_with_favorites([@book], [favorites_post])
    mentions = site.data['link_cache']['favorites_mentions']

    assert_equal 1, mentions['/books/test-book.html'].length
    assert_equal favorites_post.url, mentions['/books/test-book.html'].first.url
  end

  def test_builds_posts_to_books_mapping
    favorites_post = create_favorites_post(
      '2024',
      "{% book_card_lookup title='Test Book' date='2024-01-15' %}"
    )

    site = create_site_with_favorites([@book], [favorites_post])
    posts_to_books = site.data['link_cache']['favorites_posts_to_books']

    refute_nil posts_to_books[favorites_post.url]
    assert_equal 1, posts_to_books[favorites_post.url].length
  end

  def test_handles_multiple_books_in_one_post
    book_a = create_doc(
      { 'title' => 'Book A', 'published' => true, 'date' => Time.parse('2024-01-10') },
      '/books/a.html'
    )
    book_b = create_doc(
      { 'title' => 'Book B', 'published' => true, 'date' => Time.parse('2024-02-20') },
      '/books/b.html'
    )

    favorites_post = create_favorites_post(
      '2024',
      "{% book_card_lookup title='Book A' date='2024-01-10' %}\n" \
      "{% book_card_lookup title='Book B' date='2024-02-20' %}"
    )

    site = create_site_with_favorites([book_a, book_b], [favorites_post])
    mentions = site.data['link_cache']['favorites_mentions']

    assert_equal 1, mentions['/books/a.html'].length
    assert_equal 1, mentions['/books/b.html'].length
  end

  def test_handles_same_book_in_multiple_posts
    post_2023 = create_favorites_post(
      '2023',
      "{% book_card_lookup title='Test Book' date='2024-01-15' %}"
    )
    post_2024 = create_favorites_post(
      '2024',
      "{% book_card_lookup title='Test Book' date='2024-01-15' %}"
    )

    site = create_site_with_favorites([@book], [post_2023, post_2024])
    mentions = site.data['link_cache']['favorites_mentions']

    assert_equal 2, mentions['/books/test-book.html'].length
  end

  def test_ignores_posts_without_favorites_flag
    regular_post = create_doc(
      { 'title' => 'Regular Post', 'date' => Time.parse('2024-03-01') },
      '/posts/regular.html',
      "{% book_card_lookup title='Test Book' date='2024-01-15' %}"
    )

    site = create_site_with_favorites([@book], [], [regular_post])
    mentions = site.data['link_cache']['favorites_mentions']

    assert_empty mentions
  end

  def test_handles_double_quoted_titles
    favorites_post = create_favorites_post(
      '2024',
      '{% book_card_lookup title="Test Book" date="2024-01-15" %}'
    )

    site = create_site_with_favorites([@book], [favorites_post])
    mentions = site.data['link_cache']['favorites_mentions']

    assert_equal 1, mentions['/books/test-book.html'].length
  end

  def test_deduplicates_mentions_for_same_book_in_same_post
    favorites_post = create_favorites_post(
      '2024',
      "{% book_card_lookup title='Test Book' date='2024-01-15' %}\n" \
      "{% book_card_lookup title='Test Book' date='2024-01-15' %}"
    )

    site = create_site_with_favorites([@book], [favorites_post])
    mentions = site.data['link_cache']['favorites_mentions']

    # Should only have one mention despite two tags
    assert_equal 1, mentions['/books/test-book.html'].length
  end

  def test_skips_when_no_posts
    site = create_site({}, { 'books' => [@book] }, [], [])
    mentions = site.data['link_cache']['favorites_mentions']

    assert_empty mentions
  end

  def test_skips_when_no_books
    favorites_post = create_favorites_post(
      '2024',
      "{% book_card_lookup title='Missing Book' date='2024-01-15' %}"
    )

    site = create_site_with_favorites([], [favorites_post])
    mentions = site.data['link_cache']['favorites_mentions']

    assert_empty mentions
  end

  private

  def create_favorites_post(year, content)
    create_doc(
      { 'title' => "Favorites #{year}", 'is_favorites_list' => true, 'date' => Time.parse("#{year}-12-31") },
      "/#{year}/favorites.html",
      content
    )
  end

  def create_site_with_favorites(books, favorites_posts, regular_posts = [])
    all_posts = favorites_posts + regular_posts
    create_site({}, { 'books' => books }, [], all_posts)
  end
end
