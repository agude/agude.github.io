# frozen_string_literal: true

# _tests/plugins/test_related_books_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/tags/related_books_tag'

# Integration tests for Jekyll::Books::Tags::RelatedBooksTag Liquid tag.
#
# Tests the full orchestration of the tag, verifying that the Finder and
# Renderer work together correctly. Unit tests for Finder and Renderer are in
# _tests/plugins/logic/related_books/.
class TestRelatedBooksTag < Minitest::Test
  DEFAULT_MAX_BOOKS = Jekyll::Books::Related::Finder::DEFAULT_MAX_BOOKS

  def setup
    @site_config_base = {
      'url' => 'http://example.com',
      'plugin_logging' => { 'RELATED_BOOKS' => true, 'RELATED_BOOKS_SERIES' => true },
      'plugin_log_level' => 'debug',
    }
    @test_time_now = Time.parse('2024-03-15 10:00:00 EST')
    @helper = BookTestHelper.new(@test_time_now, @site_config_base)
    @helper.setup_generic_books
  end

  def test_tag_orchestrates_finder_and_renderer_correctly
    books, site = @helper.setup_series_books(4)
    context = create_context({}, { site: site, page: books[0] })

    output = @helper.render_tag(context)
    expected = [books[1].data['title'], books[2].data['title'], books[3].data['title']]
    assert_equal expected, @helper.extract_rendered_titles(output)
  end

  def test_tag_returns_only_logs_when_no_books_found
    coll = MockCollection.new([], 'books')
    curr = @helper.create_book(
      title: 'Alone Again',
      authors: ['Solo Author'],
      date_offset_days: 0,
      url_suffix: 'alone_again',
      collection: coll,
    )
    coll.docs = [curr, @helper.unpublished_book_generic, @helper.future_dated_book_generic].compact

    site = create_site(@site_config_base.dup, { 'books' => coll.docs })
    context = create_context({}, { site: site, page: curr })
    output = @helper.render_tag(context)
    assert_equal '', output.strip
  end

  def test_tag_combines_logs_and_html_output
    books, site = @helper.setup_series_books(2)
    context = create_context({}, { site: site, page: books[0] })

    output = @helper.render_tag(context)
    # Should have HTML structure
    assert_match(/<aside class="related">/, output)
    # Logs may be empty or present, but the HTML should always be there
    assert_includes output, books[1].data['title']
  end

  def test_series_current_is_book4_of_4_shows_1_2_3_sorted
    books, site = @helper.setup_series_books(4)
    context = create_context({}, { site: site, page: books[3] })

    output = @helper.render_tag(context)
    expected = [books[0].data['title'], books[1].data['title'], books[2].data['title']]
    assert_equal expected, @helper.extract_rendered_titles(output)
  end

  def test_series_current_is_book5_of_10_shows_3_4_6_sorted
    _, series_books, _, context = @helper.setup_book5_of_10_scenario
    output = @helper.render_tag(context)
    expected = [
      series_books[2].data['title'],
      series_books[3].data['title'],
      series_books[5].data['title'],
    ]
    assert_equal expected, @helper.extract_rendered_titles(output)
  end

  def test_series_provides_one_book_author_and_recent_fill_remaining_two
    _, s1b2, other_ay, _, context = @helper.setup_one_series_book_scenario
    output = @helper.render_tag(context)
    expected = [
      s1b2.data['title'],
      other_ay.data['title'],
      @helper.recent_unrelated_book1.data['title'],
    ]
    assert_equal expected, @helper.extract_rendered_titles(output)
  end

  def test_series_provides_two_books_author_and_recent_fill_remaining_one
    _, s1b2, s1b3, _, context = @helper.setup_two_series_books_scenario
    output = @helper.render_tag(context)
    expected = [
      s1b2.data['title'],
      s1b3.data['title'],
      @helper.recent_unrelated_book1.data['title'],
    ]
    assert_equal expected, @helper.extract_rendered_titles(output)
  end

  def test_multi_author_current_page_uses_either_author_for_fallback
    _, auth_a, auth_b, recent_z, _, context = @helper.setup_multi_author_scenario
    output = @helper.render_tag(context)
    expected = [auth_a.data['title'], auth_b.data['title'], recent_z.data['title']]
    assert_equal expected, @helper.extract_rendered_titles(output)
  end

  def test_recent_fallback_when_series_and_author_provide_less_than_max
    _, _, _, context = @helper.setup_recent_fallback_scenario
    output = @helper.render_tag(context)
    expected = [
      @helper.recent_unrelated_book1.data['title'],
      @helper.recent_unrelated_book2.data['title'],
      @helper.recent_unrelated_book3.data['title'],
    ]
    assert_equal expected, @helper.extract_rendered_titles(output)
  end

  def test_world_of_trouble_scenario_with_new_series_logic
    _, tlp, cc, fill, _, context = @helper.setup_world_of_trouble_scenario
    output = @helper.render_tag(context)
    expected = [tlp.data['title'], cc.data['title'], fill.data['title']]
    assert_equal DEFAULT_MAX_BOOKS, @helper.extract_rendered_titles(output).count
    assert_equal expected, @helper.extract_rendered_titles(output)
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

    def render_tag(context)
      output = ''
      Time.stub :now, @test_time_now do
        Jekyll.stub :logger, @silent_logger_stub do
          Jekyll::Books::Core::BookCardUtils.stub :render, ->(book_obj, _ctx) { "<!-- Card for: #{book_obj.data['title']} -->\n" } do
            output = Liquid::Template.parse('{% related_books %}').render!(context)
          end
        end
      end
      output
    end

    def extract_rendered_titles(output_html)
      output_html.scan(/<!-- Card for: (.*?) -->/).flatten
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

    def setup_book5_of_10_scenario
      books_collection = MockCollection.new([], 'books')
      series_books = (1..10).map do |i|
        create_book(
          title: "S1B#{i}",
          series: 'Series 1',
          book_num: i,
          authors: ['Auth'],
          date_offset_days: 20 - i,
          url_suffix: "s1b#{i}",
          collection: books_collection,
        )
      end
      books_collection.docs = series_books.compact
      site = create_site(@site_config_base.dup, { 'books' => books_collection.docs })
      context = create_context({}, { site: site, page: series_books[4] })
      [books_collection, series_books, site, context]
    end

    def setup_one_series_book_scenario
      coll = MockCollection.new([], 'books')
      curr = create_book(
        title: 'Current S1B1',
        series: 'Series Y',
        book_num: 1,
        authors: ['Author Y'],
        date_offset_days: 0,
        url_suffix: 'curr_s1b1',
        collection: coll,
      )
      s1b2 = create_book(
        title: 'S1B2',
        series: 'Series Y',
        book_num: 2,
        authors: ['Author Y'],
        date_offset_days: 5,
        url_suffix: 's1b2',
        collection: coll,
      )
      other_ay = create_book(
        title: 'Other AY Book Recent',
        authors: ['Author Y'],
        date_offset_days: 3,
        url_suffix: 'ay_other_rec',
        collection: coll,
      )
      coll.docs = [curr, s1b2, other_ay, @recent_unrelated_book1, @recent_unrelated_book2].compact
      site = create_site(@site_config_base.dup, { 'books' => coll.docs })
      context = create_context({}, { site: site, page: curr })
      [curr, s1b2, other_ay, site, context]
    end

    def setup_two_series_books_scenario
      coll = MockCollection.new([], 'books')
      curr = create_book(
        title: 'Current S1B1',
        series: 'Series Z',
        book_num: 1,
        authors: ['Author Z'],
        date_offset_days: 0,
        url_suffix: 'curr_s1b1',
        collection: coll,
      )
      s1b2 = create_book(
        title: 'S1B2',
        series: 'Series Z',
        book_num: 2,
        authors: ['Author Z'],
        date_offset_days: 10,
        url_suffix: 's1b2',
        collection: coll,
      )
      s1b3 = create_book(
        title: 'S1B3',
        series: 'Series Z',
        book_num: 3,
        authors: ['Author Z'],
        date_offset_days: 5,
        url_suffix: 's1b3',
        collection: coll,
      )
      coll.docs = [curr, s1b2, s1b3, @recent_unrelated_book1, @author_x_book2_recent].compact
      site = create_site(@site_config_base.dup, { 'books' => coll.docs })
      context = create_context({}, { site: site, page: curr })
      [curr, s1b2, s1b3, site, context]
    end

    def setup_multi_author_scenario
      coll = MockCollection.new([], 'books')
      curr = create_book(
        title: 'Current Multi-Author',
        series: 'UniqueSeries',
        book_num: 1,
        authors: ['Author A', 'Author B'],
        date_offset_days: 0,
        url_suffix: 'curr_multi',
        collection: coll,
      )
      auth_a = create_book(
        title: 'AuthorA Solo Book',
        authors: ['Author A'],
        date_offset_days: 2,
        url_suffix: 'aa_solo',
        collection: coll,
      )
      auth_b = create_book(
        title: 'AuthorB Solo Book',
        authors: ['Author B'],
        date_offset_days: 4,
        url_suffix: 'ab_solo',
        collection: coll,
      )
      recent_z = create_book(
        title: 'Recent By Z',
        authors: ['Author Z'],
        date_offset_days: 1,
        url_suffix: 'ru_z',
        collection: coll,
      )
      coll.docs = [curr, auth_a, auth_b, recent_z].compact
      site = create_site(@site_config_base.dup, { 'books' => coll.docs })
      context = create_context({}, { site: site, page: curr })
      [curr, auth_a, auth_b, recent_z, site, context]
    end

    def setup_recent_fallback_scenario
      coll = MockCollection.new([], 'books')
      curr = create_book(
        title: 'Current S1B1',
        series: 'Series Beta',
        book_num: 1,
        authors: ['Author B'],
        date_offset_days: 10,
        url_suffix: 'curr_s1b1',
        collection: coll,
      )
      coll.docs = [
        curr,
        @recent_unrelated_book1,
        @recent_unrelated_book2,
        @recent_unrelated_book3,
        @unpublished_book_generic,
      ].compact
      site = create_site(@site_config_base.dup, { 'books' => coll.docs })
      context = create_context({}, { site: site, page: curr })
      [coll, curr, site, context]
    end

    def setup_world_of_trouble_scenario
      coll = MockCollection.new([], 'books')
      series = 'The Last Policeman'
      authors = ['Ben H. Winters']

      wot = create_book(
        title: 'World of Trouble',
        series: series,
        book_num: 3,
        authors: authors,
        date_offset_days: 0,
        url_suffix: 'wot',
        collection: coll,
      )
      cc = create_book(
        title: 'Countdown City',
        series: series,
        book_num: 2,
        authors: authors,
        date_offset_days: 300,
        url_suffix: 'cc',
        collection: coll,
      )
      tlp = create_book(
        title: 'The Last Policeman',
        series: series,
        book_num: 1,
        authors: authors,
        date_offset_days: 365,
        url_suffix: 'tlp',
        collection: coll,
      )
      fill = create_book(
        title: 'Recent Unrelated Fill',
        authors: ['Another Author'],
        date_offset_days: 5,
        url_suffix: 'ru_fill',
        collection: coll,
      )

      coll.docs = [wot, tlp, cc, fill].compact
      site = create_site(@site_config_base.dup, { 'books' => coll.docs })
      context = create_context({}, { site: site, page: wot })
      [wot, tlp, cc, fill, site, context]
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
