# frozen_string_literal: true

# _tests/plugins/logic/related_books/test_finder.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/related/finder'

# Tests for Jekyll::Books::Related::Finder.
#
# Verifies that the Finder correctly locates and ranks related books based on
# series, author, and recency.
class TestRelatedBooksFinder < Minitest::Test
  DEFAULT_MAX_BOOKS = Jekyll::Books::Related::Finder::DEFAULT_MAX_BOOKS
  CONFIG_KEY = 'display_limits'

  def setup
    @site_config_base = {
      'url' => 'http://example.com',
      'plugin_logging' => { 'RELATED_BOOKS' => true, 'RELATED_BOOKS_SERIES' => true },
      'plugin_log_level' => 'debug',
    }
    @test_time_now = Time.parse('2024-03-15 10:00:00 EST')
    @helper = BookTestHelper.new(@test_time_now, @site_config_base)
    @helper.setup_generic_books
    @context = create_context({}, { site: create_site, page: create_doc })
  end

  # --- Unit tests for score_from_cache ---

  def test_score_from_cache_returns_count_for_early_mentions
    finder = Jekyll::Books::Related::Finder.new(nil, nil, nil)
    entry = { count: 2, min_position: 50 }

    score = finder.send(:score_from_cache, entry)

    assert_equal 2.0, score
  end

  def test_score_from_cache_returns_count
    # score_from_cache simply returns the count for sorting
    finder = Jekyll::Books::Related::Finder.new(nil, nil, nil)
    entry = { count: 3, min_position: 95 }

    score = finder.send(:score_from_cache, entry)

    assert_equal 3, score
  end

  def test_score_from_cache_returns_zero_for_zero_count
    finder = Jekyll::Books::Related::Finder.new(nil, nil, nil)
    entry = { count: 0, min_position: 100 }

    score = finder.send(:score_from_cache, entry)

    assert_equal 0.0, score
  end

  def test_score_from_cache_returns_zero_for_nil_count
    # Entries with nil count (unused captures, direct links) score 0.
    # This is expected for links that exist for backlink symmetry but have no prose usage.
    finder = Jekyll::Books::Related::Finder.new(nil, nil, nil)
    entry = { count: nil, min_position: nil }

    score = finder.send(:score_from_cache, entry)

    assert_equal 0.0, score
  end

  def test_score_from_cache_returns_zero_for_missing_count_key
    # Entry without count key (e.g., from older cache format) scores 0 gracefully
    finder = Jekyll::Books::Related::Finder.new(nil, nil, nil)
    entry = { type: 'book' } # No count or min_position keys

    score = finder.send(:score_from_cache, entry)

    assert_equal 0.0, score
  end

  # --- Integration tests ---

  def test_returns_correct_structure_with_empty_books
    site = create_site(@site_config_base.dup, {})
    page = create_doc({ 'title' => 'Test', 'url' => '/test.html', 'path' => 'test.md' }, '/test.html')
    context = create_context({}, { site: site, page: page })

    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = nil
    Time.stub :now, @test_time_now do
      Jekyll.stub :logger, @helper.instance_variable_get(:@silent_logger_stub) do
        result = finder.find
      end
    end

    assert_kind_of Hash, result
    assert_kind_of String, result[:logs]
    assert_kind_of Array, result[:books]
  end

  def test_returns_series_books_in_correct_order
    books, site = @helper.setup_series_books(4)
    context = create_context({}, { site: site, page: books[0] })

    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 3, result[:books].length
    assert_equal books[1].url, result[:books][0].url
    assert_equal books[2].url, result[:books][1].url
    assert_equal books[3].url, result[:books][2].url
  end

  def test_series_book2_of_4_returns_books_1_3_4
    books, site = @helper.setup_series_books(4)
    context = create_context({}, { site: site, page: books[1] })

    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 3, result[:books].length
    assert_equal [books[0].url, books[2].url, books[3].url], result[:books].map(&:url)
  end

  def test_series_provides_zero_books_fills_with_author_and_recent
    _, _, _, context = @helper.setup_zero_series_books_scenario

    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 3, result[:books].length
    assert_equal @helper.author_x_book2_recent.url, result[:books][0].url
    assert_equal @helper.author_x_book1_old.url, result[:books][1].url
    assert_equal @helper.recent_unrelated_book1.url, result[:books][2].url
  end

  def test_excludes_archived_reviews
    _, _, _, _, context = @helper.setup_archived_reviews_scenario

    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    titles = result[:books].map { |b| b.data['title'] }
    assert_includes titles, 'Related Canonical'
    refute_includes titles, 'Related Archived'
  end

  def test_includes_external_canonical_url
    _, _, _, context = @helper.setup_external_canonical_scenario

    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    titles = result[:books].map { |b| b.data['title'] }
    assert_includes titles, 'Related External'
  end

  def test_logs_error_when_page_is_missing
    site = create_site(@site_config_base.dup)
    context = create_context({}, { site: site })

    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = nil
    Time.stub :now, @test_time_now do
      Jekyll.stub :logger, @helper.instance_variable_get(:@silent_logger_stub) do
        result = finder.find
      end
    end

    assert_empty result[:books]
    assert_match(/Missing prerequisites: page object/, result[:logs])
  end

  def test_logs_error_when_site_is_missing
    page = create_doc({ 'title' => 'Test', 'url' => '/test.html' }, '/test.html')
    context = Liquid::Context.new({}, {}, { page: page })
    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)

    _result, stderr_str = capture_io do
      finder.find
    end

    assert_match(/Context, Site, or Site Config unavailable for logging/, stderr_str)
    assert_match(/Original Call: RELATED_BOOKS - error: Missing prerequisites: site object/, stderr_str)
  end

  def test_logs_error_when_page_url_is_missing
    site = create_site(@site_config_base.dup, { 'books' => [] })
    page_no_url = create_doc({ 'title' => 'Test', 'path' => 'test.md' }, nil)
    context = create_context({}, { site: site, page: page_no_url })
    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = nil
    Jekyll.stub :logger, @helper.instance_variable_get(:@silent_logger_stub) do
      result = finder.find
    end
    assert_empty result[:books]
    assert_match(/Missing prerequisites: page\[&#39;url&#39;\]/, result[:logs])
  end

  def test_logs_error_when_books_collection_is_missing
    site_no_books = create_site(@site_config_base.dup) # No collections by default
    page = create_doc({ 'title' => 'Test', 'url' => '/test.html', 'path' => 'test.html' }, '/test.html')
    context = create_context({}, { site: site_no_books, page: page })
    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = nil
    Jekyll.stub :logger, @helper.instance_variable_get(:@silent_logger_stub) do
      result = finder.find
    end
    assert_empty result[:books]
    assert_match(/Missing prerequisites: site.collections\[&#39;books&#39;\]/, result[:logs])
  end

  def test_with_unparseable_book_number_logs_info
    _, _, _, _, _, _, context = @helper.setup_unparseable_book_number_scenario

    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = nil
    Time.stub :now, @test_time_now do
      Jekyll.stub :logger, @helper.instance_variable_get(:@silent_logger_stub) do
        result = finder.find
      end
    end

    assert_match(/unparseable book_number/, result[:logs])
    assert_equal 3, result[:books].length
  end

  def test_logs_error_when_link_cache_missing
    coll = MockCollection.new([], 'books')
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    page = create_doc({ 'title' => 'Test', 'url' => '/test.html' }, '/test.html')
    site.data.delete('link_cache')
    context = create_context({}, { site: site, page: page })

    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = nil
    Time.stub :now, @test_time_now do
      Jekyll.stub :logger, @helper.instance_variable_get(:@silent_logger_stub) do
        result = finder.find
      end
    end

    assert_empty result[:books]
    assert_match(/Link cache is missing/, result[:logs])
  end

  def test_excludes_unpublished_books
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author X'],
      date_offset_days: 10,
      url_suffix: 'current',
      collection: coll,
    )
    published_book = @helper.create_book(
      title: 'Published Book',
      authors: ['Author X'],
      date_offset_days: 5,
      url_suffix: 'published',
      collection: coll,
    )
    unpublished_book = @helper.create_book(
      title: 'Unpublished Book',
      authors: ['Author X'],
      date_offset_days: 3,
      url_suffix: 'unpublished',
      collection: coll,
      published: false,
    )

    coll.docs = [curr, published_book, unpublished_book].compact
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: curr })

    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    titles = result[:books].map { |b| b.data['title'] }
    assert_includes titles, 'Published Book'
    refute_includes titles, 'Unpublished Book'
  end

  def test_excludes_future_dated_books
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author X'],
      date_offset_days: 10,
      url_suffix: 'current',
      collection: coll,
    )
    past_book = @helper.create_book(
      title: 'Past Book',
      authors: ['Author X'],
      date_offset_days: 5,
      url_suffix: 'past',
      collection: coll,
    )
    future_book = @helper.create_book(
      title: 'Future Book',
      authors: ['Author X'],
      date_offset_days: -5,
      url_suffix: 'future',
      collection: coll,
    )

    coll.docs = [curr, past_book, future_book].compact
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: curr })

    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    titles = result[:books].map { |b| b.data['title'] }
    assert_includes titles, 'Past Book'
    refute_includes titles, 'Future Book'
  end

  def test_excludes_book_with_nil_data
    valid_books = [@helper.author_x_book1_old, @helper.author_x_book2_recent]
    site = create_site(@site_config_base.dup, { 'books' => valid_books })
    book_with_nil_data = @helper.create_book(title: 'Nil Data Book', authors: ['Author X'], url_suffix: 'nil-data')
    book_with_nil_data.data = nil
    site.collections['books'].docs << book_with_nil_data
    context = create_context({}, { site: site, page: @helper.author_x_book1_old })
    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = finder.find
    urls = result[:books].map(&:url)
    refute_includes urls, book_with_nil_data.url
    assert_includes urls, @helper.author_x_book2_recent.url
  end

  def test_excludes_book_with_nil_date
    book_with_nil_date = @helper.create_book(title: 'Nil Date Book', authors: ['Author X'], url_suffix: 'nil-date')
    book_with_nil_date.date = nil
    book_with_nil_date.data['date'] = nil
    coll = MockCollection.new([@helper.author_x_book1_old, @helper.author_x_book2_recent, book_with_nil_date], 'books')
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: @helper.author_x_book1_old })
    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = finder.find
    urls = result[:books].map(&:url)
    refute_includes urls, book_with_nil_date.url
    assert_includes urls, @helper.author_x_book2_recent.url
  end

  def test_limits_results_to_max_books
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author X'],
      date_offset_days: 20,
      url_suffix: 'current',
      collection: coll,
    )
    books = (1..10).map do |i|
      @helper.create_book(
        title: "Book #{i}",
        authors: ['Author X'],
        date_offset_days: i,
        url_suffix: "book#{i}",
        collection: coll,
      )
    end
    coll.docs = [curr] + books
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: curr })
    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], 5)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end
    assert_equal 5, result[:books].length
  end

  def test_excludes_current_page_and_canonical_url_match
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Current Book',
      authors: ['Author X'],
      date_offset_days: 10,
      url_suffix: 'current',
      collection: coll,
      extra_fm: { 'canonical_url' => '/books/canonical.html' },
    )
    canonical = @helper.create_book(
      title: 'Canonical Book',
      authors: ['Author X'],
      date_offset_days: 5,
      url_suffix: 'canonical',
      collection: coll,
    )
    other = @helper.create_book(
      title: 'Other Book',
      authors: ['Author X'],
      date_offset_days: 3,
      url_suffix: 'other',
      collection: coll,
    )
    coll.docs = [curr, canonical, other].compact
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: curr })
    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end
    titles = result[:books].map { |b| b.data['title'] }
    refute_includes titles, 'Current Book'
    refute_includes titles, 'Canonical Book'
    assert_includes titles, 'Other Book'
  end

  def test_fallback_to_recent_when_page_has_no_authors
    current_page = @helper.create_book(title: 'Current No Authors', authors: [], url_suffix: 'current-no-authors')
    coll = MockCollection.new(
      [
        current_page,
        @helper.author_x_book1_old,
        @helper.author_x_book2_recent,
        @helper.recent_unrelated_book1,
        @helper.recent_unrelated_book2,
      ],
      'books',
    )
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: current_page })
    finder = Jekyll::Books::Related::Finder.new(context.registers[:site], context.registers[:page], DEFAULT_MAX_BOOKS)
    result = finder.find
    expected_titles = [
      @helper.recent_unrelated_book1.data['title'],
      @helper.recent_unrelated_book2.data['title'],
      @helper.author_x_book2_recent.data['title'],
    ]
    actual_titles = result[:books].map { |b| b.data['title'] }
    assert_equal expected_titles, actual_titles
  end

  def test_private_method_parse_book_num_with_hash
    finder = Jekyll::Books::Related::Finder.new(@context.registers[:site], @context.registers[:page], DEFAULT_MAX_BOOKS)
    hash_obj = { 'book_number' => '3.14' }
    result = finder.send(:parse_book_num, hash_obj)
    assert_equal 3.14, result
  end

  # --- Config-driven limit tests ---

  def test_finder_uses_default_when_no_limit_and_no_config
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(title: 'Current', authors: ['A'], date_offset_days: 20, url_suffix: 'curr', collection: coll)
    books = (1..6).map do |i|
      @helper.create_book(title: "Book #{i}", authors: ['A'], date_offset_days: i, url_suffix: "b#{i}", collection: coll)
    end
    coll.docs = [curr] + books
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    finder = Jekyll::Books::Related::Finder.new(site, curr)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end
    assert_equal DEFAULT_MAX_BOOKS, result[:books].length
  end

  def test_finder_reads_limit_from_site_config
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(title: 'Current', authors: ['A'], date_offset_days: 20, url_suffix: 'curr', collection: coll)
    books = (1..6).map do |i|
      @helper.create_book(title: "Book #{i}", authors: ['A'], date_offset_days: i, url_suffix: "b#{i}", collection: coll)
    end
    coll.docs = [curr] + books
    config = @site_config_base.merge(CONFIG_KEY => { 'related_books' => 5 })
    site = create_site(config, { 'books' => coll.docs })
    finder = Jekyll::Books::Related::Finder.new(site, curr)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end
    assert_equal 5, result[:books].length
  end

  def test_finder_explicit_limit_overrides_config
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(title: 'Current', authors: ['A'], date_offset_days: 20, url_suffix: 'curr', collection: coll)
    books = (1..6).map do |i|
      @helper.create_book(title: "Book #{i}", authors: ['A'], date_offset_days: i, url_suffix: "b#{i}", collection: coll)
    end
    coll.docs = [curr] + books
    config = @site_config_base.merge(CONFIG_KEY => { 'related_books' => 5 })
    site = create_site(config, { 'books' => coll.docs })
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end
    assert_equal 2, result[:books].length
  end

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

  # --- Integration test: full pipeline with Liquid tags ---

  def test_integration_finder_uses_backlink_builder_output
    # This test runs the full pipeline: books with Liquid tags → BacklinkBuilder → Finder
    # Verifies the contract between how BacklinkBuilder stores entries and Finder reads them.
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      "Current book that mentions {% book_link 'Mentioned Book' %}.",
    )
    mentioned = create_doc(
      {
        'title' => 'Mentioned Book',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/mentioned.html',
      'A book that gets mentioned.',
    )
    mentioner = create_doc(
      {
        'title' => 'Mentioner Book',
        'book_authors' => ['Author C'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 3),
      },
      '/books/mentioner.html',
      "This book mentions {% book_link 'Current Book' %}.",
    )

    # create_site runs LinkCacheGenerator which runs BacklinkBuilder
    site = create_site(@site_config_base.dup, { 'books' => [curr, mentioned, mentioner] })

    # Verify BacklinkBuilder populated the caches (guards against test helper changes)
    forward_links = site.data.dig('link_cache', 'forward_links', curr.url)
    backlinks = site.data.dig('link_cache', 'backlinks', curr.url)
    refute_nil forward_links, 'BacklinkBuilder should populate forward_links for curr'
    refute_nil backlinks, 'BacklinkBuilder should populate backlinks for curr'
    assert forward_links.any? { |e| e[:target].url == mentioned.url }, 'forward_links should include mentioned book'
    assert backlinks.any? { |e| e[:source].url == mentioner.url }, 'backlinks should include mentioner book'

    finder = Jekyll::Books::Related::Finder.new(site, curr, 3)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    # Verify Finder correctly reads both forward_links and backlinks
    assert_equal 2, result[:books].length
    urls = result[:books].map(&:url)
    assert_includes urls, '/books/mentioned.html', 'Should include forward-linked book'
    assert_includes urls, '/books/mentioner.html', 'Should include backlinking book'
  end

  # --- End-to-end integration tests (raw content → BacklinkBuilder → Finder) ---

  def test_e2e_capture_usage_count_affects_ranking
    # Full pipeline: captures with different usage counts → BacklinkBuilder → Finder ranking
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      <<~CONTENT,
        {% capture often %}{% book_link "Often Mentioned" %}{% endcapture %}
        {% capture once %}{% book_link "Once Mentioned" %}{% endcapture %}

        I read {{ often }} first. Then {{ often }} again. And {{ often }} a third time.
        Also {{ once }} appeared briefly.
      CONTENT
    )
    often_book = create_doc(
      {
        'title' => 'Often Mentioned',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/often.html',
      'Content.',
    )
    once_book = create_doc(
      {
        'title' => 'Once Mentioned',
        'book_authors' => ['Author C'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/once.html',
      'Content.',
    )

    site = create_site(@site_config_base.dup, { 'books' => [curr, often_book, once_book] })
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Often (count=3) should rank before once (count=1)
    assert_equal '/books/often.html', result[:books][0].url, 'Higher mention count should rank first'
    assert_equal '/books/once.html', result[:books][1].url
  end

  def test_e2e_late_position_penalty_affects_ranking
    # Full pipeline: early vs late mentions → BacklinkBuilder calculates position → Finder applies penalty
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      <<~CONTENT,
        {% capture early %}{% book_link "Early Book" %}{% endcapture %}
        {% capture late %}{% book_link "Late Book" %}{% endcapture %}

        {{ early }} is discussed substantively here at the start.
        #{'x' * 1000}
        {{ late }} is just a future-reads mention at the very end.
      CONTENT
    )
    early_book = create_doc(
      {
        'title' => 'Early Book',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/early.html',
      'Content.',
    )
    late_book = create_doc(
      {
        'title' => 'Late Book',
        'book_authors' => ['Author C'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/late.html',
      'Content.',
    )

    site = create_site(@site_config_base.dup, { 'books' => [curr, early_book, late_book] })
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Early (no penalty) should rank before late (0.25 penalty)
    assert_equal '/books/early.html', result[:books][0].url, 'Early mention should rank before penalized late mention'
    assert_equal '/books/late.html', result[:books][1].url
  end

  def test_e2e_unused_capture_ranks_below_used_capture
    # Capture defined but never used in prose → scores 0 → ranks below used captures
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      <<~CONTENT,
        {% capture used %}{% book_link "Used Book" %}{% endcapture %}
        {% capture unused %}{% book_link "Unused Book" %}{% endcapture %}

        I really enjoyed {{ used }}. Great read.
      CONTENT
    )
    used_book = create_doc(
      {
        'title' => 'Used Book',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 20),
      },
      '/books/used.html',
      'Content.',
    )
    unused_book = create_doc(
      {
        'title' => 'Unused Book',
        'book_authors' => ['Author C'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/unused.html',
      'Content.',
    )

    site = create_site(@site_config_base.dup, { 'books' => [curr, used_book, unused_book] })
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Used (count=1, score=1) ranks before unused (count=nil, score=0)
    # Even though unused_book is more recent
    assert_equal '/books/used.html', result[:books][0].url, 'Used capture should rank before unused'
    assert_equal '/books/unused.html', result[:books][1].url
  end

  def test_e2e_multiple_captures_to_same_book_aggregate
    # Two captures pointing to the same book → counts sum → higher score
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      <<~CONTENT,
        {% capture maze %}{% book_link "A Maze of Death" %}{% endcapture %}
        {% capture death %}{% book_link "A Maze of Death" %}{% endcapture %}
        {% capture other %}{% book_link "Other Book" %}{% endcapture %}

        I read {{ maze }} first. Then {{ death }} reference. And {{ maze }} again.
        Also {{ other }} once.
      CONTENT
    )
    maze_book = create_doc(
      {
        'title' => 'A Maze of Death',
        'book_authors' => ['PKD'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/maze.html',
      'Content.',
    )
    other_book = create_doc(
      {
        'title' => 'Other Book',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/other.html',
      'Content.',
    )

    site = create_site(@site_config_base.dup, { 'books' => [curr, maze_book, other_book] })
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Maze (count=3 from {{ maze }}x2 + {{ death }}x1) ranks before other (count=1)
    assert_equal '/books/maze.html', result[:books][0].url, 'Aggregated counts should rank higher'
    assert_equal '/books/other.html', result[:books][1].url
  end

  def test_e2e_direct_link_scores_zero
    # Direct {% book_link %} without capture has no usage scoring → scores 0
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      <<~CONTENT,
        {% capture captured %}{% book_link "Captured Book" %}{% endcapture %}

        I read {{ captured }} via capture.
        Also {% book_link 'Direct Book' %} inline.
      CONTENT
    )
    captured_book = create_doc(
      {
        'title' => 'Captured Book',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 20),
      },
      '/books/captured.html',
      'Content.',
    )
    direct_book = create_doc(
      {
        'title' => 'Direct Book',
        'book_authors' => ['Author C'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/direct.html',
      'Content.',
    )

    site = create_site(@site_config_base.dup, { 'books' => [curr, captured_book, direct_book] })
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Captured (count=1) ranks before direct (count=nil, score=0)
    assert_equal '/books/captured.html', result[:books][0].url, 'Captured link should rank before direct link'
    assert_equal '/books/direct.html', result[:books][1].url
  end

  def test_e2e_forward_link_tier_precedes_backlink_tier
    # Forward links (with scoring) appear before backlinks (alphabetical only)
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      <<~CONTENT,
        {% capture forward %}{% book_link "Forward Book" %}{% endcapture %}

        I discussed {{ forward }} in this review.
      CONTENT
    )
    forward_book = create_doc(
      {
        'title' => 'Forward Book',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 30),
      },
      '/books/forward.html',
      'Content.',
    )
    backlink_book = create_doc(
      {
        'title' => 'AAA Backlink Book',
        'book_authors' => ['Author C'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 1),
      },
      '/books/backlink.html',
      "This book mentions {% book_link 'Current Book' %}.",
    )

    site = create_site(@site_config_base.dup, { 'books' => [curr, forward_book, backlink_book] })
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Forward link tier comes before backlink tier, regardless of date or alphabetical order
    assert_equal '/books/forward.html', result[:books][0].url, 'Forward link should precede backlink'
    assert_equal '/books/backlink.html', result[:books][1].url
  end

  def test_e2e_deduplication_forward_and_backlink_same_book
    # Book appears in both forward and backlink → should only appear once (forward tier wins)
    book_a = create_doc(
      {
        'title' => 'Book A',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/a.html',
      <<~CONTENT,
        {% capture b %}{% book_link "Book B" %}{% endcapture %}

        I mentioned {{ b }} here.
      CONTENT
    )
    book_b = create_doc(
      {
        'title' => 'Book B',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/b.html',
      <<~CONTENT,
        {% capture a %}{% book_link "Book A" %}{% endcapture %}

        I also mentioned {{ a }} in return.
      CONTENT
    )

    site = create_site(@site_config_base.dup, { 'books' => [book_a, book_b] })
    finder = Jekyll::Books::Related::Finder.new(site, book_a, 5)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    # Book B appears in forward_links AND backlinks for Book A
    # Should only appear once
    assert_equal 1, result[:books].length, 'Book B should appear only once despite being in both caches'
    assert_equal '/books/b.html', result[:books][0].url
  end

  def test_e2e_nested_capture_counts_only_prose_usage
    # Nested captures: inner used inside outer, outer used in prose.
    # Only prose-level usage ({{ outer }}) counts, not {{ inner }} inside outer's body.
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      <<~CONTENT,
        {% capture inner %}{% book_link "Nested Book" %}{% endcapture %}
        {% capture outer %}Wrapper: {{ inner }}.{% endcapture %}
        {% capture direct %}{% book_link "Direct Book" %}{% endcapture %}

        I read {{ outer }} and {{ direct }}.
      CONTENT
    )
    nested_book = create_doc(
      {
        'title' => 'Nested Book',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/nested.html',
      'Content.',
    )
    direct_book = create_doc(
      {
        'title' => 'Direct Book',
        'book_authors' => ['Author C'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/direct.html',
      'Content.',
    )

    site = create_site(@site_config_base.dup, { 'books' => [curr, nested_book, direct_book] })
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Both have count=1 (only prose-level {{ outer }} and {{ direct }} count).
    # {{ inner }} inside outer's body is template machinery, not a prose mention.
    # With equal scores, they tie-break by date (same), then alphabetically.
    urls = result[:books].map(&:url)
    assert_includes urls, '/books/nested.html'
    assert_includes urls, '/books/direct.html'
  end

  def test_e2e_raw_block_content_not_parsed
    # Links inside {% raw %} blocks should not create forward links.
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      <<~CONTENT,
        {% capture real %}{% book_link "Real Book" %}{% endcapture %}

        I read {{ real }}.

        Here's example Liquid syntax:
        {% raw %}
        {% capture example %}{% book_link "Example Book" %}{% endcapture %}
        {{ example }}
        {% endraw %}
      CONTENT
    )
    real_book = create_doc(
      {
        'title' => 'Real Book',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/real.html',
      'Content.',
    )
    example_book = create_doc(
      {
        'title' => 'Example Book',
        'book_authors' => ['Author C'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/example.html',
      'Content.',
    )

    site = create_site(@site_config_base.dup, { 'books' => [curr, real_book, example_book] })
    # Use max_books=1 to test only forward links tier (not recent tier fallback)
    finder = Jekyll::Books::Related::Finder.new(site, curr, 1)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    # Only real_book should appear; example_book is inside {% raw %}
    assert_equal 1, result[:books].length, 'Only non-raw links should create forward links'
    assert_equal '/books/real.html', result[:books][0].url
  end

  # Helper class for test setup and utilities
  class BookTestHelper
    attr_reader :test_time_now,
                :site_config_base,
                :author_x_book1_old,
                :author_x_book2_recent,
                :author_y_book1_recent,
                :recent_unrelated_book1,
                :recent_unrelated_book2,
                :recent_unrelated_book3,
                :unpublished_book_generic,
                :future_dated_book_generic

    def initialize(test_time_now, site_config_base)
      @test_time_now = test_time_now
      @site_config_base = site_config_base
      @silent_logger_stub = silent_logger
    end

    def setup_generic_books
      @author_x_book1_old = create_book(
        title: 'AuthorX Book1 (Old)',
        authors: ['Author X'],
        date_offset_days: 20,
        url_suffix: 'ax_b1_old',
      )
      @author_x_book2_recent = create_book(
        title: 'AuthorX Book2 (Recent)',
        authors: ['Author X'],
        date_offset_days: 5,
        url_suffix: 'ax_b2_recent',
      )
      @author_y_book1_recent = create_book(
        title: 'AuthorY Book1 (Recent)',
        authors: ['Author Y'],
        date_offset_days: 4,
        url_suffix: 'ay_b1_recent',
      )
      @recent_unrelated_book1 = create_book(
        title: 'Recent Unrelated 1',
        authors: ['Author Z'],
        date_offset_days: 1,
        url_suffix: 'ru1',
      )
      @recent_unrelated_book2 = create_book(
        title: 'Recent Unrelated 2',
        authors: ['Author W'],
        date_offset_days: 2,
        url_suffix: 'ru2',
      )
      @recent_unrelated_book3 = create_book(
        title: 'Recent Unrelated 3',
        authors: ['Author V'],
        date_offset_days: 3,
        url_suffix: 'ru3',
      )
      @unpublished_book_generic = create_book(
        title: 'Unpublished Book Generic',
        series: 'Series Misc',
        book_num: 1,
        authors: ['Author X'],
        date_offset_days: 5,
        url_suffix: 'unpub_gen',
        published: false,
      )
      @future_dated_book_generic = create_book(
        title: 'Future Book Generic',
        series: 'Series Misc',
        book_num: 1,
        authors: ['Author X'],
        date_offset_days: -5,
        url_suffix: 'future_gen',
      )
    end

    def create_book(title:, url_suffix:, authors: nil, series: nil, book_num: nil,
                    date_offset_days: 0, published: true, collection: nil, extra_fm: {})
      authors_data = normalize_authors(authors)
      front_matter = {
        'title' => title,
        'series' => series,
        'book_number' => book_num,
        'book_authors' => authors_data,
        'published' => published,
        'date' => @test_time_now - (60 * 60 * 24 * date_offset_days),
        'image' => "/images/book_#{url_suffix}.jpg",
        'excerpt_output_override' => "#{title} excerpt.",
      }.merge(extra_fm)
      create_doc(front_matter, "/books/#{url_suffix}.html", "Content for #{title}", nil, collection)
    end

    def normalize_authors(authors_input)
      return [] if authors_input.nil?
      return authors_input.map(&:to_s) if authors_input.is_a?(Array)

      [authors_input.to_s]
    end

    def setup_series_books(count)
      coll = MockCollection.new([], 'books')
      books = (1..count).map do |i|
        create_book(
          title: "S1B#{i}",
          series: 'Series 1',
          book_num: i,
          authors: ['Auth'],
          date_offset_days: 10 - i,
          url_suffix: "s1b#{i}",
          collection: coll,
        )
      end
      coll.docs = books.compact
      site = create_site(@site_config_base.dup, { 'books' => coll.docs })
      [books, site]
    end

    def setup_unparseable_book_number_scenario
      coll = MockCollection.new([], 'books')
      s1b3 = create_book(
        title: 'S1B3',
        series: 'Series 1',
        book_num: 3,
        authors: ['Auth'],
        date_offset_days: 8,
        url_suffix: 's1b3',
        collection: coll,
      )
      s1b1 = create_book(
        title: 'S1B1',
        series: 'Series 1',
        book_num: 1,
        authors: ['Auth'],
        date_offset_days: 10,
        url_suffix: 's1b1',
        collection: coll,
      )
      s1b2 = create_book(
        title: 'S1B2',
        series: 'Series 1',
        book_num: 2,
        authors: ['Auth'],
        date_offset_days: 9,
        url_suffix: 's1b2',
        collection: coll,
      )
      bad_num = create_book(
        title: 'Current BadNum',
        series: 'Series 1',
        book_num: 'xyz',
        authors: ['Auth'],
        date_offset_days: 1,
        url_suffix: 'curr_bad_num',
        collection: coll,
      )
      coll.docs = [s1b1, s1b2, s1b3, bad_num, @recent_unrelated_book1].compact

      site = create_site(@site_config_base.dup, { 'books' => coll.docs })
      context = create_context({}, { site: site, page: bad_num })
      [coll, s1b1, s1b2, s1b3, bad_num, site, context]
    end

    def setup_zero_series_books_scenario
      coll = MockCollection.new([], 'books')
      curr = create_book(
        title: 'Current In SeriesX',
        series: 'Series X',
        book_num: 1,
        authors: ['Author X'],
        date_offset_days: 0,
        url_suffix: 'curr_sx',
        collection: coll,
      )
      coll.docs = [
        curr,
        @author_x_book1_old,
        @author_x_book2_recent,
        @recent_unrelated_book1,
        @recent_unrelated_book2,
        @recent_unrelated_book3,
      ].compact
      site = create_site(@site_config_base.dup, { 'books' => coll.docs })
      context = create_context({}, { site: site, page: curr })
      [coll, curr, site, context]
    end

    def setup_archived_reviews_scenario
      coll = MockCollection.new([], 'books')
      curr = create_book(
        title: 'Current Book',
        series: 'Series A',
        book_num: 1,
        authors: ['Auth'],
        date_offset_days: 10,
        url_suffix: 'current',
        collection: coll,
      )
      canon = create_book(
        title: 'Related Canonical',
        series: 'Series A',
        book_num: 2,
        authors: ['Auth'],
        date_offset_days: 9,
        url_suffix: 'related_canon',
        collection: coll,
      )
      arch = create_book(
        title: 'Related Archived',
        series: 'Series A',
        book_num: 3,
        authors: ['Auth'],
        date_offset_days: 8,
        url_suffix: 'related_archive',
        collection: coll,
        extra_fm: { 'canonical_url' => '/some/path' },
      )
      coll.docs = [curr, canon, arch].compact
      site = create_site(@site_config_base.dup, { 'books' => coll.docs })
      context = create_context({}, { site: site, page: curr })
      [curr, canon, arch, site, context]
    end

    def setup_external_canonical_scenario
      coll = MockCollection.new([], 'books')
      curr = create_book(
        title: 'Current Book',
        series: 'Series A',
        book_num: 1,
        authors: ['Auth'],
        date_offset_days: 10,
        url_suffix: 'current',
        collection: coll,
      )
      ext = create_book(
        title: 'Related External',
        series: 'Series A',
        book_num: 2,
        authors: ['Auth'],
        date_offset_days: 5,
        url_suffix: 'related_ext',
        collection: coll,
        extra_fm: { 'canonical_url' => 'http://some.other.site/path' },
      )
      coll.docs = [curr, ext].compact
      site = create_site(@site_config_base.dup, { 'books' => coll.docs })
      context = create_context({}, { site: site, page: curr })
      [curr, ext, site, context]
    end
  end
end
