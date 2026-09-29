# frozen_string_literal: true

require_relative '../test_helper'

# Helper class for test setup and utilities
class RelatedBookFixture
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
