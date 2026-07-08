# frozen_string_literal: true

# _tests/src/content/short_stories/test_short_story_resolver.rb
require_relative '../../../test_helper'

# Tests for Jekyll::ShortStories::ShortStoryResolver class.
#
# Verifies that the resolver correctly creates links to short stories within anthology books.
class TestShortStoryResolver < Minitest::Test
  def setup
    create_mock_story_cache
    setup_test_site
    setup_test_context
    @silent_logger_stub = silent_logger
  end

  # Helper to call the resolver
  def render_util(story_title, from_book_title = nil, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      Jekyll::ShortStories::ShortStoryResolver.new(context).resolve(story_title, from_book_title)
    end
  end

  def test_render_unique_story_found_and_linked
    output = render_util('Unique Story')
    assert_match(%r{<a href="/books/one\.html#unique-story"><cite class="short-story-title">Unique Story</cite>}, output)
  end

  def test_render_multiple_mentions_in_same_book_links_to_first
    output = render_util('Story Mentioned Twice In One Book')
    assert_match(
      %r{<a href="/books/three\.html#story-mentioned-twice"><cite class="short-story-title">Story Mentioned Twice</cite>},
      output,
    )
    refute_match(/<!--.*?RENDER_SHORT_STORY_LINK_FAILURE.*?-->/, output)
  end

  def test_prefers_canonical_location_over_archived
    canonical_url = '/books/canonical-anthology.html'
    archived_url = '/books/canonical-anthology/2023.html'
    @site.data['link_cache']['url_to_canonical_map'] = {
      canonical_url => canonical_url,
      archived_url => canonical_url,
    }
    @site.data['link_cache']['short_stories']['story in archive'] = [
      {
        'title' => 'Story in Archive',
        'parent_book_title' => 'Canonical Anthology',
        'url' => canonical_url,
        'slug' => 'story-slug',
      },
      {
        'title' => 'Story in Archive',
        'parent_book_title' => 'Archived Anthology',
        'url' => archived_url,
        'slug' => 'story-slug',
      },
    ]

    output = render_util('Story in Archive')
    assert_match(
      %r{<a href="/books/canonical-anthology\.html#story-slug"><cite class="short-story-title">Story in Archive</cite>},
      output,
    )
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
    assert_match(
      %r{<a href="/books/two\.html#duplicate-story"><cite class="short-story-title">Duplicate Story</cite>},
      output,
    )
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

  def test_render_fallback_when_no_site_in_context
    # When context has no site (e.g., nil context), should return unlinked cite element
    nil_context = nil
    resolver = Jekyll::ShortStories::ShortStoryResolver.new(nil_context)
    output = resolver.resolve('Some Story', nil)
    expected = '<cite class="short-story-title">Some Story</cite>'
    assert_equal expected, output
  end

  def test_render_link_is_created_for_anchor_on_current_page
    @mock_story_cache['story on this page'] = [
      {
        'title' => 'Story On This Page',
        'parent_book_title' => 'Current Book',
        'url' => '/current-page.html',
        'slug' => 'story-on-this-page',
      },
    ]
    output = render_util('Story On This Page')
    expected = '<a href="#story-on-this-page"><cite class="short-story-title">Story On This Page</cite></a>'
    assert_equal expected, output
    refute_match(/book-preview/, output, 'Same-page anchor links should not include a preview')
  end

  # --- resolve_data() tests ---

  def resolve_data_util(story_title, from_book_title = nil, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      Jekyll::ShortStories::ShortStoryResolver.new(context).resolve_data(story_title, from_book_title)
    end
  end

  def test_resolve_data_found
    data = resolve_data_util('Unique Story')
    assert_equal :found, data[:status]
    assert_equal '/books/one.html#unique-story', data[:url]
    assert_equal 'Unique Story', data[:display_text]
  end

  def test_resolve_data_not_found
    data = resolve_data_util('NonExistent Story')
    assert_equal :not_found, data[:status]
    assert_nil data[:url]
    assert_equal 'NonExistent Story', data[:display_text]
  end

  def test_resolve_data_ambiguous
    data = resolve_data_util('Duplicate Story')
    assert_equal :ambiguous, data[:status]
    assert_nil data[:url]
    assert_equal 'Duplicate Story', data[:display_text]
  end

  def test_resolve_data_resolved_by_book_filter
    data = resolve_data_util('Duplicate Story', 'Book Two')
    assert_equal :found, data[:status]
    assert_equal '/books/two.html#duplicate-story', data[:url]
    assert_equal 'Duplicate Story', data[:display_text]
  end

  def test_resolve_data_empty_title
    data = resolve_data_util('')
    assert_equal :empty_title, data[:status]
    assert_nil data[:url]
    assert_nil data[:display_text]
  end

  def test_resolve_data_no_site
    data = Jekyll::ShortStories::ShortStoryResolver.new(nil).resolve_data('Some Story', nil)
    assert_equal :no_site, data[:status]
    assert_nil data[:url]
    assert_equal 'Some Story', data[:display_text]
  end

  def test_resolve_data_frozen
    data = resolve_data_util('Unique Story')
    assert data.frozen?, 'resolve_data() should return a frozen hash'
  end

  def test_resolve_data_includes_parent_book_fields_when_book_cached
    add_book_to_cache('Book One', '/books/one.html',
                      rating: 4, image: '/images/one.jpg',
                      authors: ['Author A'], series: 'Test Series', book_number: 1)

    data = resolve_data_util('Unique Story')
    assert_equal :found, data[:status]
    assert_equal 'Book One', data[:book_title]
    assert_equal ['Author A'], data[:authors]
    assert_equal 4, data[:rating]
    assert_equal '/images/one.jpg', data[:image]
    assert_equal 'Test Series', data[:series]
    assert_equal 1, data[:book_number]
  end

  def test_resolve_data_book_fields_nil_when_book_not_cached
    data = resolve_data_util('Unique Story')
    assert_equal :found, data[:status]
    assert_nil data[:book_title]
    assert_nil data[:authors]
    assert_nil data[:rating]
  end

  # --- Preview tests ---

  def test_render_includes_book_preview_when_book_cached
    add_book_to_cache('Book One', '/books/one.html',
                      rating: 4, image: '/images/one.jpg',
                      authors: ['Author A'], series: 'Test Series', book_number: 1)

    output = render_util('Unique Story')
    assert_match(/<!--book-preview-->/, output)
    assert_match(/<!--\/book-preview-->/, output)
    assert_match(/book-link-preview/, output)
    assert_match(/Author A/, output)
  end

  def test_render_no_preview_when_book_not_cached
    output = render_util('Unique Story')
    refute_match(/book-preview/, output)
  end

  def test_render_no_preview_for_same_page_anchor
    add_book_to_cache('Current Book', '/current-page.html',
                      rating: 5, image: '/images/current.jpg', authors: ['Author B'])

    @mock_story_cache['story on this page'] = [
      {
        'title' => 'Story On This Page',
        'parent_book_title' => 'Current Book',
        'url' => '/current-page.html',
        'slug' => 'story-on-this-page',
      },
    ]
    output = render_util('Story On This Page')
    assert_match(%r{<a href="#story-on-this-page">}, output)
    refute_match(/book-preview/, output, 'Same-page anchor links should not include a preview')
  end

  private

  # Creates mock short story cache data
  def create_mock_story_cache
    @mock_story_cache = {
      'unique story' => [
        {
          'title' => 'Unique Story',
          'parent_book_title' => 'Book One',
          'url' => '/books/one.html',
          'slug' => 'unique-story',
        },
      ],
      # Same title in DIFFERENT books. This should still require disambiguation.
      'duplicate story' => [
        {
          'title' => 'Duplicate Story',
          'parent_book_title' => 'Book One',
          'url' => '/books/one.html',
          'slug' => 'duplicate-story',
        },
        {
          'title' => 'Duplicate Story',
          'parent_book_title' => 'Book Two',
          'url' => '/books/two.html',
          'slug' => 'duplicate-story',
        },
      ],
      # Same title mentioned multiple times in the SAME book. This is NOT ambiguous.
      'story mentioned twice in one book' => [
        {
          'title' => 'Story Mentioned Twice',
          'parent_book_title' => 'Book Three',
          'url' => '/books/three.html',
          'slug' => 'story-mentioned-twice',
        },
        {
          'title' => 'Story Mentioned Twice',
          'parent_book_title' => 'Book Three',
          'url' => '/books/three.html',
          'slug' => 'story-mentioned-twice-2',
        },
      ],
    }
  end

  # Sets up test site with story cache
  def setup_test_site
    @site = create_site
    @site.data['link_cache']['short_stories'] = @mock_story_cache
    @site.config['plugin_logging']['RENDER_SHORT_STORY_LINK'] = true # Enable logging for tests
  end

  def add_book_to_cache(title, url, rating: nil, image: nil, authors: [], series: nil, book_number: nil)
    normalized = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(title)
    @site.data['link_cache']['books'] ||= {}
    @site.data['link_cache']['books'][normalized] ||= []
    @site.data['link_cache']['books'][normalized] << {
      'url' => url,
      'title' => title,
      'authors' => authors,
      'rating' => rating,
      'image' => image,
      'series' => series,
      'book_number' => book_number,
    }
  end

  # Sets up test context
  def setup_test_context
    @current_page = create_doc({ 'path' => 'current_page.md' }, '/current-page.html')
    @context = create_context({}, { site: @site, page: @current_page })
  end
end
