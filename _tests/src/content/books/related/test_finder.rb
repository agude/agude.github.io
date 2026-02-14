# frozen_string_literal: true

# _tests/plugins/logic/related_books/test_finder.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/related/finder'

# Tests for Jekyll::Books::Related::Finder.
#
# Verifies that the Finder correctly locates and ranks related books based on
# series, author, and recency.
class TestRelatedBooksFinder < Minitest::Test
  DEFAULT_MAX_BOOKS = 3

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
      @silent_logger_stub = create_silent_logger
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

    private

    def create_silent_logger
      Object.new.tap do |logger|
        def logger.warn(topic, message); end

        def logger.error(topic, message); end

        def logger.info(topic, message); end

        def logger.debug(topic, message); end
      end
    end
  end
end
