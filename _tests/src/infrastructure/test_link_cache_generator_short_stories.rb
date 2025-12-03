# frozen_string_literal: true

# _tests/plugins/test_link_cache_generator_short_stories.rb
require_relative '../../test_helper'
# LinkCacheGenerator is loaded by test_helper

# Tests for LinkCacheGenerator short story caching functionality.
#
# Verifies that the generator correctly extracts and caches short stories from anthology books.
class TestLinkCacheGeneratorShortStories < Minitest::Test
  def setup
    # --- Mock Books for Short Story Cache Testing ---

    # Use a non-interpolated heredoc (<<~'MARKDOWN') to define content safely.
    anthology1_content = <<~MARKDOWN
      Here is a review.
      ### {% short_story_title "Story Alpha" %}
      Content for Alpha.
      ### {% short_story_title "A & B's Story" %}
      Content for A&B.
      ### {% short_story_title "Duplicate Story" %}
      Content for the first duplicate.
    MARKDOWN

    anthology2_content = <<~MARKDOWN
      ### {% short_story_title "Story Gamma" %}
      Content for Gamma.
      ### {% short_story_title "Duplicate Story" %}
      Content for the second duplicate.
    MARKDOWN

    # An anthology with the flag and several stories
    @anthology1 = create_doc(
      {
        'title' => 'First Collection',
        'is_anthology' => true,
        'published' => true
      },
      '/books/first-collection.html',
      anthology1_content
    )

    # A second anthology with a duplicate story title
    @anthology2 = create_doc(
      {
        'title' => 'Second Collection',
        'is_anthology' => true,
        'published' => true
      },
      '/books/second-collection.html',
      anthology2_content
    )

    # A book with story tags but WITHOUT the is_anthology flag
    @book_no_flag = create_doc(
      {
        'title' => 'Book Without Flag',
        'published' => true
        # 'is_anthology' is missing
      },
      '/books/book-no-flag.html',
      '### {% short_story_title "Ignored Story" %}'
    )

    # An anthology with a story tag using the `no_id` flag
    @anthology_no_id = create_doc(
      {
        'title' => 'No ID Collection',
        'is_anthology' => true,
        'published' => true
      },
      '/books/no-id-collection.html',
      '### {% short_story_title "Story With No ID" no_id %}'
    )

    # An unpublished anthology that should be ignored
    @anthology_unpublished = create_doc(
      {
        'title' => 'Unpublished Collection',
        'is_anthology' => true,
        'published' => false
      },
      '/books/unpublished-collection.html',
      '### {% short_story_title "Unpublished Story" %}'
    )

    # The create_site helper automatically runs the LinkCacheGenerator,
    # so the cache will be populated and ready for assertions.
    @site = create_site(
      {}, # config
      { 'books' => [
        @anthology1, @anthology2, @book_no_flag,
        @anthology_no_id, @anthology_unpublished
      ] }, # collections
      [] # pages
    )
    @cache = @site.data['link_cache']
  end

  def test_short_story_cache_is_created
    refute_nil @cache, 'Link cache should exist'
    assert @cache.key?('short_stories'), 'short_stories key should be in the cache'
  end

  def test_finds_and_caches_stories_from_flagged_anthology
    story_alpha_cache = @cache['short_stories']['story alpha']
    refute_nil story_alpha_cache, "Cache for 'story alpha' should exist"
    assert_instance_of Array, story_alpha_cache
    assert_equal 1, story_alpha_cache.length

    location = story_alpha_cache.first
    assert_equal 'Story Alpha', location['title']
    assert_equal 'First Collection', location['parent_book_title']
    assert_equal '/books/first-collection.html', location['url']
    assert_equal 'story-alpha', location['slug']
  end

  def test_correctly_slugifies_complex_title
    complex_story_cache = @cache['short_stories']["a & b's story"]
    refute_nil complex_story_cache, "Cache for 'a & b's story' should exist"
    location = complex_story_cache.first
    assert_equal "A & B's Story", location['title']
    assert_equal 'a-b-s-story', location['slug']
  end

  def test_ignores_book_without_is_anthology_flag
    assert_nil @cache['short_stories']['ignored story'], 'Story from book without flag should not be cached'
  end

  def test_ignores_unpublished_anthology
    assert_nil @cache['short_stories']['unpublished story'], 'Story from unpublished anthology should not be cached'
  end

  def test_ignores_story_title_with_no_id_flag
    assert_nil @cache['short_stories']['story with no id'], "Story with 'no_id' flag should be ignored"
  end

  def test_handles_duplicate_story_titles_across_books
    dup_story_cache = @cache['short_stories']['duplicate story']
    refute_nil dup_story_cache, 'Cache for duplicate story should exist'
    assert_instance_of Array, dup_story_cache
    assert_equal 2, dup_story_cache.length, 'Cache for duplicate story should have two entries'

    # Check for the entry from the first anthology
    location1 = dup_story_cache.find { |loc| loc['parent_book_title'] == 'First Collection' }
    refute_nil location1
    assert_equal '/books/first-collection.html', location1['url']
    assert_equal 'duplicate-story', location1['slug']

    # Check for the entry from the second anthology
    location2 = dup_story_cache.find { |loc| loc['parent_book_title'] == 'Second Collection' }
    refute_nil location2
    assert_equal '/books/second-collection.html', location2['url']
    assert_equal 'duplicate-story', location2['slug']
  end

  def test_does_not_incorrectly_match_tag_with_extra_content
    # This test proves the need for a more robust regex.
    # A simple non-greedy regex might match `{% short_story_title "A Title with a %}" %}`
    # incorrectly by stopping at the first `%\}`.
    # Our final regex should be robust enough to not match this at all.
    malformed_content_book = create_doc(
      { 'title' => 'Malformed Content', 'is_anthology' => true, 'published' => true },
      '/books/malformed.html',
      # This line is intentionally malformed Liquid
      '### {% short_story_title "A Title with a %}" in it %}'
    )

    # We need to re-run the generator with this new book.
    temp_site = create_site({}, { 'books' => [@anthology1, malformed_content_book] })
    temp_cache = temp_site.data['link_cache']

    assert_nil temp_cache['short_stories']['a title with a '], 'Should not create a partial match from a malformed tag'
  end
end
