# frozen_string_literal: true

require_relative '../../../../support/related_book_finder_test_case'

# Mentioned books and forward-link ranking.
class TestRelatedBooksFinderForwardLinks < RelatedBookFinderTestCase
  # --- Forward links (mentioned books) tests ---

  def test_mentioned_books_appear_after_series_and_author
    coll = MockCollection.new([], 'books')
    # Current book mentions "Mentioned Book" via book_link
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 10,
      url_suffix: 'current',
      collection: coll,
    )
    # Same author book (should appear first after series)
    same_author = @helper.create_book(
      title: 'Same Author Book',
      authors: ['Author A'],
      date_offset_days: 5,
      url_suffix: 'same-author',
      collection: coll,
    )
    # Mentioned book (should appear after same author)
    mentioned = @helper.create_book(
      title: 'Mentioned Book',
      authors: ['Author B'],
      date_offset_days: 3,
      url_suffix: 'mentioned',
      collection: coll,
    )

    coll.docs = [curr, same_author, mentioned]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    # Inject forward_links: current → mentioned
    site.data['link_cache']['forward_links'] = {
      curr.url => [{ target: mentioned, type: 'book', count: 1, min_position: 50 }],
    }
    finder = Jekyll::Books::Related::Finder.new(site, curr, 3)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    assert_equal same_author.url, result[:books][0].url, 'Same author should come first'
    assert_equal mentioned.url, result[:books][1].url, 'Mentioned book should come second'
  end

  def test_mentioned_short_story_appears_between_book_and_series
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 10,
      url_suffix: 'current',
      collection: coll,
    )
    # Mentioned via book_link (highest priority)
    book_mentioned = @helper.create_book(
      title: 'Book Mentioned',
      authors: ['Author B'],
      date_offset_days: 5,
      url_suffix: 'book-mentioned',
      collection: coll,
    )
    # Mentioned via short_story_link (medium priority)
    short_story_mentioned = @helper.create_book(
      title: 'Short Story Mentioned',
      authors: ['Author C'],
      date_offset_days: 4,
      url_suffix: 'short-story-mentioned',
      collection: coll,
    )
    # Mentioned via series_link (lowest priority)
    series_mentioned = @helper.create_book(
      title: 'Series Mentioned',
      authors: ['Author D'],
      date_offset_days: 3,
      url_suffix: 'series-mentioned',
      collection: coll,
    )

    coll.docs = [curr, book_mentioned, short_story_mentioned, series_mentioned]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    site.data['link_cache']['forward_links'] = {
      curr.url => [
        { target: series_mentioned, type: 'series', count: 1, min_position: 70 },
        { target: short_story_mentioned, type: 'short_story', count: 1, min_position: 50 },
        { target: book_mentioned, type: 'book', count: 1, min_position: 30 },
      ],
    }
    finder = Jekyll::Books::Related::Finder.new(site, curr, 3)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 3, result[:books].length
    assert_equal book_mentioned.url, result[:books][0].url, 'Book mention first'
    assert_equal short_story_mentioned.url, result[:books][1].url, 'Short story mention second'
    assert_equal series_mentioned.url, result[:books][2].url, 'Series mention third'
  end

  def test_mentioned_book_takes_priority_over_mentioned_series
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 10,
      url_suffix: 'current',
      collection: coll,
    )
    # Mentioned via book_link (higher priority)
    book_mentioned = @helper.create_book(
      title: 'Book Mentioned',
      authors: ['Author B'],
      date_offset_days: 5,
      url_suffix: 'book-mentioned',
      collection: coll,
    )
    # Mentioned via series_link (lower priority)
    series_mentioned = @helper.create_book(
      title: 'Series Mentioned',
      authors: ['Author C'],
      date_offset_days: 3,
      url_suffix: 'series-mentioned',
      collection: coll,
    )

    coll.docs = [curr, book_mentioned, series_mentioned]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    site.data['link_cache']['forward_links'] = {
      curr.url => [
        { target: series_mentioned, type: 'series', count: 1, min_position: 50 },
        { target: book_mentioned, type: 'book', count: 1, min_position: 50 },
      ],
    }
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    assert_equal book_mentioned.url, result[:books][0].url, 'Book mention should come before series mention'
    assert_equal series_mentioned.url, result[:books][1].url
  end

  def test_mentioned_books_sorted_by_date_when_scores_tied
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 20,
      url_suffix: 'current',
      collection: coll,
    )
    # Older book (alphabetically first)
    mentioned_alpha = @helper.create_book(
      title: 'Alpha Book',
      authors: ['Author B'],
      date_offset_days: 10,
      url_suffix: 'mentioned-alpha',
      collection: coll,
    )
    # More recent book (alphabetically second)
    mentioned_beta = @helper.create_book(
      title: 'Beta Book',
      authors: ['Author C'],
      date_offset_days: 2,
      url_suffix: 'mentioned-beta',
      collection: coll,
    )

    coll.docs = [curr, mentioned_alpha, mentioned_beta]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    # Same scores (count=1, early position) — ties broken by date desc
    site.data['link_cache']['forward_links'] = {
      curr.url => [
        { target: mentioned_alpha, type: 'book', count: 1, min_position: 50 },
        { target: mentioned_beta, type: 'book', count: 1, min_position: 50 },
      ],
    }
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    assert_equal mentioned_beta.url, result[:books][0].url, 'More recent book should come first when scores tied'
    assert_equal mentioned_alpha.url, result[:books][1].url
  end

  def test_mentioned_books_sorted_alphabetically_when_scores_and_dates_tied
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 20,
      url_suffix: 'current',
      collection: coll,
    )
    # Same date, title comes later alphabetically
    mentioned_beta = @helper.create_book(
      title: 'Beta Book',
      authors: ['Author B'],
      date_offset_days: 5,
      url_suffix: 'mentioned-beta',
      collection: coll,
    )
    # Same date, title comes first alphabetically
    mentioned_alpha = @helper.create_book(
      title: 'Alpha Book',
      authors: ['Author C'],
      date_offset_days: 5,
      url_suffix: 'mentioned-alpha',
      collection: coll,
    )

    coll.docs = [curr, mentioned_beta, mentioned_alpha]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    # Same scores, same dates — ties broken alphabetically
    site.data['link_cache']['forward_links'] = {
      curr.url => [
        { target: mentioned_beta, type: 'book', count: 1, min_position: 50 },
        { target: mentioned_alpha, type: 'book', count: 1, min_position: 50 },
      ],
    }
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    assert_equal mentioned_alpha.url, result[:books][0].url, 'Alpha should come first when scores and dates tied'
    assert_equal mentioned_beta.url, result[:books][1].url
  end

  def test_position_breaks_tie_when_counts_equal
    # When counts are equal, earlier position wins (lower min_position is better)
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 20,
      url_suffix: 'current',
      collection: coll,
    )
    # Same count, early position, older date
    early_mention = @helper.create_book(
      title: 'Early Mention',
      authors: ['Author B'],
      date_offset_days: 10,
      url_suffix: 'early',
      collection: coll,
    )
    # Same count, late position, recent date
    late_mention = @helper.create_book(
      title: 'Late Mention',
      authors: ['Author C'],
      date_offset_days: 2,
      url_suffix: 'late',
      collection: coll,
    )

    coll.docs = [curr, early_mention, late_mention]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    # Same count, different positions — position should break tie
    site.data['link_cache']['forward_links'] = {
      curr.url => [
        { target: early_mention, type: 'book', count: 1, min_position: 20 },
        { target: late_mention, type: 'book', count: 1, min_position: 80 },
      ],
    }

    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Earlier position wins, even though late_mention has more recent date
    assert_equal early_mention.url, result[:books][0].url, 'Earlier position should win over later'
    assert_equal late_mention.url, result[:books][1].url
  end

  def test_date_breaks_tie_when_count_and_position_equal
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 20,
      url_suffix: 'current',
      collection: coll,
    )
    # High score (2 mentions), oldest date
    high_score = @helper.create_book(
      title: 'Zeta High Score',
      authors: ['Author B'],
      date_offset_days: 15,
      url_suffix: 'high-score',
      collection: coll,
    )
    # Low score (1 mention), same position, older date
    low_score_old = @helper.create_book(
      title: 'Alpha Low Old',
      authors: ['Author C'],
      date_offset_days: 10,
      url_suffix: 'low-old',
      collection: coll,
    )
    # Low score (1 mention), same position, recent date
    low_score_recent = @helper.create_book(
      title: 'Beta Low Recent',
      authors: ['Author D'],
      date_offset_days: 2,
      url_suffix: 'low-recent',
      collection: coll,
    )

    coll.docs = [curr, high_score, low_score_old, low_score_recent]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    # high_score has count=2, others have count=1 and same position — date breaks tie
    site.data['link_cache']['forward_links'] = {
      curr.url => [
        { target: high_score, type: 'book', count: 2, min_position: 10 },
        { target: low_score_old, type: 'book', count: 1, min_position: 50 },
        { target: low_score_recent, type: 'book', count: 1, min_position: 50 },
      ],
    }

    finder = Jekyll::Books::Related::Finder.new(site, curr, 3)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 3, result[:books].length
    # high_score wins on score (2 > 1), regardless of being oldest
    assert_equal high_score.url, result[:books][0].url, 'Highest score should be first despite oldest date'
    # Tied count and position: more recent date wins
    assert_equal low_score_recent.url, result[:books][1].url, 'More recent should be second when count and position tied'
    assert_equal low_score_old.url, result[:books][2].url, 'Older should be third when count and position tied'
  end

  def test_mixed_dates_alpha_tiebreaker_only_for_tied_pair
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 20,
      url_suffix: 'current',
      collection: coll,
    )
    # Same score, most recent date
    recent_date = @helper.create_book(
      title: 'Zeta Recent',
      authors: ['Author B'],
      date_offset_days: 2,
      url_suffix: 'recent',
      collection: coll,
    )
    # Same score, same older date, alpha first
    old_date_alpha = @helper.create_book(
      title: 'Alpha Old',
      authors: ['Author C'],
      date_offset_days: 10,
      url_suffix: 'old-alpha',
      collection: coll,
    )
    # Same score, same older date, alpha second
    old_date_beta = @helper.create_book(
      title: 'Beta Old',
      authors: ['Author D'],
      date_offset_days: 10,
      url_suffix: 'old-beta',
      collection: coll,
    )

    coll.docs = [curr, recent_date, old_date_alpha, old_date_beta]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    # All have same score (count=1, early position)
    site.data['link_cache']['forward_links'] = {
      curr.url => [
        { target: recent_date, type: 'book', count: 1, min_position: 50 },
        { target: old_date_alpha, type: 'book', count: 1, min_position: 50 },
        { target: old_date_beta, type: 'book', count: 1, min_position: 50 },
      ],
    }
    finder = Jekyll::Books::Related::Finder.new(site, curr, 3)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 3, result[:books].length
    # recent_date wins on date, regardless of title (Zeta)
    assert_equal recent_date.url, result[:books][0].url, 'Most recent should be first despite Zeta title'
    # Tied dates: alpha_old wins on title over beta_old
    assert_equal old_date_alpha.url, result[:books][1].url, 'Alpha should be second among tied dates'
    assert_equal old_date_beta.url, result[:books][2].url, 'Beta should be third among tied dates'
  end

  def test_mentioned_books_scored_by_mention_count
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 20,
      url_suffix: 'current',
      collection: coll,
    )
    # Book mentioned once
    mentioned_once = @helper.create_book(
      title: 'Alpha Once',
      authors: ['Author B'],
      date_offset_days: 10,
      url_suffix: 'once',
      collection: coll,
    )
    # Book mentioned three times (higher score)
    mentioned_thrice = @helper.create_book(
      title: 'Zeta Thrice',
      authors: ['Author C'],
      date_offset_days: 2,
      url_suffix: 'thrice',
      collection: coll,
    )

    coll.docs = [curr, mentioned_once, mentioned_thrice]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    # thrice has count=3, once has count=1 (both early positions)
    site.data['link_cache']['forward_links'] = {
      curr.url => [
        { target: mentioned_once, type: 'book', count: 1, min_position: 50 },
        { target: mentioned_thrice, type: 'book', count: 3, min_position: 10 },
      ],
    }

    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    assert_equal mentioned_thrice.url, result[:books][0].url, 'Book with more mentions should rank higher'
    assert_equal mentioned_once.url, result[:books][1].url
  end

  def test_late_mentions_downweighted_as_future_reads
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 20,
      url_suffix: 'current',
      collection: coll,
    )
    # Book mentioned early (substantive)
    substantive = @helper.create_book(
      title: 'Zeta Substantive',
      authors: ['Author B'],
      date_offset_days: 10,
      url_suffix: 'substantive',
      collection: coll,
    )
    # Book mentioned only at the end (future read, should be downweighted)
    future_read = @helper.create_book(
      title: 'Alpha Future',
      authors: ['Author C'],
      date_offset_days: 2,
      url_suffix: 'future',
      collection: coll,
    )

    coll.docs = [curr, substantive, future_read]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    # Substantive at 10% (early, no penalty), Future at 95% (penalized)
    site.data['link_cache']['forward_links'] = {
      curr.url => [
        { target: substantive, type: 'book', count: 1, min_position: 10 },
        { target: future_read, type: 'book', count: 1, min_position: 95 },
      ],
    }

    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Substantive (1x early, score=1.0) beats Future (1x late, score=0.25)
    # Even though 'Alpha Future' < 'Zeta Substantive' alphabetically
    assert_equal substantive.url, result[:books][0].url, 'Early mention should beat late (future read)'
    assert_equal future_read.url, result[:books][1].url
  end

  def test_mixed_early_and_late_mentions_uses_min_position
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 20,
      url_suffix: 'current',
      collection: coll,
    )
    # Book mentioned both early and late - should use min (early) position
    mixed_mentions = @helper.create_book(
      title: 'Zeta Mixed',
      authors: ['Author B'],
      date_offset_days: 10,
      url_suffix: 'mixed',
      collection: coll,
    )
    # Book mentioned only late - should be penalized
    late_only = @helper.create_book(
      title: 'Alpha Late',
      authors: ['Author C'],
      date_offset_days: 2,
      url_suffix: 'late',
      collection: coll,
    )

    coll.docs = [curr, mixed_mentions, late_only]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    # mixed_mentions: count=2, min_pos=5% (early, no penalty)
    # late_only: count=1, min_pos=94% (penalized)
    site.data['link_cache']['forward_links'] = {
      curr.url => [
        { target: mixed_mentions, type: 'book', count: 2, min_position: 5 },
        { target: late_only, type: 'book', count: 1, min_position: 94 },
      ],
    }

    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # mixed_mentions: score=2 (count=2, min_pos=5%, no penalty)
    # late_only: score=0.25 (count=1, min_pos=94%, penalized)
    assert_equal mixed_mentions.url, result[:books][0].url, 'Book with early mention should not be penalized despite late mention too'
    assert_equal late_only.url, result[:books][1].url
  end

  def test_boundary_at_future_read_threshold
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author A'],
      date_offset_days: 20,
      url_suffix: 'current',
      collection: coll,
    )
    # Book just below threshold (91%) - should NOT be penalized
    just_below = @helper.create_book(
      title: 'Zeta Below',
      authors: ['Author B'],
      date_offset_days: 10,
      url_suffix: 'below',
      collection: coll,
    )
    # Book at/above threshold (93%) - should be penalized
    at_threshold = @helper.create_book(
      title: 'Alpha Above',
      authors: ['Author C'],
      date_offset_days: 2,
      url_suffix: 'above',
      collection: coll,
    )

    coll.docs = [curr, just_below, at_threshold]
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    # just_below at 91.5% -> below 92% threshold, no penalty
    # at_threshold at 92.5% -> at/above 92% threshold, penalized
    site.data['link_cache']['forward_links'] = {
      curr.url => [
        { target: just_below, type: 'book', count: 1, min_position: 91.5 },
        { target: at_threshold, type: 'book', count: 1, min_position: 92.5 },
      ],
    }

    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # just_below at 91.5% -> score = 1.0 (no penalty, below 92% threshold)
    # at_threshold at 92.5% -> score = 0.25 (penalized, at/above 92% threshold)
    # Even though 'Alpha Above' < 'Zeta Below' alphabetically, score wins
    assert_equal just_below.url, result[:books][0].url, 'Book at 91.5% should not be penalized'
    assert_equal at_threshold.url, result[:books][1].url, 'Book at 92.5% should be penalized'
  end
end
