# frozen_string_literal: true

require_relative '../../../../test_helper'

# Exercises both mention rankings against the data each consumes.
class TestRankedByBacklinksFinder < Minitest::Test
  def setup
    @site = create_site
    @cache = @site.data['link_cache']
    @context = create_context({}, { site: @site })
  end

  def test_finds_and_ranks_books_correctly_sorted
    @cache['books'] = {
      'book a' => [{ 'url' => '/a.html', 'title' => 'Book A' }],
      'book b' => [{ 'url' => '/b.html', 'title' => 'Book B' }],
      'book c' => [{ 'url' => '/c.html', 'title' => 'Book C' }],
      'duplicate' => [{ 'url' => '/a.html', 'title' => 'Duplicate' }],
    }
    @cache['backlinks'] = {
      '/c.html' => [{ type: 'series' }],
      '/unknown.html' => [{ type: 'book' }, { type: 'book' }, { type: 'book' }],
      '/a.html' => [{ type: 'book' }],
      '/b.html' => [{ type: 'book' }, { type: 'series' }],
    }

    expected = {
      logs: '',
      ranked_list: [
        { title: 'Book B', url: '/b.html', count: 2 },
        { title: 'Book C', url: '/c.html', count: 1 },
        { title: 'Book A', url: '/a.html', count: 1 },
      ],
    }
    assert_equal expected, find
  end

  def test_returns_empty_ranked_list_when_no_backlinks_exist
    assert_equal({ logs: '', ranked_list: [] }, find)
  end

  def test_returns_error_when_link_cache_missing
    @site.config['plugin_logging']['RANKED_BY_BACKLINKS'] = true
    missing_caches = [nil, @cache.except('backlinks'), @cache.except('books')]
    missing_caches.each do |cache|
      @site.data['link_cache'] = cache

      result = Jekyll.stub(:logger, silent_logger) { find }

      assert_empty result[:ranked_list]
      assert_includes result[:logs], 'RANKED_BY_BACKLINKS_FAILURE'
      assert_includes result[:logs], 'Prerequisites missing: link_cache, backlinks, or books cache.'
    end
  end

  private

  def find
    Jekyll::Books::Ranking::Finder.new(@context).by_backlinks
  end
end

# Exercises the mention tracker and reviewed-title filter.
class TestUnreviewedMentionsFinder < Minitest::Test
  def setup
    @site = create_site
    @site.data['link_cache']['books']['reviewed book'] = [{ 'url' => '/books/reviewed.html' }]
    @context = create_context({}, { site: @site })
  end

  def test_ranks_by_mention_count
    @site.data['mention_tracker'] = {
      'few mentions' => { sources: Set['/one.html'], original_titles: { 'Few Mentions' => 2, 'Few mentions' => 2 } },
      'many mentions' => {
        sources: Set['/one.html', '/two.html', '/three.html'],
        original_titles: { 'many mentions' => 1, 'Many Mentions' => 4 },
      },
      'reviewed book' => { sources: Set['/one.html'], original_titles: { 'Reviewed Book' => 1 } },
      'fallback title' => { sources: Set['/one.html'], original_titles: {} },
    }

    expected = {
      logs: '',
      mentions: [
        { title: 'Many Mentions', count: 3 },
        { title: 'Few Mentions', count: 1 },
        { title: 'fallback title', count: 1 },
      ],
    }
    assert_equal expected, find
  end

  def test_returns_empty_when_no_mentions
    assert_equal({ logs: '', mentions: [] }, find)
  end

  def test_find_logs_error_if_mention_tracker_is_missing
    @site.config['plugin_logging']['UNREVIEWED_MENTIONS'] = true
    %w[mention_tracker link_cache].each do |key|
      data = @site.data.delete(key)
      result = Jekyll.stub(:logger, silent_logger) { find }
      @site.data[key] = data

      assert_empty result[:mentions]
      assert_includes result[:logs], 'UNREVIEWED_MENTIONS_FAILURE'
      assert_includes result[:logs], 'Prerequisites missing: mention_tracker or link_cache[&#39;books&#39;] not found.'
    end
  end

  private

  def find
    Jekyll::Books::Ranking::Finder.new(@context).unreviewed_mentions
  end
end
