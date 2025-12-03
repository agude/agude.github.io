# frozen_string_literal: true

# _tests/plugins/utils/test_short_story_link_util.rb
require_relative '../../../test_helper'

# Tests for ShortStoryLinkUtils module.
#
# Verifies that the utility correctly creates links to short stories within anthology books.
class TestShortStoryLinkUtils < Minitest::Test
  def setup
    create_mock_story_cache
    setup_test_site
    setup_test_context
    @silent_logger_stub = create_silent_logger_stub
  end

  # Helper to call the utility
  def render_util(story_title, from_book_title = nil, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      ShortStoryLinkUtils.render_short_story_link(story_title, context, from_book_title)
    end
  end

  def test_render_unique_story_found_and_linked
    output = render_util('Unique Story')
    expected = '<a href="/books/one.html#unique-story"><cite class="short-story-title">Unique Story</cite></a>'
    assert_equal expected, output
  end

  def test_render_multiple_mentions_in_same_book_links_to_first
    # This story is mentioned twice in "Book Three". The link should resolve to the first one
    # without needing disambiguation, as it's not truly ambiguous (it's not in multiple books).
    output = render_util('Story Mentioned Twice In One Book')
    expected =
      '<a href="/books/three.html#story-mentioned-twice"><cite class="short-story-title">Story Mentioned Twice</cite></a>'
    assert_equal expected, output
    # Also assert that no error/warning log was generated for ambiguity
    refute_match(/<!--.*?RENDER_SHORT_STORY_LINK_FAILURE.*?-->/, output)
  end

  def test_prefers_canonical_location_over_archived
    canonical_url = '/books/canonical-anthology.html'
    archived_url = '/books/canonical-anthology/2023.html'
    @site.data['link_cache']['url_to_canonical_map'] = {
      canonical_url => canonical_url,
      archived_url => canonical_url
    }
    @site.data['link_cache']['short_stories']['story in archive'] = [
      { 'title' => 'Story in Archive', 'parent_book_title' => 'Canonical Anthology', 'url' => canonical_url,
        'slug' => 'story-slug' },
      { 'title' => 'Story in Archive', 'parent_book_title' => 'Archived Anthology', 'url' => archived_url,
        'slug' => 'story-slug' }
    ]

    # This would be ambiguous without the new logic
    output = render_util('Story in Archive')
    expected =
      '<a href="/books/canonical-anthology.html#story-slug"><cite class="short-story-title">Story in Archive</cite></a>'
    assert_equal expected, output
    refute_match(/<!--.*?RENDER_SHORT_STORY_LINK_FAILURE.*?-->/, output, 'Should not log an ambiguity error')
  end

  def test_render_story_not_found_returns_unlinked_cite_and_logs
    output = render_util('NonExistent Story')
    expected = '<cite class="short-story-title">NonExistent Story</cite>'
    # The log is prepended to the output
    expected_log_pattern =
      /<!-- \[INFO\] RENDER_SHORT_STORY_LINK_FAILURE: Reason='Could not find short story in cache\.' StoryTitle='NonExistent Story' .*? -->#{Regexp.escape(expected)}/
    assert_match(expected_log_pattern, output)
  end

  def test_render_duplicate_story_with_disambiguation_succeeds
    output = render_util('Duplicate Story', 'Book Two')
    expected = '<a href="/books/two.html#duplicate-story"><cite class="short-story-title">Duplicate Story</cite></a>'
    assert_equal expected, output
  end

  def test_render_duplicate_story_without_disambiguation_fails_and_logs
    output = render_util('Duplicate Story')
    expected = '<cite class="short-story-title">Duplicate Story</cite>'
    expected_log_pattern =
      /<!-- \[ERROR\] RENDER_SHORT_STORY_LINK_FAILURE: Reason='Ambiguous story title\. Use &#39;from_book&#39; to specify which book\.' StoryTitle='Duplicate Story' FoundIn='&#39;Book One&#39;, &#39;Book Two&#39;' .*? -->#{Regexp.escape(expected)}/
    assert_match(expected_log_pattern, output)
  end

  def test_render_duplicate_story_with_wrong_disambiguation_fails_and_logs
    output = render_util('Duplicate Story', 'Book Three') # Book Three does not contain this story
    expected = '<cite class="short-story-title">Duplicate Story</cite>'
    expected_log_pattern =
      /<!-- \[WARN\] RENDER_SHORT_STORY_LINK_FAILURE: Reason='Story found in cache but not in the specified book\.' StoryTitle='Duplicate Story' FromBook='Book Three' .*? -->#{Regexp.escape(expected)}/
    assert_match(expected_log_pattern, output)
  end

  def test_render_empty_or_nil_title_returns_empty_and_logs
    output = render_util(nil)
    expected_log_pattern =
      /<!-- \[WARN\] RENDER_SHORT_STORY_LINK_FAILURE: Reason='Input story title resolved to an empty string\.' TitleInput='nil' .*? -->/
    assert_match(expected_log_pattern, output)

    output_empty = render_util('   ')
    expected_log_pattern_empty =
      /<!-- \[WARN\] RENDER_SHORT_STORY_LINK_FAILURE: Reason='Input story title resolved to an empty string\.' TitleInput='   ' .*? -->/
    assert_match(expected_log_pattern_empty, output_empty)
  end

  def test_render_link_is_created_for_anchor_on_current_page
    # Simulate the story being on the current page
    @mock_story_cache['story on this page'] = [
      { 'title' => 'Story On This Page', 'parent_book_title' => 'Current Book', 'url' => '/current-page.html',
        'slug' => 'story-on-this-page' }
    ]
    output = render_util('Story On This Page')
    expected = '<a href="#story-on-this-page"><cite class="short-story-title">Story On This Page</cite></a>'
    assert_equal expected, output
  end

  private

  # Creates mock short story cache data
  def create_mock_story_cache
    @mock_story_cache = {
      'unique story' => [
        { 'title' => 'Unique Story', 'parent_book_title' => 'Book One', 'url' => '/books/one.html',
          'slug' => 'unique-story' }
      ],
      # Same title in DIFFERENT books. This should still require disambiguation.
      'duplicate story' => [
        { 'title' => 'Duplicate Story', 'parent_book_title' => 'Book One', 'url' => '/books/one.html',
          'slug' => 'duplicate-story' },
        { 'title' => 'Duplicate Story', 'parent_book_title' => 'Book Two', 'url' => '/books/two.html',
          'slug' => 'duplicate-story' }
      ],
      # Same title mentioned multiple times in the SAME book. This is NOT ambiguous.
      'story mentioned twice in one book' => [
        { 'title' => 'Story Mentioned Twice', 'parent_book_title' => 'Book Three', 'url' => '/books/three.html',
          'slug' => 'story-mentioned-twice' },
        { 'title' => 'Story Mentioned Twice', 'parent_book_title' => 'Book Three', 'url' => '/books/three.html',
          'slug' => 'story-mentioned-twice-2' }
      ]
    }
  end

  # Sets up test site with story cache
  def setup_test_site
    @site = create_site
    @site.data['link_cache']['short_stories'] = @mock_story_cache
    @site.config['plugin_logging']['RENDER_SHORT_STORY_LINK'] = true # Enable logging for tests
  end

  # Sets up test context
  def setup_test_context
    @current_page = create_doc({ 'path' => 'current_page.md' }, '/current-page.html')
    @context = create_context({}, { site: @site, page: @current_page })
  end

  # Creates a silent logger stub
  def create_silent_logger_stub
    Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
  end
end
