# frozen_string_literal: true

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

  def test_renders_markdown_link
    context = create_context({}, { site: @site, page: @current_page, render_mode: :markdown })
    template = Liquid::Template.parse('{% short_story_link "Unique Story" %}')
    assert_equal '[_Unique Story_](/books/one.html#unique-story)', template.render!(context)
  end

  def test_render_multiple_mentions_in_same_book_links_to_first
    data = resolve_data_util('Story Mentioned Twice In One Book')
    expected = [:found, '/books/three.html#story-mentioned-twice', 'Story Mentioned Twice']
    assert_equal expected, data.values_at(:status, :url, :display_text)
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

  def test_resolve_data_does_not_reuse_previous_book_filter
    resolver = Jekyll::ShortStories::ShortStoryResolver.new(@context)
    first, second = Jekyll.stub :logger, @silent_logger_stub do
      [resolver.resolve_data('Duplicate Story', 'Book Two'), resolver.resolve_data('Duplicate Story', nil)]
    end

    assert_equal :found, first[:status]
    assert_equal :ambiguous, second[:status], 'a call without from_book must not reuse the earlier filter'
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

  def test_render_includes_book_preview_when_book_cached
    add_book_to_cache('Book One', '/books/one.html', rating: 4, authors: ['Author A'])
    template = Liquid::Template.parse('{% short_story_link "Unique Story" %}')
    output = template.render!(@context)
    assert_match(%r{\A<a href="/books/one\.html#unique-story"><cite class="short-story-title">Unique Story</cite><!--book-preview-->}, output)
    assert_includes output, 'Author A'
    assert output.end_with?('<!--/book-preview--></a>')
  end

  def test_render_no_preview_when_book_not_cached
    output = render_util('Unique Story')
    refute_match(/book-preview/, output)
  end

  def test_render_no_preview_for_same_page_anchor
    add_book_to_cache(
      'Current Book',
      '/current-page.html',
      rating: 5,
      image: '/images/current.jpg',
      authors: ['Author B'],
    )

    @mock_story_cache['story on this page'] = [
      {
        'title' => 'Story On This Page',
        'parent_book_title' => 'Current Book',
        'url' => '/current-page.html',
        'slug' => 'story-on-this-page',
      },
    ]
    output = render_util('Story On This Page')
    assert_match(/<a href="#story-on-this-page">/, output)
    refute_match(/book-preview/, output, 'Same-page anchor links should not include a preview')
  end

  def test_reused_instance_does_not_leak_ambiguous_status
    Jekyll.stub :logger, @silent_logger_stub do
      resolver = Jekyll::ShortStories::ShortStoryResolver.new(@context)

      first = resolver.resolve_data('Duplicate Story', nil)
      assert_equal :ambiguous, first[:status]

      second = resolver.resolve_data('NonExistent Story', nil)
      assert_equal(
        :not_found,
        second[:status],
        'a merely-missing resolve after an ambiguous one must not return :ambiguous',
      )
    end
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
