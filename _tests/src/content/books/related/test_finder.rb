# frozen_string_literal: true

require_relative '../../../../support/related_book_finder_test_case'
require 'tmpdir'

# Prerequisites, filtering, series, and result limits.
class TestRelatedBooksFinder < RelatedBookFinderTestCase
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

  def test_series_neighbors_alternate_then_exhaust_succeeding_books
    books, site = @helper.setup_series_books(8)
    finder = Jekyll::Books::Related::Finder.new(site, books[5], 6)

    result = Time.stub(:now, @test_time_now) { finder.find }

    assert_equal [books[1], books[2], books[3], books[4], books[6], books[7]].map(&:url),
                 result[:books].map(&:url)
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
    assert_match(/Missing prerequisites: page.url/, result[:logs])
  end

  def test_finds_related_book_with_real_jekyll_document
    Dir.mktmpdir do |source|
      path = File.join(source, 'current.md')
      File.write(path, "---\ntitle: Current\nbook_authors: [Author A]\npermalink: /books/current.html\n---\n")
      related = create_doc(
        { 'title' => 'Related', 'book_authors' => ['Author A'], 'date' => @test_time_now - 43_200 },
        '/books/related.html',
      )
      site = create_site(@site_config_base.merge('source' => source), { 'books' => [related] })
      document_site = Jekyll::Site.new(Jekyll.configuration('source' => source, 'config' => []))
      collection = Jekyll::Collection.new(document_site, 'books')
      page = Jekyll::Document.new(path, site: document_site, collection: collection)
      page.read

      assert_nil page['url']
      assert_equal '/books/current.html', page.url
      result = Time.stub(:now, @test_time_now) { Jekyll::Books::Related::Finder.new(site, page).find }

      assert_equal ['/books/related.html'], result[:books].map(&:url)
    end
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
end
