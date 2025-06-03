# _tests/plugins/test_related_books_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/related_books_tag'
# FrontMatterUtils and BookListUtils (for _parse_book_number) should be loaded by test_helper

class TestRelatedBooksTag < Minitest::Test
  DEFAULT_MAX_BOOKS = Jekyll::RelatedBooksTag::DEFAULT_MAX_BOOKS

  def setup
    @site_config_base = {
      'url' => 'http://example.com',
      'plugin_logging' => { 'RELATED_BOOKS' => true }, # For prerequisite logging tests
      'plugin_log_level' => 'debug'
    }
    @test_time_now = Time.parse("2024-03-15 10:00:00 EST")
    @books_collection_mock = MockCollection.new([], 'books')

    # Updated create_book_obj to accept an array of authors
    def create_book_obj(title, series, book_num, authors_input, date_offset_days, url_suffix, published = true)
      authors_data = if authors_input.is_a?(Array)
                       authors_input.map(&:to_s) # Ensure strings
                     elsif authors_input.nil?
                       []
                     else
                       [authors_input.to_s]
                     end
      create_doc(
        {
          'title' => title, 'series' => series, 'book_number' => book_num,
          'book_authors' => authors_data, # Use 'book_authors' key
          'published' => published,
          'date' => @test_time_now - (60 * 60 * 24 * date_offset_days),
          'image' => "/images/book_#{url_suffix}.jpg",
          'excerpt_output_override' => "#{title} excerpt."
        },
        "/books/#{url_suffix}.html", "Content for #{title}", nil, @books_collection_mock
      )
    end

    # Date offsets: Lower is more recent.
    @sA_b3_ax = create_book_obj('Series A Book 3', 'Series A', 3, ['Author X'], 1,  'sa_b3_ax')
    @other_ax_recent = create_book_obj('Other AX Recent', 'Old Series', 1, ['Author X'], 2, 'other_ax_rec')
    @sA_b2_ax = create_book_obj('Series A Book 2', 'Series A', 2, ['Author X'], 5,  'sa_b2_ax')
    @book_ax_collab_c = create_book_obj('AX & CC Shared Book', 'Series D', 1, ['Author X', 'Collaborator C'], 6, 'ax_cc_shared')
    @other_ay_collab_c_standalone = create_book_obj('Other AY & CC Standalone', nil, nil, ['Author Y', 'Collaborator C'], 7, 'other_ay_cc_sa')
    @sA_b1_ax = create_book_obj('Series A Book 1', 'Series A', 1, ['Author X'], 10, 'sa_b1_ax')
    @other_ax_old    = create_book_obj('Other AX Old', nil, nil, ['Author X'], 20, 'other_ax_old')

    @sB_b2_ay = create_book_obj('Series B Book 2', 'Series B', 2, ['Author Y'], 4,  'sb_b2_ay')
    @sB_b1_ay = create_book_obj('Series B Book 1', 'Series B', 1, ['Author Y'], 8,  'sb_b1_ay')

    @recent_other_auth1 = create_book_obj('Recent Other Auth 1', 'Series C', 1, ['Author Z'], 0.5, 'rec_oth1')

    @unpublished_book = create_book_obj('Unpublished Book', 'Series A', 4, ['Author X'], 6, 'unpub', false)
    @future_dated_book = create_book_obj('Future Book', 'Series A', 5, ['Author X'], -3, 'future')

    @all_test_books_for_site = [
      @sA_b1_ax, @sA_b2_ax, @sA_b3_ax, @sB_b1_ay, @sB_b2_ay,
      @other_ax_recent, @other_ax_old, @other_ay_collab_c_standalone,
      @recent_other_auth1, @book_ax_collab_c,
      @unpublished_book, @future_dated_book
    ].compact # Ensure no nils if create_book_obj could return nil

    @books_collection_mock.docs = @all_test_books_for_site
    @site = create_site(@site_config_base.dup, { 'books' => @books_collection_mock.docs })

    @current_page_sA_aX = create_doc(
      { 'title' => 'Current Page In Series A', 'url' => '/books/current_sa_ax.html',
        'path' => 'current_sa_ax.md', 'series' => 'Series A',
        'book_authors' => ['Author X'], 'date' => @test_time_now },
    '/books/current_sa_ax.html', "Current page content", nil, @books_collection_mock
    )
    @context = create_context({}, { site: @site, page: @current_page_sA_aX })

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
    end
  end

  # Default render_tag uses silent logger. For tests verifying logger calls,
  # the test method itself should handle Jekyll.stub with a specific mock.
  def render_tag(context = @context)
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

  def test_logs_error_if_prerequisites_missing
    # Scenario 1: Page object is missing
    bad_context_no_page = create_context({}, { site: @site })
    mock_logger_page_missing = Minitest::Mock.new
    # Define expected message for page missing scenario
    expected_page_missing_msg_regex = /Missing prerequisites: page object/
    mock_logger_page_missing.expect(:error, nil) do |prefix, msg|
      prefix == "PluginLiquid:" && msg.match?(expected_page_missing_msg_regex) && msg.include?("PageURL='N/A'")
    end

    output_page_missing_with_mock = ""
    Time.stub :now, @test_time_now do
      Jekyll.stub :logger, mock_logger_page_missing do # Use the specific mock for this scenario
        BookCardUtils.stub :render, ->(b,c){""} do # Stub BookCardUtils as it might be called by the tag
          output_page_missing_with_mock = Liquid::Template.parse("{% related_books %}").render!(bad_context_no_page)
        end
      end
    end
    assert_match %r{<!-- \[ERROR\] RELATED_BOOKS_FAILURE: Reason='Missing prerequisites: page object.*PageURL='N/A'.* -->}, output_page_missing_with_mock
    mock_logger_page_missing.verify

    # Scenario 2: 'books' collection is missing
    site_no_books_collection = create_site(@site_config_base.dup, {})
    # Recreate current_page_sA_aX_for_test with correct book_authors for this specific context
    current_page_for_no_books_test = create_doc(
      { 'title' => 'Current Page In Series A', 'url' => '/books/current_sa_ax.html',
        'path' => 'current_sa_ax.md', 'series' => 'Series A',
        'book_authors' => ['Author X'], 'date' => @test_time_now }, # Using book_authors
    '/books/current_sa_ax.html', "Current page content", nil, @books_collection_mock # Collection doesn't matter for page itself
    )
    bad_context_no_books = create_context({}, { site: site_no_books_collection, page: current_page_for_no_books_test })
    mock_logger_coll_missing = Minitest::Mock.new
    expected_coll_missing_msg_regex = /Missing prerequisites: site\.collections\[&#39;books&#39;\]/
    mock_logger_coll_missing.expect(:error, nil) do |prefix, msg|
      prefix == "PluginLiquid:" && msg.match?(expected_coll_missing_msg_regex) && msg.include?("PageURL='/books/current_sa_ax.html'")
    end

    output_coll_missing_with_mock = ""
    Time.stub :now, @test_time_now do
      Jekyll.stub :logger, mock_logger_coll_missing do # Use the specific mock for this scenario
        BookCardUtils.stub :render, ->(b,c){""} do
          output_coll_missing_with_mock = Liquid::Template.parse("{% related_books %}").render!(bad_context_no_books)
        end
      end
    end
    assert_match %r{<!-- \[ERROR\] RELATED_BOOKS_FAILURE: Reason='Missing prerequisites: site\.collections\[&#39;books&#39;\]\.'\s*PageURL='\/books\/current_sa_ax\.html'\s*SourcePage='current_sa_ax\.md'\s*-->}, output_coll_missing_with_mock
    mock_logger_coll_missing.verify
  end

  def test_priority_1_same_series
    current_page_for_test = create_doc(
      { 'title' => 'Test Current Book (Series A)', 'url' => '/books/test_current_sa.html',
        'path' => 'test_current_sa.md', 'series' => 'Series A',
        'book_authors' => ['Author X'], 'date' => @test_time_now },
    '/books/test_current_sa.html', "Content", nil, @books_collection_mock
    )
    temp_site_books = @all_test_books_for_site.compact.dup.reject { |b| b.url == current_page_for_test.url }
    temp_site = create_site(@site_config_base.dup, { 'books' => temp_site_books })
    context_for_test = create_context({}, { site: temp_site, page: current_page_for_test })
    output = render_tag(context_for_test)
    rendered_titles = extract_rendered_titles(output)
    # Series A books sorted by book_number: @sA_b1_ax (1), @sA_b2_ax (2), @sA_b3_ax (3)
    expected_titles_series_order = [@sA_b1_ax.data['title'], @sA_b2_ax.data['title'], @sA_b3_ax.data['title']]
    assert_equal DEFAULT_MAX_BOOKS, rendered_titles.count
    assert_equal expected_titles_series_order, rendered_titles
  end

  def test_priority_2_same_author_after_series_single_author_page
    current_page_sB_aY = create_doc(
      { 'title' => 'Current Page In Series B', 'url' => '/books/current_sb_ay.html',
        'path' => 'current_sb_ay.md', 'series' => 'Series B',
        'book_authors' => ['Author Y'], 'date' => @test_time_now },
    '/books/current_sb_ay.html', "Content", nil, @books_collection_mock
    )
    temp_site_books = @all_test_books_for_site.compact.dup.reject { |b| b.url == current_page_sB_aY.url }
    temp_site = create_site(@site_config_base.dup, { 'books' => temp_site_books })
    context_for_test = create_context({}, { site: temp_site, page: current_page_sB_aY })
    output = render_tag(context_for_test)
    rendered_titles = extract_rendered_titles(output)
    # Series B books by Author Y, sorted by book_number: @sB_b1_ay (num 1), @sB_b2_ay (num 2)
    # Other books by Author Y, sorted by date: @other_ay_collab_c_standalone (offset 7)
    expected_titles = [
      @sB_b1_ay.data['title'],
      @sB_b2_ay.data['title'],
      @other_ay_collab_c_standalone.data['title']
    ]
    assert_equal DEFAULT_MAX_BOOKS, rendered_titles.count
    assert_equal expected_titles, rendered_titles, "Author fallback (single author page) prioritization failed"
  end

  def test_priority_2_current_page_multi_author_finds_by_any_author
    current_page_multi_author = create_doc(
      { 'title' => 'Current Multi-Author Book', 'url' => '/books/current_multi.html',
        'path' => 'current_multi.md', 'series' => 'Unique Series For This Test',
        'book_authors' => ['Author X', 'Collaborator C'], 'date' => @test_time_now },
    '/books/current_multi.html', "Content", nil, @books_collection_mock
    )
    temp_site_books = @all_test_books_for_site.compact.dup.reject { |b| b.url == current_page_multi_author.url }
    temp_site = create_site(@site_config_base.dup, { 'books' => temp_site_books })
    context_for_test = create_context({}, { site: temp_site, page: current_page_multi_author })
    output = render_tag(context_for_test)
    rendered_titles = extract_rendered_titles(output)

    # Expected: Most recent books by 'Author X' OR 'Collaborator C'
    # 1. @sA_b3_ax (X, offset 1)
    # 2. @other_ax_recent (X, offset 2)
    # 3. @sA_b2_ax (X, offset 5)
    expected_titles = [
      @sA_b3_ax.data['title'],
      @other_ax_recent.data['title'],
      @sA_b2_ax.data['title']
    ]
    assert_equal DEFAULT_MAX_BOOKS, rendered_titles.count
    assert_equal expected_titles, rendered_titles, "Multi-author current page related books failed"
  end

  def test_priority_3_recent_books_fallback
    current_page_no_affiliation = create_doc(
      { 'title' => 'Current Standalone Book', 'url' => '/books/current_standalone.html',
        'path' => 'current_standalone.md', 'series' => 'UniqueSeries',
        'book_authors' => ['UniqueAuthor'], 'date' => @test_time_now },
    '/books/current_standalone.html', "Content", nil, @books_collection_mock
    )
    temp_site_books = @all_test_books_for_site.compact.dup.reject { |b| b.url == current_page_no_affiliation.url }
    temp_site = create_site(@site_config_base.dup, { 'books' => temp_site_books })
    context_for_test = create_context({}, { site: temp_site, page: current_page_no_affiliation })
    output = render_tag(context_for_test)
    rendered_titles = extract_rendered_titles(output)
    expected_titles = [@recent_other_auth1.data['title'], @sA_b3_ax.data['title'], @other_ax_recent.data['title']]
    assert_equal DEFAULT_MAX_BOOKS, rendered_titles.count
    assert_equal expected_titles, rendered_titles
  end

  def test_fills_slots_correctly_when_series_and_author_overlap_partially
    output = render_tag(@context)
    rendered_titles = extract_rendered_titles(output)
    expected_titles = [@sA_b1_ax.data['title'], @sA_b2_ax.data['title'], @sA_b3_ax.data['title']]
    assert_equal DEFAULT_MAX_BOOKS, rendered_titles.count
    assert_equal expected_titles, rendered_titles
  end

  def test_world_of_trouble_scenario_fixed
    tlp_series_name = "The Last Policeman"
    bhw_authors_array = ["Ben H. Winters"]

    wot_book = create_book_obj('World of Trouble', tlp_series_name, 3, bhw_authors_array, 0, 'wot')
    tlp_book = create_book_obj('The Last Policeman', tlp_series_name, 1, bhw_authors_array, 365, 'tlp')
    cc_book  = create_book_obj('Countdown City', tlp_series_name, 2, bhw_authors_array, 300, 'cc')
    recent_unrelated1 = create_book_obj('Recent Unrelated 1', 'Other Series', 1, ['Other Author'], 10, 'ru1')
    recent_unrelated2 = create_book_obj('Recent Unrelated 2', nil, nil, ['Another Author'], 5, 'ru2')

    books_for_wot_test = [wot_book, tlp_book, cc_book, recent_unrelated1, recent_unrelated2].compact
    site_for_wot = create_site(@site_config_base.dup, { 'books' => books_for_wot_test })
    context_for_wot = create_context({}, { site: site_for_wot, page: wot_book })

    output = render_tag(context_for_wot)
    rendered_titles = extract_rendered_titles(output)
    expected_titles = [tlp_book.data['title'], cc_book.data['title'], recent_unrelated2.data['title']]
    assert_equal DEFAULT_MAX_BOOKS, rendered_titles.count
    assert_equal expected_titles, rendered_titles
  end

  def test_returns_empty_string_if_no_valid_related_books
    current_page_alone = create_book_obj('Alone Again', nil,nil,['Solo Author'],0,'alone_again')
    site_alone = create_site(@site_config_base.dup, {
      'books' => [current_page_alone, @unpublished_book, @future_dated_book].compact
    })
    context_alone = create_context({}, { site: site_alone, page: current_page_alone })
    output = render_tag(context_alone)
    assert_equal "", output.strip
  end

  def test_html_structure_is_correct
    output = render_tag(@context)
    refute_empty output.strip
    assert_match %r{<aside class="related">}, output
    assert_match %r{<h2>Related Books</h2>}, output
    assert_match %r{<div class="card-grid">}, output
    assert_equal DEFAULT_MAX_BOOKS, output.scan(/<!-- Card for:/).count
    assert_match %r{</div>\s*</aside>}m, output
  end

  def test_renders_fewer_than_max_books_if_insufficient_candidates
    series_sparse_name = "Sparse Series"
    author_sparse_name_array = ["Sparse Author"]

    current_page_sparse = create_book_obj('Current Sparse Book', series_sparse_name, 1, author_sparse_name_array, 0, 'curr_sparse')
    other_series_book_sparse = create_book_obj('Other Sparse Series Book', series_sparse_name, 2, author_sparse_name_array, 10, 'other_sparse')
    recent_unrelated_sparse = create_book_obj('Recent Unrelated Sparse', nil, nil, ['Another Author'], 5, 'rec_unrel_sparse')

    books_for_sparse_test = [
      current_page_sparse, other_series_book_sparse, recent_unrelated_sparse,
      @unpublished_book, @future_dated_book
    ].compact
    site_sparse = create_site(@site_config_base.dup, { 'books' => books_for_sparse_test })
    context_sparse = create_context({}, { site: site_sparse, page: current_page_sparse })

    output = render_tag(context_sparse)
    rendered_titles = extract_rendered_titles(output)
    expected_titles = [other_series_book_sparse.data['title'], recent_unrelated_sparse.data['title']]
    assert_equal 2, rendered_titles.count
    assert_equal expected_titles, rendered_titles
  end
end
