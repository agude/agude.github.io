# _tests/plugins/test_related_books_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/related_books_tag'

class TestRelatedBooksTag < Minitest::Test
  DEFAULT_MAX_BOOKS = Jekyll::RelatedBooksTag::DEFAULT_MAX_BOOKS

  def setup
    @site_config_base = {
      'url' => 'http://example.com',
      'plugin_logging' => { 'RELATED_BOOKS' => true, 'RELATED_BOOKS_SERIES' => true }, # Enable logging
      'plugin_log_level' => 'debug'
    }
    @test_time_now = Time.parse("2024-03-15 10:00:00 EST")

    def create_book_obj(title, series, book_num, authors_input, date_offset_days, url_suffix, published = true, collection_mock_for_doc_creation = nil, extra_fm = {})
      authors_data = if authors_input.is_a?(Array)
                       authors_input.map(&:to_s)
                     elsif authors_input.nil?
                       []
                     else
                       [authors_input.to_s]
                     end
      front_matter = {
        'title' => title, 'series' => series, 'book_number' => book_num,
        'book_authors' => authors_data,
        'published' => published,
        'date' => @test_time_now - (60 * 60 * 24 * date_offset_days), # Lower offset = more recent
        'image' => "/images/book_#{url_suffix}.jpg",
        'excerpt_output_override' => "#{title} excerpt."
      }.merge(extra_fm)
      create_doc(
        front_matter,
        "/books/#{url_suffix}.html", "Content for #{title}", nil, collection_mock_for_doc_creation
      )
    end

    # Generic books for fallback testing
    @author_X_book1_old = create_book_obj('AuthorX Book1 (Old)', nil, nil, ['Author X'], 20, 'ax_b1_old')
    @author_X_book2_recent = create_book_obj('AuthorX Book2 (Recent)', nil, nil, ['Author X'], 5, 'ax_b2_recent')

    @author_Y_book1_recent = create_book_obj('AuthorY Book1 (Recent)', nil, nil, ['Author Y'], 4, 'ay_b1_recent')

    @recent_unrelated_book1 = create_book_obj('Recent Unrelated 1', nil, nil, ['Author Z'], 1, 'ru1')
    @recent_unrelated_book2 = create_book_obj('Recent Unrelated 2', nil, nil, ['Author W'], 2, 'ru2')
    @recent_unrelated_book3 = create_book_obj('Recent Unrelated 3', nil, nil, ['Author V'], 3, 'ru3')


    @unpublished_book_generic = create_book_obj('Unpublished Book Generic', 'Series Misc', 1, ['Author X'], 5, 'unpub_gen', false)
    @future_dated_book_generic = create_book_obj('Future Book Generic', 'Series Misc', 1, ['Author X'], -5, 'future_gen')


    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
    end
  end

  def render_tag(context)
    output = ""
    Time.stub :now, @test_time_now do
      Jekyll.stub :logger, @silent_logger_stub do
        BookCardUtils.stub :render, ->(book_obj, _ctx) { "<!-- Card for: #{book_obj.data['title']} -->\n" } do
          output = Liquid::Template.parse("{% related_books %}").render!(context)
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
    site_for_test = create_site(@site_config_base.dup)
    bad_context_no_page = create_context({}, { site: site_for_test })
    mock_logger_page_missing = Minitest::Mock.new
    mock_logger_page_missing.expect(:error, nil) { |p, m| m.include?("Missing prerequisites: page object") }

    output_page_missing = ""
    Time.stub :now, @test_time_now do
      Jekyll.stub :logger, mock_logger_page_missing do
        output_page_missing = Liquid::Template.parse("{% related_books %}").render!(bad_context_no_page)
      end
    end
    assert_match %r{<!-- \[ERROR\] RELATED_BOOKS_FAILURE: Reason='Missing prerequisites: page object.*PageURL='N/A'.* -->}, output_page_missing
    mock_logger_page_missing.verify

    site_no_books_coll = create_site(@site_config_base.dup, {})
    current_page_mock = create_doc({'title' => 'Test', 'url' => '/test.html', 'path' => 'test.md'}, '/test.html')
    bad_context_no_books = create_context({}, { site: site_no_books_coll, page: current_page_mock })
    mock_logger_coll_missing = Minitest::Mock.new
    # Corrected expectation for HTML escaped single quotes
    mock_logger_coll_missing.expect(:error, nil) { |p, m| m.include?("Missing prerequisites: site.collections[&#39;books&#39;]") }

    output_coll_missing = ""
    Time.stub :now, @test_time_now do
      Jekyll.stub :logger, mock_logger_coll_missing do
        output_coll_missing = Liquid::Template.parse("{% related_books %}").render!(bad_context_no_books)
      end
    end
    assert_match %r{<!-- \[ERROR\] RELATED_BOOKS_FAILURE: Reason='Missing prerequisites: site\.collections\[&#39;books&#39;\]\.' .*-->}, output_coll_missing
    mock_logger_coll_missing.verify
  end

  # --- New Series Logic Tests ---
  def test_series_current_is_book1_of_4_shows_2_3_4_sorted
    books_collection = MockCollection.new([], 'books')
    s1b1 = create_book_obj('S1B1', 'Series 1', 1, ['Auth'], 10, 's1b1', true, books_collection)
    s1b2 = create_book_obj('S1B2', 'Series 1', 2, ['Auth'], 9,  's1b2', true, books_collection)
    s1b3 = create_book_obj('S1B3', 'Series 1', 3, ['Auth'], 8,  's1b3', true, books_collection)
    s1b4 = create_book_obj('S1B4', 'Series 1', 4, ['Auth'], 7,  's1b4', true, books_collection)
    books_collection.docs = [s1b1, s1b2, s1b3, s1b4].compact
    site = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
    context = create_context({}, { site: site, page: s1b1 })

    output = render_tag(context)
    rendered_titles = extract_rendered_titles(output)
    expected_titles = [s1b2.data['title'], s1b3.data['title'], s1b4.data['title']]
    assert_equal expected_titles, rendered_titles
  end

  def test_series_current_is_book2_of_4_shows_1_3_4_sorted
    books_collection = MockCollection.new([], 'books')
    s1b1 = create_book_obj('S1B1', 'Series 1', 1, ['Auth'], 10, 's1b1', true, books_collection)
    s1b2 = create_book_obj('S1B2', 'Series 1', 2, ['Auth'], 9,  's1b2', true, books_collection)
    s1b3 = create_book_obj('S1B3', 'Series 1', 3, ['Auth'], 8,  's1b3', true, books_collection)
    s1b4 = create_book_obj('S1B4', 'Series 1', 4, ['Auth'], 7,  's1b4', true, books_collection)
    books_collection.docs = [s1b1, s1b2, s1b3, s1b4].compact
    site = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
    context = create_context({}, { site: site, page: s1b2 })

    output = render_tag(context)
    rendered_titles = extract_rendered_titles(output)
    expected_titles = [s1b1.data['title'], s1b3.data['title'], s1b4.data['title']]
    assert_equal expected_titles, rendered_titles
  end

  def test_series_current_is_book4_of_4_shows_1_2_3_sorted
    books_collection = MockCollection.new([], 'books')
    s1b1 = create_book_obj('S1B1', 'Series 1', 1, ['Auth'], 10, 's1b1', true, books_collection)
    s1b2 = create_book_obj('S1B2', 'Series 1', 2, ['Auth'], 9,  's1b2', true, books_collection)
    s1b3 = create_book_obj('S1B3', 'Series 1', 3, ['Auth'], 8,  's1b3', true, books_collection)
    s1b4 = create_book_obj('S1B4', 'Series 1', 4, ['Auth'], 7,  's1b4', true, books_collection)
    books_collection.docs = [s1b1, s1b2, s1b3, s1b4].compact
    site = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
    context = create_context({}, { site: site, page: s1b4 })

    output = render_tag(context)
    rendered_titles = extract_rendered_titles(output)
    expected_titles = [s1b1.data['title'], s1b2.data['title'], s1b3.data['title']]
    assert_equal expected_titles, rendered_titles
  end

  def test_series_current_is_book5_of_10_shows_3_4_6_sorted
    books_collection = MockCollection.new([], 'books')
    series_books = (1..10).map do |i|
      create_book_obj("S1B#{i}", 'Series 1', i, ['Auth'], 20 - i, "s1b#{i}", true, books_collection)
    end
    books_collection.docs = series_books.compact
    site = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
    current_page = series_books[4]
    context = create_context({}, { site: site, page: current_page })

    output = render_tag(context)
    rendered_titles = extract_rendered_titles(output)
    expected_titles = [
      series_books[2].data['title'],
      series_books[3].data['title'],
      series_books[5].data['title']
    ]
    assert_equal expected_titles, rendered_titles, "Books not in correct sorted order for 'Book 5 of 10'"
  end

  def test_series_current_book_number_unparseable_falls_back_to_all_series_sorted_numerically
    books_collection = MockCollection.new([], 'books')
    s1b3 = create_book_obj('S1B3', 'Series 1', 3, ['Auth'], 8,  's1b3', true, books_collection)
    s1b1 = create_book_obj('S1B1', 'Series 1', 1, ['Auth'], 10, 's1b1', true, books_collection)
    s1b2 = create_book_obj('S1B2', 'Series 1', 2, ['Auth'], 9,  's1b2', true, books_collection)
    current_page_bad_num = create_book_obj('Current BadNum', 'Series 1', 'xyz', ['Auth'], 1, 'curr_bad_num', true, books_collection)
    books_collection.docs = [s1b1, s1b2, s1b3, current_page_bad_num, @recent_unrelated_book1].compact

    site = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
    context = create_context({}, { site: site, page: current_page_bad_num })

    output = render_tag(context)
    rendered_titles = extract_rendered_titles(output)
    expected_titles = [s1b1.data['title'], s1b2.data['title'], s1b3.data['title']]
    assert_equal expected_titles, rendered_titles
    # Corrected SourcePage expectation
    assert_match %r{<!-- \[INFO\] RELATED_BOOKS_SERIES_FAILURE: Reason='Current page has unparseable book_number \(&#39;xyz&#39;\)\. Using all series books sorted by number\.' PageURL='\/books\/curr_bad_num\.html' Series='Series 1' SourcePage='books\/curr_bad_num\.html' -->}, output
  end

  # --- Tests for Series Providing < @max_books ---
  def test_series_provides_zero_books_author_and_recent_fill
    books_collection = MockCollection.new([], 'books')
    current_page = create_book_obj('Current In SeriesX', 'Series X', 1, ['Author X'], 0, 'curr_sx', true, books_collection)
    books_collection.docs = [current_page, @author_X_book1_old, @author_X_book2_recent, @recent_unrelated_book1, @recent_unrelated_book2, @recent_unrelated_book3].compact
    site = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
    context = create_context({}, { site: site, page: current_page })

    output = render_tag(context)
    rendered_titles = extract_rendered_titles(output)
    expected_titles = [
      @author_X_book2_recent.data['title'],
      @author_X_book1_old.data['title'],
      @recent_unrelated_book1.data['title']
    ]
    assert_equal expected_titles, rendered_titles
  end

  def test_series_provides_one_book_author_and_recent_fill_remaining_two
    books_collection = MockCollection.new([], 'books')
    current_page = create_book_obj('Current S1B1', 'Series Y', 1, ['Author Y'], 0, 'curr_s1b1', true, books_collection)
    s1b2 = create_book_obj('S1B2', 'Series Y', 2, ['Author Y'], 5, 's1b2', true, books_collection)
    author_Y_book_other_recent = create_book_obj('Other AY Book Recent', nil, nil, ['Author Y'], 3, 'ay_other_rec', true, books_collection)
    books_collection.docs = [current_page, s1b2, author_Y_book_other_recent, @recent_unrelated_book1, @recent_unrelated_book2].compact
    site = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
    context = create_context({}, { site: site, page: current_page })

    output = render_tag(context)
    rendered_titles = extract_rendered_titles(output)
    expected_titles = [s1b2.data['title'], author_Y_book_other_recent.data['title'], @recent_unrelated_book1.data['title']]
    assert_equal expected_titles, rendered_titles
  end

  def test_series_provides_two_books_author_and_recent_fill_remaining_one
    books_collection = MockCollection.new([], 'books')
    current_page = create_book_obj('Current S1B1', 'Series Z', 1, ['Author Z'], 0, 'curr_s1b1', true, books_collection)
    s1b2 = create_book_obj('S1B2', 'Series Z', 2, ['Author Z'], 10, 's1b2', true, books_collection)
    s1b3 = create_book_obj('S1B3', 'Series Z', 3, ['Author Z'], 5, 's1b3', true, books_collection)
    books_collection.docs = [current_page, s1b2, s1b3, @recent_unrelated_book1, @author_X_book2_recent].compact # @recent_unrelated_book1 is by Author Z
    site = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
    context = create_context({}, { site: site, page: current_page })

    output = render_tag(context)
    rendered_titles = extract_rendered_titles(output)
    expected_titles = [s1b2.data['title'], s1b3.data['title'], @recent_unrelated_book1.data['title']]
    assert_equal expected_titles, rendered_titles
  end

  # --- Author and Recent Fallback Tests ---
  def test_multi_author_current_page_uses_either_author_for_fallback
    books_collection = MockCollection.new([], 'books')
    current_page_multi = create_book_obj('Current Multi-Author', 'UniqueSeries', 1, ['Author A', 'Author B'], 0, 'curr_multi', true, books_collection)
    author_A_book = create_book_obj('AuthorA Solo Book', nil, nil, ['Author A'], 2, 'aa_solo', true, books_collection)
    author_B_book = create_book_obj('AuthorB Solo Book', nil, nil, ['Author B'], 4, 'ab_solo', true, books_collection)
    recent_unrelated_by_Z = create_book_obj('Recent By Z', nil, nil, ['Author Z'], 1, 'ru_z', true, books_collection)
    books_collection.docs = [current_page_multi, author_A_book, author_B_book, recent_unrelated_by_Z].compact
    site = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
    context = create_context({}, { site: site, page: current_page_multi })

    output = render_tag(context)
    rendered_titles = extract_rendered_titles(output)
    expected_titles = [author_A_book.data['title'], author_B_book.data['title'], recent_unrelated_by_Z.data['title']]
    assert_equal expected_titles, rendered_titles
  end

  def test_recent_fallback_when_series_and_author_provide_less_than_max
    books_collection = MockCollection.new([], 'books')
    current_page = create_book_obj('Current S1B1', 'Series Beta', 1, ['Author B'], 10, 'curr_s1b1', true, books_collection)
    books_collection.docs = [current_page, @recent_unrelated_book1, @recent_unrelated_book2, @recent_unrelated_book3, @unpublished_book_generic].compact
    site = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
    context = create_context({}, { site: site, page: current_page })

    output = render_tag(context)
    rendered_titles = extract_rendered_titles(output)
    expected_titles = [@recent_unrelated_book1.data['title'], @recent_unrelated_book2.data['title'], @recent_unrelated_book3.data['title']]
    assert_equal expected_titles, rendered_titles
  end

  # --- General Behavior Tests ---
  def test_world_of_trouble_scenario_with_new_series_logic
    books_collection = MockCollection.new([], 'books')
    tlp_series_name = "The Last Policeman"
    bhw_authors_array = ["Ben H. Winters"]

    wot_book = create_book_obj('World of Trouble', tlp_series_name, 3, bhw_authors_array, 0, 'wot', true, books_collection)
    cc_book  = create_book_obj('Countdown City', tlp_series_name, 2, bhw_authors_array, 300, 'cc', true, books_collection)
    tlp_book = create_book_obj('The Last Policeman', tlp_series_name, 1, bhw_authors_array, 365, 'tlp', true, books_collection)
    recent_unrelated_fill = create_book_obj('Recent Unrelated Fill', nil, nil, ['Another Author'], 5, 'ru_fill', true, books_collection)

    books_collection.docs = [wot_book, tlp_book, cc_book, recent_unrelated_fill].compact
    site_for_wot = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
    context_for_wot = create_context({}, { site: site_for_wot, page: wot_book })

    output = render_tag(context_for_wot)
    rendered_titles = extract_rendered_titles(output)
    expected_titles = [tlp_book.data['title'], cc_book.data['title'], recent_unrelated_fill.data['title']]
    assert_equal DEFAULT_MAX_BOOKS, rendered_titles.count
    assert_equal expected_titles, rendered_titles
  end

  def test_returns_empty_string_if_no_valid_related_books
    books_collection = MockCollection.new([], 'books')
    current_page_alone = create_book_obj('Alone Again', nil, nil, ['Solo Author'], 0, 'alone_again', true, books_collection)
    books_collection.docs = [current_page_alone, @unpublished_book_generic, @future_dated_book_generic].compact

    site_alone = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
    context_alone = create_context({}, { site: site_alone, page: current_page_alone })
    output = render_tag(context_alone)
    assert_equal "", output.strip
  end

  def test_html_structure_is_correct_when_books_found
    books_collection = MockCollection.new([], 'books')
    s1b1 = create_book_obj('S1B1', 'Series 1', 1, ['Auth'], 10, 's1b1', true, books_collection)
    s1b2 = create_book_obj('S1B2', 'Series 1', 2, ['Auth'], 9,  's1b2', true, books_collection)
    books_collection.docs = [s1b1, s1b2].compact
    site = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
    context = create_context({}, { site: site, page: s1b1 })

    output = render_tag(context)
    refute_empty output.strip, "Output should not be empty"
    assert_match %r{<aside class="related">}, output
    assert_match %r{<h2>Related Books</h2>}, output
    assert_match %r{<div class="card-grid">}, output
    assert_equal 1, output.scan(/<!-- Card for:/).count
    assert_match %r{</div>\s*</aside>}m, output
  end

  def test_excludes_archived_reviews_from_recommendations
    books_collection = MockCollection.new([], 'books')
    current_page = create_book_obj('Current Book', 'Series A', 1, ['Auth'], 10, 'current', true, books_collection)
    related_canonical = create_book_obj('Related Canonical', 'Series A', 2, ['Auth'], 9, 'related_canon', true, books_collection)
    related_archived = create_book_obj('Related Archived', 'Series A', 3, ['Auth'], 8, 'related_archive', true, books_collection, { 'canonical_url' => '/some/path' })
    books_collection.docs = [current_page, related_canonical, related_archived].compact
    site = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
    context = create_context({}, { site: site, page: current_page })

    output = render_tag(context)
    rendered_titles = extract_rendered_titles(output)

    assert_includes rendered_titles, 'Related Canonical'
    refute_includes rendered_titles, 'Related Archived'
  end

  def test_includes_books_with_external_canonical_url
    books_collection = MockCollection.new([], 'books')
    current_page = create_book_obj('Current Book', 'Series A', 1, ['Auth'], 10, 'current', true, books_collection)
    related_external = create_book_obj('Related External', 'Series A', 2, ['Auth'], 5, 'related_ext', true, books_collection, { 'canonical_url' => 'http://some.other.site/path' })
    books_collection.docs = [current_page, related_external].compact
    site = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
    context = create_context({}, { site: site, page: current_page })

    output = render_tag(context)
    rendered_titles = extract_rendered_titles(output)

    assert_includes rendered_titles, 'Related External'
  end
end
