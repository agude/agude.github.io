# frozen_string_literal: true

require_relative '../../../../support/related_book_finder_test_case'

# Backlinks and priority across related-book tiers.
class TestRelatedBooksFinderBacklinks < RelatedBookFinderTestCase
  # --- Backlinks (mentioning reviews) tests ---

  def test_backlinks_appear_after_forward_links
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 10,
      url_suffix: 'current',
      collection: coll,
    )
    # Book that current mentions
    mentioned = @helper.create_book(
      title: 'Mentioned Book',
      authors: ['Author B'],
      date_offset_days: 5,
      url_suffix: 'mentioned',
      collection: coll,
    )
    # Book that mentions current (backlink)
    mentioner = @helper.create_book(
      title: 'Mentioner Book',
      authors: ['Author C'],
      date_offset_days: 3,
      url_suffix: 'mentioner',
      collection: coll,
    )

    coll.docs = [curr, mentioned, mentioner]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    site.data['link_cache']['forward_links'] = {
      curr.url => [{ target: mentioned, type: 'book' }],
    }
    site.data['link_cache']['backlinks'] = {
      curr.url => [{ source: mentioner, type: 'book' }],
    }
    finder = Jekyll::Books::Related::Finder.new(site, curr, 3)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    assert_equal mentioned.url, result[:books][0].url, 'Forward link should come before backlink'
    assert_equal mentioner.url, result[:books][1].url, 'Backlink should come second'
  end

  # Verifies books and short stories share a tier, with series in a separate tier.
  # Uses assert_includes (not order assertion) because both works have equal scores;
  # their relative order depends on date tiebreaker, which isn't the focus here.
  def test_backlink_books_and_short_stories_share_tier
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 10,
      url_suffix: 'current',
      collection: coll,
    )
    # Mentions current via book_link
    book_mentioner = @helper.create_book(
      title: 'Book Mentioner',
      authors: ['Author B'],
      date_offset_days: 5,
      url_suffix: 'book-mentioner',
      collection: coll,
    )
    # Mentions current via short_story_link
    short_story_mentioner = @helper.create_book(
      title: 'Short Story Mentioner',
      authors: ['Author C'],
      date_offset_days: 4,
      url_suffix: 'short-story-mentioner',
      collection: coll,
    )
    # Mentions current via series_link
    series_mentioner = @helper.create_book(
      title: 'Series Mentioner',
      authors: ['Author D'],
      date_offset_days: 3,
      url_suffix: 'series-mentioner',
      collection: coll,
    )

    coll.docs = [curr, book_mentioner, short_story_mentioner, series_mentioner]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    # Equal scores for book and short_story — both should appear before series
    site.data['link_cache']['backlinks'] = {
      curr.url => [
        { source: series_mentioner, type: 'series', count: 1, min_position: 10 },
        { source: short_story_mentioner, type: 'short_story', count: 1, min_position: 20 },
        { source: book_mentioner, type: 'book', count: 1, min_position: 20 },
      ],
    }
    finder = Jekyll::Books::Related::Finder.new(site, curr, 3)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 3, result[:books].length
    works_urls = result[:books].first(2).map(&:url)
    assert_includes works_urls, book_mentioner.url, 'Book should appear in works tier'
    assert_includes works_urls, short_story_mentioner.url, 'Short story should appear in works tier'
    assert_equal series_mentioner.url, result[:books][2].url, 'Series remains in separate tier'
  end

  def test_backlink_works_tier_before_series_tier
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 10,
      url_suffix: 'current',
      collection: coll,
    )
    # Mentions current via book_link
    book_mentioner = @helper.create_book(
      title: 'Book Mentioner',
      authors: ['Author B'],
      date_offset_days: 5,
      url_suffix: 'book-mentioner',
      collection: coll,
    )
    # Mentions current via series_link
    series_mentioner = @helper.create_book(
      title: 'Series Mentioner',
      authors: ['Author C'],
      date_offset_days: 3,
      url_suffix: 'series-mentioner',
      collection: coll,
    )

    coll.docs = [curr, book_mentioner, series_mentioner]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    # Series has higher score, but works tier still comes first
    site.data['link_cache']['backlinks'] = {
      curr.url => [
        { source: series_mentioner, type: 'series', count: 5, min_position: 10 },
        { source: book_mentioner, type: 'book', count: 1, min_position: 50 },
      ],
    }
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    assert_equal book_mentioner.url, result[:books][0].url, 'Works tier comes before series tier regardless of score'
    assert_equal series_mentioner.url, result[:books][1].url
  end

  def test_short_story_outranks_book_when_higher_scored
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 10,
      url_suffix: 'current',
      collection: coll,
    )
    # Low-scored book (1 mention)
    book_mentioner = @helper.create_book(
      title: 'Book Mentioner',
      authors: ['Author B'],
      date_offset_days: 5,
      url_suffix: 'book-mentioner',
      collection: coll,
    )
    # High-scored short story (5 mentions)
    short_story_mentioner = @helper.create_book(
      title: 'Short Story Mentioner',
      authors: ['Author C'],
      date_offset_days: 3,
      url_suffix: 'short-story-mentioner',
      collection: coll,
    )

    coll.docs = [curr, book_mentioner, short_story_mentioner]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    site.data['link_cache']['forward_links'] = {
      curr.url => [
        { target: book_mentioner, type: 'book', count: 1, min_position: 10 },
        { target: short_story_mentioner, type: 'short_story', count: 5, min_position: 20 },
      ],
    }
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    assert_equal short_story_mentioner.url, result[:books][0].url, 'Higher-scored short story should beat lower-scored book'
    assert_equal book_mentioner.url, result[:books][1].url
  end

  def test_backlink_short_story_outranks_book_when_higher_scored
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 10,
      url_suffix: 'current',
      collection: coll,
    )
    # Low-scored book backlink (1 mention)
    book_mentioner = @helper.create_book(
      title: 'Book Mentioner',
      authors: ['Author B'],
      date_offset_days: 5,
      url_suffix: 'book-mentioner',
      collection: coll,
    )
    # High-scored short story backlink (5 mentions)
    short_story_mentioner = @helper.create_book(
      title: 'Short Story Mentioner',
      authors: ['Author C'],
      date_offset_days: 3,
      url_suffix: 'short-story-mentioner',
      collection: coll,
    )

    coll.docs = [curr, book_mentioner, short_story_mentioner]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    site.data['link_cache']['backlinks'] = {
      curr.url => [
        { source: book_mentioner, type: 'book', count: 1, min_position: 10 },
        { source: short_story_mentioner, type: 'short_story', count: 5, min_position: 20 },
      ],
    }
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    assert_equal short_story_mentioner.url, result[:books][0].url, 'Higher-scored short story backlink should beat lower-scored book backlink'
    assert_equal book_mentioner.url, result[:books][1].url
  end

  def test_works_tier_tiebreaker_by_date_then_title
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 20,
      url_suffix: 'current',
      collection: coll,
    )
    # Same score, older date, alphabetically first
    book_mentioner = @helper.create_book(
      title: 'Alpha Book',
      authors: ['Author B'],
      date_offset_days: 10,
      url_suffix: 'book-mentioner',
      collection: coll,
    )
    # Same score, more recent date, alphabetically second
    short_story_mentioner = @helper.create_book(
      title: 'Beta Short Story',
      authors: ['Author C'],
      date_offset_days: 5,
      url_suffix: 'short-story-mentioner',
      collection: coll,
    )

    coll.docs = [curr, book_mentioner, short_story_mentioner]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    # Identical scores — tiebreaker is date desc (more recent first)
    site.data['link_cache']['forward_links'] = {
      curr.url => [
        { target: book_mentioner, type: 'book', count: 2, min_position: 30 },
        { target: short_story_mentioner, type: 'short_story', count: 2, min_position: 30 },
      ],
    }
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Short story has more recent date despite being alphabetically second
    assert_equal short_story_mentioner.url, result[:books][0].url, 'More recent date wins on score tie'
    assert_equal book_mentioner.url, result[:books][1].url
  end

  def test_backlinks_sorted_by_score
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 20,
      url_suffix: 'current',
      collection: coll,
    )
    # Lower score (1 mention), alphabetically first
    mentioner_alpha = @helper.create_book(
      title: 'Alpha Mentioner',
      authors: ['Author B'],
      date_offset_days: 10,
      url_suffix: 'mentioner-alpha',
      collection: coll,
    )
    # Higher score (3 mentions), alphabetically second
    mentioner_beta = @helper.create_book(
      title: 'Beta Mentioner',
      authors: ['Author C'],
      date_offset_days: 2,
      url_suffix: 'mentioner-beta',
      collection: coll,
    )

    coll.docs = [curr, mentioner_alpha, mentioner_beta]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    site.data['link_cache']['backlinks'] = {
      curr.url => [
        { source: mentioner_alpha, type: 'book', count: 1, min_position: 50 },
        { source: mentioner_beta, type: 'book', count: 3, min_position: 10 },
      ],
    }
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Beta has higher score (3) despite being alphabetically second
    assert_equal mentioner_beta.url, result[:books][0].url, 'Higher scoring backlink should come first'
    assert_equal mentioner_alpha.url, result[:books][1].url
  end

  def test_backlinks_tiebreak_by_date_then_alphabetically
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 20,
      url_suffix: 'current',
      collection: coll,
    )
    # Same score, older date, alphabetically first
    mentioner_alpha = @helper.create_book(
      title: 'Alpha Mentioner',
      authors: ['Author B'],
      date_offset_days: 10,
      url_suffix: 'mentioner-alpha',
      collection: coll,
    )
    # Same score, more recent date, alphabetically second
    mentioner_beta = @helper.create_book(
      title: 'Beta Mentioner',
      authors: ['Author C'],
      date_offset_days: 2,
      url_suffix: 'mentioner-beta',
      collection: coll,
    )

    coll.docs = [curr, mentioner_alpha, mentioner_beta]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    # Same scores — tiebreaker is date desc, then alphabetical
    site.data['link_cache']['backlinks'] = {
      curr.url => [
        { source: mentioner_alpha, type: 'book', count: 1, min_position: 50 },
        { source: mentioner_beta, type: 'book', count: 1, min_position: 50 },
      ],
    }

    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Beta is more recent, should come first despite being alphabetically second
    assert_equal mentioner_beta.url, result[:books][0].url, 'More recent backlink should win on date tiebreaker'
    assert_equal mentioner_alpha.url, result[:books][1].url
  end

  # --- Full waterfall priority tests ---

  def test_full_waterfall_priority_order
    coll = MockCollection.new([], 'books')
    # Current book in a series
    curr = @helper.create_book(
      title: 'Current Book',
      series: 'Test Series',
      book_num: 2,
      authors: ['Author A'],
      date_offset_days: 30,
      url_suffix: 'current',
      collection: coll,
    )
    # 1. Series book (highest priority)
    series_book = @helper.create_book(
      title: 'Series Book',
      series: 'Test Series',
      book_num: 1,
      authors: ['Author B'],
      date_offset_days: 25,
      url_suffix: 'series',
      collection: coll,
    )
    # 2. Same author
    author_book = @helper.create_book(
      title: 'Author Book',
      authors: ['Author A'],
      date_offset_days: 20,
      url_suffix: 'author',
      collection: coll,
    )
    # 3. Mentioned book (forward_link type: book)
    mentioned_book = @helper.create_book(
      title: 'Mentioned Book',
      authors: ['Author C'],
      date_offset_days: 18,
      url_suffix: 'mentioned-book',
      collection: coll,
    )
    # 4. Mentioned short_story (forward_link type: short_story)
    mentioned_short_story = @helper.create_book(
      title: 'Mentioned Short Story',
      authors: ['Author D'],
      date_offset_days: 16,
      url_suffix: 'mentioned-short-story',
      collection: coll,
    )
    # 5. Mentioned series (forward_link type: series)
    mentioned_series = @helper.create_book(
      title: 'Mentioned Series',
      authors: ['Author E'],
      date_offset_days: 14,
      url_suffix: 'mentioned-series',
      collection: coll,
    )
    # 6. Backlink book (backlinks type: book)
    backlink_book = @helper.create_book(
      title: 'Backlink Book',
      authors: ['Author F'],
      date_offset_days: 12,
      url_suffix: 'backlink-book',
      collection: coll,
    )
    # 7. Backlink short_story (backlinks type: short_story)
    backlink_short_story = @helper.create_book(
      title: 'Backlink Short Story',
      authors: ['Author G'],
      date_offset_days: 10,
      url_suffix: 'backlink-short-story',
      collection: coll,
    )
    # 8. Backlink series (backlinks type: series)
    backlink_series = @helper.create_book(
      title: 'Backlink Series',
      authors: ['Author H'],
      date_offset_days: 8,
      url_suffix: 'backlink-series',
      collection: coll,
    )
    # 9. Recent fallback
    recent_book = @helper.create_book(
      title: 'Recent Book',
      authors: ['Author I'],
      date_offset_days: 1,
      url_suffix: 'recent',
      collection: coll,
    )

    coll.docs = [
      curr,
      series_book,
      author_book,
      mentioned_book,
      mentioned_short_story,
      mentioned_series,
      backlink_book,
      backlink_short_story,
      backlink_series,
      recent_book,
    ]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })

    # Set up forward_links and backlinks
    site.data['link_cache']['forward_links'] = {
      curr.url => [
        { target: mentioned_book, type: 'book', count: 1, min_position: 30 },
        { target: mentioned_short_story, type: 'short_story', count: 1, min_position: 40 },
        { target: mentioned_series, type: 'series', count: 1, min_position: 50 },
      ],
    }
    # Give backlink_book higher score so it ranks first in combined works tier
    site.data['link_cache']['backlinks'] = {
      curr.url => [
        { source: backlink_book, type: 'book', count: 2, min_position: 10 },
        { source: backlink_short_story, type: 'short_story', count: 1, min_position: 20 },
        { source: backlink_series, type: 'series', count: 1, min_position: 60 },
      ],
    }

    finder = Jekyll::Books::Related::Finder.new(site, curr, 9)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 9, result[:books].length
    expected_order = [
      series_book.url,            # 1. Series
      author_book.url,            # 2. Same author
      mentioned_book.url,         # 3. Mentioned book
      mentioned_short_story.url,  # 4. Mentioned short_story
      mentioned_series.url,       # 5. Mentioned series
      backlink_book.url,          # 6. Backlink book
      backlink_short_story.url,   # 7. Backlink short_story
      backlink_series.url,        # 8. Backlink series
      recent_book.url,            # 9. Recent fallback
    ]
    assert_equal expected_order, result[:books].map(&:url), 'Full waterfall priority order'
  end

  def test_handles_missing_forward_links_and_backlinks_cache_entries
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 10,
      url_suffix: 'current',
      collection: coll,
    )
    other = @helper.create_book(
      title: 'Other Book',
      authors: ['Author A'],
      date_offset_days: 5,
      url_suffix: 'other',
      collection: coll,
    )

    coll.docs = [curr, other]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    # Explicitly don't set forward_links or backlinks for curr.url
    # The cache exists but has no entry for this page
    site.data['link_cache']['forward_links'] = {}
    site.data['link_cache']['backlinks'] = {}

    finder = Jekyll::Books::Related::Finder.new(site, curr, 3)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    # Should still work, falling through to author/recent
    assert_equal 1, result[:books].length
    assert_equal other.url, result[:books][0].url
  end

  def test_deduplication_across_forward_and_back_link_tiers
    # BookA mentions BookB (forward_link) AND BookB mentions BookA (backlink).
    # BookB should appear only once in BookA's related books (from forward_link tier).
    coll = MockCollection.new([], 'books')
    book_a = @helper.create_book(
      title: 'Book A',
      authors: ['Author A'],
      date_offset_days: 10,
      url_suffix: 'book-a',
      collection: coll,
    )
    book_b = @helper.create_book(
      title: 'Book B',
      authors: ['Author B'],
      date_offset_days: 5,
      url_suffix: 'book-b',
      collection: coll,
    )

    coll.docs = [book_a, book_b]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    # BookA → BookB (forward) AND BookA ← BookB (backlink)
    site.data['link_cache']['forward_links'] = {
      book_a.url => [{ target: book_b, type: 'book', count: 1, min_position: 50 }],
    }
    site.data['link_cache']['backlinks'] = {
      book_a.url => [{ source: book_b, type: 'book' }],
    }

    finder = Jekyll::Books::Related::Finder.new(site, book_a, 3)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    # BookB should appear exactly once (from forward_link tier, not duplicated from backlink)
    assert_equal 1, result[:books].length
    assert_equal book_b.url, result[:books][0].url
  end

  def test_deduplication_across_tiers
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 10,
      url_suffix: 'current',
      collection: coll,
    )
    # This book is both same author AND mentioned
    overlap_book = @helper.create_book(
      title: 'Overlap Book',
      authors: ['Author A'],
      date_offset_days: 5,
      url_suffix: 'overlap',
      collection: coll,
    )
    # Only mentioned
    mentioned_only = @helper.create_book(
      title: 'Mentioned Only',
      authors: ['Author B'],
      date_offset_days: 3,
      url_suffix: 'mentioned-only',
      collection: coll,
    )

    coll.docs = [curr, overlap_book, mentioned_only]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    site.data['link_cache']['forward_links'] = {
      curr.url => [
        { target: overlap_book, type: 'book', count: 1, min_position: 50 },
        { target: mentioned_only, type: 'book', count: 1, min_position: 60 },
      ],
    }
    finder = Jekyll::Books::Related::Finder.new(site, curr, 3)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    # Overlap book should appear once (from author tier, not duplicated from mentioned tier)
    assert_equal 2, result[:books].length
    assert_equal overlap_book.url, result[:books][0].url, 'Overlap book appears from author tier'
    assert_equal mentioned_only.url, result[:books][1].url, 'Mentioned-only book fills next slot'
  end
end
