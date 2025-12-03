# frozen_string_literal: true

# _tests/plugins/logic/ranked_by_backlinks/test_finder.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/books/ranking/finder'

# Tests for Jekyll::RankedByBacklinks::Finder.
#
# Verifies that the Finder correctly processes backlinks cache and ranks books.
class TestRankedByBacklinksFinder < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({}, { site: @site })

    # Pre-populate the link_cache for tests
    @site.data['link_cache']['books'] = {
      'book a' => [{ 'url' => '/a.html', 'title' => 'Book A', 'authors' => [] }],
      'book b' => [{ 'url' => '/b.html', 'title' => 'Book B', 'authors' => [] }],
      'book c' => [{ 'url' => '/c.html', 'title' => 'Book C', 'authors' => [] }]
    }
  end

  def test_returns_empty_ranked_list_when_no_backlinks_exist
    @site.data['link_cache']['backlinks'] = {}

    finder = Jekyll::RankedByBacklinks::Finder.new(@context)
    result = finder.find

    assert_equal '', result[:logs]
    assert_equal [], result[:ranked_list]
  end

  def test_finds_and_ranks_books_correctly_sorted
    setup_backlink_data_for_ranking_test

    finder = Jekyll::RankedByBacklinks::Finder.new(@context)
    result = finder.find

    assert_equal '', result[:logs]
    assert_equal 3, result[:ranked_list].length

    # Verify correct sorting: Book B (3), Book A (2), Book C (1)
    assert_equal 'Book B', result[:ranked_list][0][:title]
    assert_equal '/b.html', result[:ranked_list][0][:url]
    assert_equal 3, result[:ranked_list][0][:count]

    assert_equal 'Book A', result[:ranked_list][1][:title]
    assert_equal '/a.html', result[:ranked_list][1][:url]
    assert_equal 2, result[:ranked_list][1][:count]

    assert_equal 'Book C', result[:ranked_list][2][:title]
    assert_equal '/c.html', result[:ranked_list][2][:url]
    assert_equal 1, result[:ranked_list][2][:count]
  end

  def test_returns_error_when_link_cache_missing
    fresh_site = create_site
    fresh_site.data.delete('link_cache')
    fresh_context = create_context({}, { site: fresh_site })
    fresh_site.config['plugin_logging']['RANKED_BY_BACKLINKS'] = true

    finder = Jekyll::RankedByBacklinks::Finder.new(fresh_context)
    result = nil

    capture_io do
      result = finder.find
    end

    refute_empty result[:logs]
    assert_match(/RANKED_BY_BACKLINKS_FAILURE/, result[:logs])
    assert_match(/Prerequisites missing/, result[:logs])
    assert_equal [], result[:ranked_list]
  end

  def test_returns_error_when_backlinks_key_missing
    @site.data['link_cache'].delete('backlinks')
    @site.config['plugin_logging']['RANKED_BY_BACKLINKS'] = true

    finder = Jekyll::RankedByBacklinks::Finder.new(@context)
    result = nil

    capture_io do
      result = finder.find
    end

    refute_empty result[:logs]
    assert_match(/RANKED_BY_BACKLINKS_FAILURE/, result[:logs])
    assert_equal [], result[:ranked_list]
  end

  def test_returns_error_when_books_key_missing
    @site.data['link_cache'].delete('books')
    @site.config['plugin_logging']['RANKED_BY_BACKLINKS'] = true

    finder = Jekyll::RankedByBacklinks::Finder.new(@context)
    result = nil

    capture_io do
      result = finder.find
    end

    refute_empty result[:logs]
    assert_match(/RANKED_BY_BACKLINKS_FAILURE/, result[:logs])
    assert_equal [], result[:ranked_list]
  end

  def test_excludes_books_not_in_books_cache
    # Add a backlink for a book that doesn't exist in the books cache
    @site.data['link_cache']['backlinks'] = {
      '/a.html' => [{ source: create_doc, type: 'book' }],
      '/unknown.html' => [{ source: create_doc, type: 'book' }]
    }

    finder = Jekyll::RankedByBacklinks::Finder.new(@context)
    result = finder.find

    assert_equal 1, result[:ranked_list].length
    assert_equal 'Book A', result[:ranked_list][0][:title]
  end

  private

  def setup_backlink_data_for_ranking_test
    # Book B is mentioned most (3), then A (2), then C (1)
    @site.data['link_cache']['backlinks'] = {
      '/a.html' => [
        { source: create_doc, type: 'book' },
        { source: create_doc, type: 'series' }
      ],
      '/b.html' => [
        { source: create_doc, type: 'book' },
        { source: create_doc, type: 'book' },
        { source: create_doc, type: 'direct' }
      ],
      '/c.html' => [
        { source: create_doc, type: 'book' }
      ]
    }
  end
end
