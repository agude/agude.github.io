# frozen_string_literal: true

require_relative '../../../../../test_helper'

# Tests for Jekyll::Books::Ranking::UnreviewedMentions::Finder
#
# Verifies that unreviewed book mentions are correctly found and ranked.
class TestUnreviewedMentionsFinder < Minitest::Test
  def setup
    @book = create_doc(
      { 'title' => 'Reviewed Book', 'published' => true },
      '/books/reviewed.html'
    )
  end

  def create_site_with_mentions(mention_tracker, books_cache = {})
    site = create_site({}, { 'books' => [@book] })
    site.data['mention_tracker'] = mention_tracker
    site.data['link_cache'] = { 'books' => books_cache }
    site
  end

  def test_returns_empty_when_no_mentions
    site = create_site_with_mentions({})
    context = create_context({}, { site: site, page: @book })

    finder = Jekyll::Books::Ranking::UnreviewedMentions::Finder.new(context)
    result = finder.find

    assert_empty result[:mentions]
  end

  def test_finds_unreviewed_mentions
    tracker = {
      'unreviewed book' => {
        sources: ['/posts/one.html', '/posts/two.html'],
        original_titles: { 'Unreviewed Book' => 2 }
      }
    }
    site = create_site_with_mentions(tracker, { 'reviewed book' => @book })
    context = create_context({}, { site: site, page: @book })

    finder = Jekyll::Books::Ranking::UnreviewedMentions::Finder.new(context)
    result = finder.find

    assert_equal 1, result[:mentions].length
    assert_equal 'Unreviewed Book', result[:mentions].first[:title]
    assert_equal 2, result[:mentions].first[:count]
  end

  def test_excludes_reviewed_books
    tracker = {
      'reviewed book' => {
        sources: ['/posts/one.html'],
        original_titles: { 'Reviewed Book' => 1 }
      }
    }
    site = create_site_with_mentions(tracker, { 'reviewed book' => @book })
    context = create_context({}, { site: site, page: @book })

    finder = Jekyll::Books::Ranking::UnreviewedMentions::Finder.new(context)
    result = finder.find

    assert_empty result[:mentions]
  end

  def test_ranks_by_mention_count
    tracker = {
      'few mentions' => {
        sources: ['/posts/one.html'],
        original_titles: { 'Few Mentions' => 1 }
      },
      'many mentions' => {
        sources: ['/posts/a.html', '/posts/b.html', '/posts/c.html'],
        original_titles: { 'Many Mentions' => 3 }
      }
    }
    site = create_site_with_mentions(tracker)
    context = create_context({}, { site: site, page: @book })

    finder = Jekyll::Books::Ranking::UnreviewedMentions::Finder.new(context)
    result = finder.find

    # Many mentions should be first
    assert_equal 'Many Mentions', result[:mentions].first[:title]
    assert_equal 'Few Mentions', result[:mentions].last[:title]
  end

  def test_uses_most_common_title_variant
    tracker = {
      'the book' => {
        sources: ['/posts/one.html', '/posts/two.html', '/posts/three.html'],
        original_titles: { 'The Book' => 2, 'the book' => 1 }
      }
    }
    site = create_site_with_mentions(tracker)
    context = create_context({}, { site: site, page: @book })

    finder = Jekyll::Books::Ranking::UnreviewedMentions::Finder.new(context)
    result = finder.find

    # Should use "The Book" (2 occurrences) not "the book" (1)
    assert_equal 'The Book', result[:mentions].first[:title]
  end

  def test_handles_missing_site
    context = create_context({}, { site: nil, page: @book })

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil) do |prefix, msg|
      prefix == 'PluginLogger:' && msg.include?('UNREVIEWED_MENTIONS')
    end

    finder = Jekyll::Books::Ranking::UnreviewedMentions::Finder.new(context)
    result = nil
    Jekyll.stub :logger, mock_logger do
      result = finder.find
    end

    # Should gracefully handle missing site (logger returns empty when no site config)
    assert_empty result[:mentions]
    mock_logger.verify
  end

  def test_handles_multiple_unreviewed_books
    tracker = {
      'book a' => {
        sources: ['/posts/one.html'],
        original_titles: { 'Book A' => 1 }
      },
      'book b' => {
        sources: ['/posts/two.html'],
        original_titles: { 'Book B' => 1 }
      },
      'book c' => {
        sources: ['/posts/three.html'],
        original_titles: { 'Book C' => 1 }
      }
    }
    site = create_site_with_mentions(tracker)
    context = create_context({}, { site: site, page: @book })

    finder = Jekyll::Books::Ranking::UnreviewedMentions::Finder.new(context)
    result = finder.find

    assert_equal 3, result[:mentions].length
  end
end
