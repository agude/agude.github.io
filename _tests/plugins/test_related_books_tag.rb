# frozen_string_literal: true

# _tests/plugins/test_related_books_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/related_books_tag'

class TestRelatedBooksTag < Minitest::Test
  DEFAULT_MAX_BOOKS = Jekyll::RelatedBooksTag::DEFAULT_MAX_BOOKS

  def setup
    @site_config_base = {
      'url' => 'http://example.com',
      'plugin_logging' => { 'RELATED_BOOKS' => true, 'RELATED_BOOKS_SERIES' => true },
      'plugin_log_level' => 'debug'
    }
    @test_time_now = Time.parse('2024-03-15 10:00:00 EST')

    setup_generic_books
    setup_silent_logger
  end

  def setup_generic_books
    @author_x_book1_old = create_book_obj('AuthorX Book1 (Old)', nil, nil, ['Author X'], 20, 'ax_b1_old')
    @author_x_book2_recent = create_book_obj('AuthorX Book2 (Recent)', nil, nil, ['Author X'], 5, 'ax_b2_recent')
    @author_y_book1_recent = create_book_obj('AuthorY Book1 (Recent)', nil, nil, ['Author Y'], 4, 'ay_b1_recent')
    @recent_unrelated_book1 = create_book_obj('Recent Unrelated 1', nil, nil, ['Author Z'], 1, 'ru1')
    @recent_unrelated_book2 = create_book_obj('Recent Unrelated 2', nil, nil, ['Author W'], 2, 'ru2')
    @recent_unrelated_book3 = create_book_obj('Recent Unrelated 3', nil, nil, ['Author V'], 3, 'ru3')
    @unpublished_book_generic = create_book_obj('Unpublished Book Generic', 'Series Misc', 1, ['Author X'], 5,
                                                'unpub_gen', published: false)
    @future_dated_book_generic = create_book_obj('Future Book Generic', 'Series Misc', 1, ['Author X'], -5,
                                                 'future_gen')
  end

  def setup_silent_logger
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end
      def logger.error(topic, message); end
      def logger.info(topic, message); end
      def logger.debug(topic, message); end
    end
  end

  def create_book_obj(title, series, book_num, authors_input, date_offset_days, url_suffix, published: true,
                      collection_mock_for_doc_creation: nil, extra_fm: {})
    authors_data = normalize_authors(authors_input)
    front_matter = {
      'title' => title, 'series' => series, 'book_number' => book_num,
      'book_authors' => authors_data, 'published' => published,
      'date' => @test_time_now - (60 * 60 * 24 * date_offset_days),
      'image' => "/images/book_#{url_suffix}.jpg",
      'excerpt_output_override' => "#{title} excerpt."
    }.merge(extra_fm)
    create_doc(front_matter, "/books/#{url_suffix}.html", "Content for #{title}", nil, collection_mock_for_doc_creation)
  end

  def normalize_authors(authors_input)
    if authors_input.is_a?(Array)
      authors_input.map(&:to_s)
    elsif authors_input.nil?
      []
    else
      [authors_input.to_s]
    end
  end

  def render_tag(context)
    output = ''
    Time.stub :now, @test_time_now do
      Jekyll.stub :logger, @silent_logger_stub do
        BookCardUtils.stub :render, ->(book_obj, _ctx) { "<!-- Card for: #{book_obj.data['title']} -->\n" } do
          output = Liquid::Template.parse('{% related_books %}').render!(context)
        end
      end
    end
    output
  end

  def extract_rendered_titles(output_html)
    output_html.scan(/<!-- Card for: (.*?) -->/).flatten
  end

  # --- Prerequisite Tests ---
  def test_logs_error_if_prerequisites_missing
    verify_missing_page_log
    verify_missing_collection_log
  end

  def verify_missing_page_log
    site = create_site(@site_config_base.dup)
    context = create_context({}, { site: site })
    mock = Minitest::Mock.new
    mock.expect(:error, nil) { |_p, m| m.include?('Missing prerequisites: page object') }

    output = ''
    Time.stub :now, @test_time_now do
      Jekyll.stub :logger, mock do
        output = Liquid::Template.parse('{% related_books %}').render!(context)
      end
    end
    assert_match %r{<!-- \[ERROR\] RELATED_BOOKS_FAILURE: Reason='Missing prerequisites: page object.*PageURL='N/A'.* -->},
      output
    mock.verify
  end

  def verify_missing_collection_log
    site = create_site(@site_config_base.dup, {})
    page = create_doc({ 'title' => 'Test', 'url' => '/test.html', 'path' => 'test.md' }, '/test.html')
    context = create_context({}, { site: site, page: page })
    mock = Minitest::Mock.new
    mock.expect(:error, nil) { |_p, m| m.include?('Missing prerequisites: site.collections[&#39;books&#39;]') }

    output = ''
    Time.stub :now, @test_time_now do
      Jekyll.stub :logger, mock do
        output = Liquid::Template.parse('{% related_books %}').render!(context)
      end
    end
    assert_match(/<!-- \[ERROR\] RELATED_BOOKS_FAILURE: Reason='Missing prerequisites: site\.collections\[&#39;books&#39;\]\.' .*-->/,
                 output)
    mock.verify
  end

  # --- New Series Logic Tests ---
  def test_series_current_is_book1_of_4_shows_2_3_4_sorted
    books, site = setup_series_books(4)
    context = create_context({}, { site: site, page: books[0] })

    output = render_tag(context)
    expected = [books[1].data['title'], books[2].data['title'], books[3].data['title']]
    assert_equal expected, extract_rendered_titles(output)
  end

  def test_series_current_is_book2_of_4_shows_1_3_4_sorted
    books, site = setup_series_books(4)
    context = create_context({}, { site: site, page: books[1] })

    output = render_tag(context)
    expected = [books[0].data['title'], books[2].data['title'], books[3].data['title']]
    assert_equal expected, extract_rendered_titles(output)
  end

  def test_series_current_is_book4_of_4_shows_1_2_3_sorted
    books, site = setup_series_books(4)
    context = create_context({}, { site: site, page: books[3] })

    output = render_tag(context)
    expected = [books[0].data['title'], books[1].data['title'], books[2].data['title']]
    assert_equal expected, extract_rendered_titles(output)
  end

  def test_series_current_is_book5_of_10_shows_3_4_6_sorted
    books_collection = MockCollection.new([], 'books')
    series_books = (1..10).map do |i|
      create_book_obj("S1B#{i}", 'Series 1', i, ['Auth'], 20 - i, "s1b#{i}",
                      collection_mock_for_doc_creation: books_collection)
    end
    books_collection.docs = series_books.compact
    site = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
    context = create_context({}, { site: site, page: series_books[4] })

    output = render_tag(context)
    expected = [series_books[2].data['title'], series_books[3].data['title'], series_books[5].data['title']]
    assert_equal expected, extract_rendered_titles(output)
  end

  def test_series_current_book_number_unparseable_falls_back_to_all_series_sorted_numerically
    coll = MockCollection.new([], 'books')
    s1b3 = create_book_obj('S1B3', 'Series 1', 3, ['Auth'], 8, 's1b3', collection_mock_for_doc_creation: coll)
    s1b1 = create_book_obj('S1B1', 'Series 1', 1, ['Auth'], 10, 's1b1', collection_mock_for_doc_creation: coll)
    s1b2 = create_book_obj('S1B2', 'Series 1', 2, ['Auth'], 9, 's1b2', collection_mock_for_doc_creation: coll)
    bad_num = create_book_obj('Current BadNum', 'Series 1', 'xyz', ['Auth'], 1, 'curr_bad_num',
                              collection_mock_for_doc_creation: coll)
    coll.docs = [s1b1, s1b2, s1b3, bad_num, @recent_unrelated_book1].compact

    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: bad_num })

    output = render_tag(context)
    assert_equal [s1b1.data['title'], s1b2.data['title'], s1b3.data['title']], extract_rendered_titles(output)
    assert_match %r{Reason='Current page has unparseable book_number \(&#39;xyz&#39;\)\. Using all series books sorted by number\.'},
      output
  end

  # --- Tests for Series Providing < @max_books ---
  def test_series_provides_zero_books_author_and_recent_fill
    coll = MockCollection.new([], 'books')
    curr = create_book_obj('Current In SeriesX', 'Series X', 1, ['Author X'], 0, 'curr_sx',
                           collection_mock_for_doc_creation: coll)
    coll.docs = [curr, @author_x_book1_old, @author_x_book2_recent, @recent_unrelated_book1,
                 @recent_unrelated_book2, @recent_unrelated_book3].compact
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: curr })

    output = render_tag(context)
    expected = [@author_x_book2_recent.data['title'], @author_x_book1_old.data['title'],
                @recent_unrelated_book1.data['title']]
    assert_equal expected, extract_rendered_titles(output)
  end

  def test_series_provides_one_book_author_and_recent_fill_remaining_two
    coll = MockCollection.new([], 'books')
    curr = create_book_obj('Current S1B1', 'Series Y', 1, ['Author Y'], 0, 'curr_s1b1',
                           collection_mock_for_doc_creation: coll)
    s1b2 = create_book_obj('S1B2', 'Series Y', 2, ['Author Y'], 5, 's1b2', collection_mock_for_doc_creation: coll)
    other_ay = create_book_obj('Other AY Book Recent', nil, nil, ['Author Y'], 3, 'ay_other_rec',
                               collection_mock_for_doc_creation: coll)
    coll.docs = [curr, s1b2, other_ay, @recent_unrelated_book1, @recent_unrelated_book2].compact
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: curr })

    output = render_tag(context)
    expected = [s1b2.data['title'], other_ay.data['title'], @recent_unrelated_book1.data['title']]
    assert_equal expected, extract_rendered_titles(output)
  end

  def test_series_provides_two_books_author_and_recent_fill_remaining_one
    coll = MockCollection.new([], 'books')
    curr = create_book_obj('Current S1B1', 'Series Z', 1, ['Author Z'], 0, 'curr_s1b1',
                           collection_mock_for_doc_creation: coll)
    s1b2 = create_book_obj('S1B2', 'Series Z', 2, ['Author Z'], 10, 's1b2', collection_mock_for_doc_creation: coll)
    s1b3 = create_book_obj('S1B3', 'Series Z', 3, ['Author Z'], 5, 's1b3', collection_mock_for_doc_creation: coll)
    coll.docs = [curr, s1b2, s1b3, @recent_unrelated_book1, @author_x_book2_recent].compact
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: curr })

    output = render_tag(context)
    expected = [s1b2.data['title'], s1b3.data['title'], @recent_unrelated_book1.data['title']]
    assert_equal expected, extract_rendered_titles(output)
  end

  # --- Author and Recent Fallback Tests ---
  def test_multi_author_current_page_uses_either_author_for_fallback
    coll = MockCollection.new([], 'books')
    curr = create_book_obj('Current Multi-Author', 'UniqueSeries', 1, ['Author A', 'Author B'], 0, 'curr_multi',
                           collection_mock_for_doc_creation: coll)
    auth_a = create_book_obj('AuthorA Solo Book', nil, nil, ['Author A'], 2, 'aa_solo',
                             collection_mock_for_doc_creation: coll)
    auth_b = create_book_obj('AuthorB Solo Book', nil, nil, ['Author B'], 4, 'ab_solo',
                             collection_mock_for_doc_creation: coll)
    recent_z = create_book_obj('Recent By Z', nil, nil, ['Author Z'], 1, 'ru_z', collection_mock_for_doc_creation: coll)
    coll.docs = [curr, auth_a, auth_b, recent_z].compact
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: curr })

    output = render_tag(context)
    expected = [auth_a.data['title'], auth_b.data['title'], recent_z.data['title']]
    assert_equal expected, extract_rendered_titles(output)
  end

  def test_recent_fallback_when_series_and_author_provide_less_than_max
    coll = MockCollection.new([], 'books')
    curr = create_book_obj('Current S1B1', 'Series Beta', 1, ['Author B'], 10, 'curr_s1b1',
                           collection_mock_for_doc_creation: coll)
    coll.docs = [curr, @recent_unrelated_book1, @recent_unrelated_book2, @recent_unrelated_book3,
                 @unpublished_book_generic].compact
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: curr })

    output = render_tag(context)
    expected = [@recent_unrelated_book1.data['title'], @recent_unrelated_book2.data['title'],
                @recent_unrelated_book3.data['title']]
    assert_equal expected, extract_rendered_titles(output)
  end

  # --- General Behavior Tests ---
  def test_world_of_trouble_scenario_with_new_series_logic
    coll = MockCollection.new([], 'books')
    series = 'The Last Policeman'
    authors = ['Ben H. Winters']

    wot = create_book_obj('World of Trouble', series, 3, authors, 0, 'wot', collection_mock_for_doc_creation: coll)
    cc = create_book_obj('Countdown City', series, 2, authors, 300, 'cc', collection_mock_for_doc_creation: coll)
    tlp = create_book_obj('The Last Policeman', series, 1, authors, 365, 'tlp', collection_mock_for_doc_creation: coll)
    fill = create_book_obj('Recent Unrelated Fill', nil, nil, ['Another Author'], 5, 'ru_fill',
                           collection_mock_for_doc_creation: coll)

    coll.docs = [wot, tlp, cc, fill].compact
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: wot })

    output = render_tag(context)
    expected = [tlp.data['title'], cc.data['title'], fill.data['title']]
    assert_equal DEFAULT_MAX_BOOKS, extract_rendered_titles(output).count
    assert_equal expected, extract_rendered_titles(output)
  end

  def test_returns_empty_string_if_no_valid_related_books
    coll = MockCollection.new([], 'books')
    curr = create_book_obj('Alone Again', nil, nil, ['Solo Author'], 0, 'alone_again',
                           collection_mock_for_doc_creation: coll)
    coll.docs = [curr, @unpublished_book_generic, @future_dated_book_generic].compact

    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: curr })
    output = render_tag(context)
    assert_equal '', output.strip
  end

  def test_html_structure_is_correct_when_books_found
    coll = MockCollection.new([], 'books')
    s1b1 = create_book_obj('S1B1', 'Series 1', 1, ['Auth'], 10, 's1b1', collection_mock_for_doc_creation: coll)
    s1b2 = create_book_obj('S1B2', 'Series 1', 2, ['Auth'], 9, 's1b2', collection_mock_for_doc_creation: coll)
    coll.docs = [s1b1, s1b2].compact
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: s1b1 })

    output = render_tag(context)
    refute_empty output.strip, 'Output should not be empty'
    assert_match(/<aside class="related">/, output)
    assert_match %r{<h2>Related Books</h2>}, output
    assert_match(/<div class="card-grid">/, output)
    assert_equal 1, output.scan('<!-- Card for:').count
    assert_match %r{</div>\s*</aside>}m, output
  end

  def test_excludes_archived_reviews_from_recommendations
    coll = MockCollection.new([], 'books')
    curr = create_book_obj('Current Book', 'Series A', 1, ['Auth'], 10, 'current',
                           collection_mock_for_doc_creation: coll)
    canon = create_book_obj('Related Canonical', 'Series A', 2, ['Auth'], 9, 'related_canon',
                            collection_mock_for_doc_creation: coll)
    arch = create_book_obj('Related Archived', 'Series A', 3, ['Auth'], 8, 'related_archive',
                           collection_mock_for_doc_creation: coll, extra_fm: { 'canonical_url' => '/some/path' })
    coll.docs = [curr, canon, arch].compact
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: curr })

    output = render_tag(context)
    titles = extract_rendered_titles(output)

    assert_includes titles, 'Related Canonical'
    refute_includes titles, 'Related Archived'
  end

  def test_includes_books_with_external_canonical_url
    coll = MockCollection.new([], 'books')
    curr = create_book_obj('Current Book', 'Series A', 1, ['Auth'], 10, 'current',
                           collection_mock_for_doc_creation: coll)
    ext = create_book_obj('Related External', 'Series A', 2, ['Auth'], 5, 'related_ext',
                          collection_mock_for_doc_creation: coll,
                          extra_fm: { 'canonical_url' => 'http://some.other.site/path' })
    coll.docs = [curr, ext].compact
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: curr })

    output = render_tag(context)
    assert_includes extract_rendered_titles(output), 'Related External'
  end

  private

  def setup_series_books(count)
    coll = MockCollection.new([], 'books')
    books = (1..count).map do |i|
      create_book_obj("S1B#{i}", 'Series 1', i, ['Auth'], 10 - i, "s1b#{i}", collection_mock_for_doc_creation: coll)
    end
    coll.docs = books.compact
    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    [books, site]
  end
end
