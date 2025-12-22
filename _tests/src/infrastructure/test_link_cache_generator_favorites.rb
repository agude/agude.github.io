# frozen_string_literal: true

require_relative '../../test_helper'

# Tests for Jekyll::Infrastructure::LinkCacheGenerator favorites tracking functionality.
#
# Verifies that the generator correctly tracks book mentions in favorites posts,
# matching books by both title and date.
class TestLinkCacheGeneratorFavorites < Minitest::Test
  # Case 1: 1 book, 0 posts - Book exists but isn't in any favorites
  def test_book_with_no_favorites_reference_has_no_badge
    book = create_doc(
      { 'title' => 'Lonely Book', 'date' => Time.parse('2023-06-15') },
      '/books/lonely.html'
    )
    regular_post = create_doc(
      { 'title' => 'Regular Post' },
      '/posts/regular.html',
      'No book cards here.'
    )

    site = create_site({}, { 'books' => [book] }, [], [regular_post])
    cache = site.data['link_cache']['favorites_mentions']

    assert_empty cache, 'Book with no favorites reference should have no badge'
  end

  # Case 2: 1 book, 1 post - Basic matching
  def test_single_book_single_post_gets_badge
    book = create_doc(
      { 'title' => 'Great Book', 'date' => Time.parse('2023-06-15') },
      '/books/great.html'
    )
    favorites_post = create_doc(
      { 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 },
      '/posts/fav23.html',
      '{% book_card_lookup title="Great Book" date="2023-06-15" %}'
    )

    site = create_site({}, { 'books' => [book] }, [], [favorites_post])
    cache = site.data['link_cache']['favorites_mentions']

    refute_nil cache[book.url], 'Book should have badge'
    assert_equal 1, cache[book.url].size
    assert_equal favorites_post.url, cache[book.url].first.url
  end

  # Case 3: 1 book, 2 posts - Same review referenced by multiple favorites
  def test_single_book_multiple_posts_gets_multiple_badges
    book = create_doc(
      { 'title' => 'Classic Book', 'date' => Time.parse('2023-06-15') },
      '/books/classic.html'
    )
    favorites_2023 = create_doc(
      { 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 },
      '/posts/fav23.html',
      '{% book_card_lookup title="Classic Book" date="2023-06-15" %}'
    )
    favorites_2024 = create_doc(
      { 'title' => 'Favorites 2024', 'is_favorites_list' => 2024 },
      '/posts/fav24.html',
      '{% book_card_lookup title="Classic Book" date="2023-06-15" %}'
    )

    site = create_site({}, { 'books' => [book] }, [], [favorites_2023, favorites_2024])
    cache = site.data['link_cache']['favorites_mentions']

    refute_nil cache[book.url], 'Book should have badges'
    assert_equal 2, cache[book.url].size, 'Book should have badges from both posts'

    post_urls = cache[book.url].map(&:url).sort
    assert_equal [favorites_2023.url, favorites_2024.url].sort, post_urls
  end

  # Case 4: 2 books (same title), 1 post - Date matching selects correct review
  def test_two_reviews_one_post_badges_matching_review_only
    old_review = create_doc(
      { 'title' => 'Hyperion', 'date' => Time.parse('2023-10-27') },
      '/books/hyperion-2023.html'
    )
    new_review = create_doc(
      { 'title' => 'Hyperion', 'date' => Time.parse('2025-12-20') },
      '/books/hyperion-2025.html'
    )
    favorites_post = create_doc(
      { 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 },
      '/posts/fav23.html',
      '{% book_card_lookup title="Hyperion" date="2023-10-27" %}'
    )

    site = create_site({}, { 'books' => [old_review, new_review] }, [], [favorites_post])
    cache = site.data['link_cache']['favorites_mentions']

    # Old review should have badge
    refute_nil cache[old_review.url], 'Old review should have badge'
    assert_equal 1, cache[old_review.url].size

    # New review should NOT have badge
    assert_nil cache[new_review.url], 'New review should not have badge'
  end

  # Case 5: 2 books (same title), 2 posts - Each post badges its respective review
  def test_two_reviews_two_posts_each_badges_its_review
    old_review = create_doc(
      { 'title' => 'Hyperion', 'date' => Time.parse('2023-10-27') },
      '/books/hyperion-2023.html'
    )
    new_review = create_doc(
      { 'title' => 'Hyperion', 'date' => Time.parse('2025-12-20') },
      '/books/hyperion-2025.html'
    )
    favorites_2023 = create_doc(
      { 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 },
      '/posts/fav23.html',
      '{% book_card_lookup title="Hyperion" date="2023-10-27" %}'
    )
    favorites_2025 = create_doc(
      { 'title' => 'Favorites 2025', 'is_favorites_list' => 2025 },
      '/posts/fav25.html',
      '{% book_card_lookup title="Hyperion" date="2025-12-20" %}'
    )

    site = create_site(
      {},
      { 'books' => [old_review, new_review] },
      [],
      [favorites_2023, favorites_2025]
    )
    cache = site.data['link_cache']['favorites_mentions']

    # Old review badged by 2023 favorites
    refute_nil cache[old_review.url]
    assert_equal 1, cache[old_review.url].size
    assert_equal favorites_2023.url, cache[old_review.url].first.url

    # New review badged by 2025 favorites
    refute_nil cache[new_review.url]
    assert_equal 1, cache[new_review.url].size
    assert_equal favorites_2025.url, cache[new_review.url].first.url
  end

  # Case 6: Same book referenced twice in one post - No duplicate badges
  def test_same_book_twice_in_one_post_no_duplicate
    book = create_doc(
      { 'title' => 'Great Book', 'date' => Time.parse('2023-06-15') },
      '/books/great.html'
    )
    favorites_post = create_doc(
      { 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 },
      '/posts/fav23.html',
      '{% book_card_lookup title="Great Book" date="2023-06-15" %} and again ' \
      '{% book_card_lookup title="Great Book" date="2023-06-15" %}'
    )

    site = create_site({}, { 'books' => [book] }, [], [favorites_post])
    cache = site.data['link_cache']['favorites_mentions']

    refute_nil cache[book.url]
    assert_equal 1, cache[book.url].size, 'Should only have one badge entry despite two references'
  end

  # Case 7: Date doesn't match any review - Build fails
  def test_date_mismatch_raises_error
    book = create_doc(
      { 'title' => 'Some Book', 'date' => Time.parse('2023-06-15') },
      '/books/some.html'
    )
    favorites_post = create_doc(
      { 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 },
      '/posts/fav23.html',
      '{% book_card_lookup title="Some Book" date="2099-01-01" %}'
    )

    error = assert_raises(RuntimeError) do
      create_site({}, { 'books' => [book] }, [], [favorites_post])
    end

    assert_includes error.message, 'No matching review'
    assert_includes error.message, 'Some Book'
    assert_includes error.message, '2099-01-01'
  end

  # Case 8: Non-existent book title - Ignored gracefully
  def test_nonexistent_book_ignored
    book = create_doc(
      { 'title' => 'Real Book', 'date' => Time.parse('2023-06-15') },
      '/books/real.html'
    )
    favorites_post = create_doc(
      { 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 },
      '/posts/fav23.html',
      '{% book_card_lookup title="Fake Book" date="2023-01-01" %}'
    )

    # Should not raise - non-existent books are ignored
    site = create_site({}, { 'books' => [book] }, [], [favorites_post])
    cache = site.data['link_cache']['favorites_mentions']

    assert_empty cache, 'Cache should be empty since referenced book does not exist'
  end

  # --- Additional tests for inverted cache (favorites_posts_to_books) ---

  def test_posts_to_books_cache_created_correctly
    book_a = create_doc(
      { 'title' => 'Book A', 'date' => Time.parse('2023-01-01') },
      '/books/a.html'
    )
    book_b = create_doc(
      { 'title' => 'Book B', 'date' => Time.parse('2023-02-01') },
      '/books/b.html'
    )
    favorites_post = create_doc(
      { 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 },
      '/posts/fav23.html',
      '{% book_card_lookup title="Book A" date="2023-01-01" %} and ' \
      '{% book_card_lookup title="Book B" date="2023-02-01" %}'
    )

    site = create_site({}, { 'books' => [book_a, book_b] }, [], [favorites_post])
    posts_to_books = site.data['link_cache']['favorites_posts_to_books']

    refute_nil posts_to_books[favorites_post.url]
    assert_equal 2, posts_to_books[favorites_post.url].size

    book_urls = posts_to_books[favorites_post.url].map(&:url).sort
    assert_equal [book_a.url, book_b.url].sort, book_urls
  end

  def test_regular_post_not_in_posts_to_books_cache
    book = create_doc(
      { 'title' => 'Book', 'date' => Time.parse('2023-01-01') },
      '/books/book.html'
    )
    regular_post = create_doc(
      { 'title' => 'Regular Post' },
      '/posts/regular.html',
      '{% book_card_lookup title="Book" %}'
    )

    site = create_site({}, { 'books' => [book] }, [], [regular_post])
    posts_to_books = site.data['link_cache']['favorites_posts_to_books']

    refute posts_to_books.key?(regular_post.url), 'Regular post should not be in cache'
  end
end
