# _tests/plugins/utils/test_short_story_link_util.rb
require_relative '../../test_helper'

class TestShortStoryLinkUtils < Minitest::Test

  def setup
    # --- Mock Short Story Cache Data ---
    @mock_story_cache = {
      'unique story' => [
        { 'title' => 'Unique Story', 'parent_book_title' => 'Book One', 'url' => '/books/one.html', 'slug' => 'unique-story' }
      ],
      'duplicate story' => [
        { 'title' => 'Duplicate Story', 'parent_book_title' => 'Book One', 'url' => '/books/one.html', 'slug' => 'duplicate-story' },
        { 'title' => 'Duplicate Story', 'parent_book_title' => 'Book Two', 'url' => '/books/two.html', 'slug' => 'duplicate-story' }
      ]
    }

    @site = create_site
    @site.data['link_cache']['short_stories'] = @mock_story_cache
    @site.config['plugin_logging']['RENDER_SHORT_STORY_LINK'] = true # Enable logging for tests

    @current_page = create_doc({ 'path' => 'current_page.md' }, '/current-page.html')
    @context = create_context({}, { site: @site, page: @current_page })

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end; def logger.debug(topic, message); end
    end
  end

  # Helper to call the utility
  def render_util(story_title, from_book_title = nil, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      ShortStoryLinkUtils.render_short_story_link(story_title, context, from_book_title)
    end
  end

  def test_render_unique_story_found_and_linked
    output = render_util("Unique Story")
    expected = "<a href=\"/books/one.html#unique-story\"><cite class=\"short-story-title\">Unique Story</cite></a>"
    assert_equal expected, output
  end

  def test_render_story_not_found_returns_unlinked_cite_and_logs
    output = render_util("NonExistent Story")
    expected = "<cite class=\"short-story-title\">NonExistent Story</cite>"
    # The log is prepended to the output
    assert_match %r{<!-- \[INFO\] RENDER_SHORT_STORY_LINK_FAILURE: Reason='Could not find short story in cache\.' StoryTitle='NonExistent Story' .*? -->#{Regexp.escape(expected)}}, output
  end

  def test_render_duplicate_story_with_disambiguation_succeeds
    output = render_util("Duplicate Story", "Book Two")
    expected = "<a href=\"/books/two.html#duplicate-story\"><cite class=\"short-story-title\">Duplicate Story</cite></a>"
    assert_equal expected, output
  end

  def test_render_duplicate_story_without_disambiguation_fails_and_logs
    output = render_util("Duplicate Story")
    expected = "<cite class=\"short-story-title\">Duplicate Story</cite>"
    assert_match %r{<!-- \[ERROR\] RENDER_SHORT_STORY_LINK_FAILURE: Reason='Ambiguous story title\. Use &#39;from_book&#39; to specify which book\.' StoryTitle='Duplicate Story' FoundIn='&#39;Book One&#39;, &#39;Book Two&#39;' .*? -->#{Regexp.escape(expected)}}, output
  end

  def test_render_duplicate_story_with_wrong_disambiguation_fails_and_logs
    output = render_util("Duplicate Story", "Book Three") # Book Three does not contain this story
    expected = "<cite class=\"short-story-title\">Duplicate Story</cite>"
    assert_match %r{<!-- \[WARN\] RENDER_SHORT_STORY_LINK_FAILURE: Reason='Story found in cache but not in the specified book\.' StoryTitle='Duplicate Story' FromBook='Book Three' .*? -->#{Regexp.escape(expected)}}, output
  end

  def test_render_empty_or_nil_title_returns_empty_and_logs
    output = render_util(nil)
    assert_match %r{<!-- \[WARN\] RENDER_SHORT_STORY_LINK_FAILURE: Reason='Input story title resolved to an empty string\.' TitleInput='nil' .*? -->}, output

    output_empty = render_util("   ")
    assert_match %r{<!-- \[WARN\] RENDER_SHORT_STORY_LINK_FAILURE: Reason='Input story title resolved to an empty string\.' TitleInput='   ' .*? -->}, output_empty
  end

  def test_render_link_is_created_for_anchor_on_current_page
    # Simulate the story being on the current page
    @mock_story_cache['story on this page'] = [
      { 'title' => 'Story On This Page', 'parent_book_title' => 'Current Book', 'url' => '/current-page.html', 'slug' => 'story-on-this-page' }
    ]
    output = render_util("Story On This Page")
    expected = "<a href=\"#story-on-this-page\"><cite class=\"short-story-title\">Story On This Page</cite></a>" # Expect anchor link
    assert_equal expected, output
  end
end
