# _tests/plugins/test_link_cache_generator_favorites.rb
require_relative '../test_helper'

class TestLinkCacheGeneratorFavorites < Minitest::Test
  def setup
    # --- Mock Books (Targets of the links) ---
    @book_a = create_doc({ 'title' => 'Book A' }, '/books/a.html')
    @book_b = create_doc({ 'title' => 'Book B' }, '/books/b.html')
    @book_c = create_doc({ 'title' => 'Book C' }, '/books/c.html')

    # --- Mock Posts (Sources of the links) ---
    # A favorites post linking to two books
    @favorites_post_2023 = create_doc(
      { 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 },
      '/posts/fav23.html',
      '{% book_link "Book A" %} and {% book_card_lookup title="Book B" %}'
    )

    # Another favorites post linking to one existing and one non-existent book
    @favorites_post_2024 = create_doc(
      { 'title' => 'Favorites 2024', 'is_favorites_list' => 2024 },
      '/posts/fav24.html',
      '{% book_link "Book B" %} and {% book_link "Non-Existent Book" %}'
    )

    # A regular post that should be ignored
    @regular_post_with_link = create_doc(
      { 'title' => 'Regular Post' },
      '/posts/regular.html',
      '{% book_link "Book C" %}'
    )

    # The create_site helper runs the LinkCacheGenerator automatically
    @site = create_site(
      {},
      { 'books' => [@book_a, @book_b, @book_c] },
      [],
      [@favorites_post_2023, @favorites_post_2024, @regular_post_with_link]
    )
    @favorites_cache = @site.data['link_cache']['favorites_mentions']
    @favorites_posts_to_books_cache = @site.data['link_cache']['favorites_posts_to_books']
  end

  def test_favorites_mentions_cache_is_created
    refute_nil @favorites_cache, "The 'favorites_mentions' cache should exist"
  end

  def test_finds_mentions_from_favorites_post
    mentions_for_a = @favorites_cache[@book_a.url]
    refute_nil mentions_for_a, "Book A should be in the favorites cache"
    assert_instance_of Array, mentions_for_a
    assert_equal 1, mentions_for_a.size
    assert_equal @favorites_post_2023.url, mentions_for_a.first.url
  end

  def test_ignores_mentions_from_regular_posts
    assert_nil @favorites_cache[@book_c.url], "Book C, mentioned in a regular post, should not be in the cache"
  end

  def test_book_mentioned_in_multiple_lists_is_tracked_correctly
    mentions_for_b = @favorites_cache[@book_b.url]
    refute_nil mentions_for_b, "Book B should be in the favorites cache"
    assert_equal 2, mentions_for_b.size, "Book B should be mentioned by two posts"

    mentioning_post_urls = mentions_for_b.map(&:url).sort
    expected_urls = [@favorites_post_2023.url, @favorites_post_2024.url].sort
    assert_equal expected_urls, mentioning_post_urls
  end

  def test_ignores_links_to_non_existent_books
    # The cache should only contain keys for books that actually exist.
    # We expect keys for Book A and Book B.
    assert_equal 2, @favorites_cache.keys.size
    assert_includes @favorites_cache.keys, @book_a.url
    assert_includes @favorites_cache.keys, @book_b.url
  end

  def test_handles_no_favorites_posts_gracefully
    site_no_favs = create_site(
      {},
      { 'books' => [@book_a, @book_c] },
      [],
      [@regular_post_with_link] # Only a regular post
    )
    cache = site_no_favs.data['link_cache']['favorites_mentions']
    assert_empty cache, "Favorites cache should be empty if no posts are flagged"
  end

  def test_handles_favorites_post_with_no_links
    favorites_post_no_links = create_doc(
      { 'title' => 'Favorites No Links', 'is_favorites_list' => 2025 },
      '/posts/fav25.html',
      'This post has no book links.'
    )
    site_with_empty_fav = create_site(
      {},
      { 'books' => [@book_a] },
      [],
      [favorites_post_no_links, @favorites_post_2023]
    )
    cache = site_with_empty_fav.data['link_cache']['favorites_mentions']
    # The cache should still contain Book A from the 2023 post, but nothing new.
    assert_equal 1, cache.keys.size
    assert_includes cache.keys, @book_a.url
  end

  def test_book_mentioned_multiple_times_in_one_post_is_added_once
    favorites_post_multi_mention = create_doc(
      { 'title' => 'Favorites Multi-Mention', 'is_favorites_list' => 2026 },
      '/posts/fav26.html',
      '{% book_link "Book A" %} and again {% book_link "Book A" %}'
    )
    site_with_multi_mention = create_site(
      {},
      { 'books' => [@book_a] },
      [],
      [favorites_post_multi_mention]
    )
    cache = site_with_multi_mention.data['link_cache']['favorites_mentions']
    mentions_for_a = cache[@book_a.url]
    refute_nil mentions_for_a
    assert_equal 1, mentions_for_a.size, "Book A should only be listed once for the post that mentions it multiple times"
    assert_equal favorites_post_multi_mention.url, mentions_for_a.first.url
  end

  def test_inverted_favorites_cache_is_created_correctly
    refute_nil @favorites_posts_to_books_cache, "The 'favorites_posts_to_books' cache should exist"
    assert_equal 2, @favorites_posts_to_books_cache.keys.size, "Should have entries for two favorites posts"

    # Check 2023 post
    books_for_2023 = @favorites_posts_to_books_cache[@favorites_post_2023.url]
    refute_nil books_for_2023
    assert_equal 2, books_for_2023.size
    book_urls_2023 = books_for_2023.map(&:url).sort
    assert_equal [@book_a.url, @book_b.url].sort, book_urls_2023

    # Check 2024 post
    books_for_2024 = @favorites_posts_to_books_cache[@favorites_post_2024.url]
    refute_nil books_for_2024
    assert_equal 1, books_for_2024.size # Mentions one valid book
    assert_equal @book_b.url, books_for_2024.first.url

    # Check that regular post is not a key
    refute @favorites_posts_to_books_cache.key?(@regular_post_with_link.url)
  end
end
