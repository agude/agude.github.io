# frozen_string_literal: true

# _tests/plugins/logic/related_books/test_renderer.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/related/renderer'

# Tests for Jekyll::RelatedBooks::Renderer.
#
# Verifies that the Renderer correctly generates HTML structure for related books.
class TestRelatedBooksRenderer < Minitest::Test
  def setup
    @test_time_now = Time.parse('2024-03-15 10:00:00 EST')
    @site_config_base = {
      'url' => 'http://example.com',
      'plugin_logging' => { 'RELATED_BOOKS' => true },
      'plugin_log_level' => 'debug'
    }
    @helper = BookTestHelper.new(@test_time_now, @site_config_base)
  end

  def test_returns_empty_string_for_empty_books
    site = create_site(@site_config_base.dup, {})
    context = create_context({}, { site: site })

    renderer = Jekyll::RelatedBooks::Renderer.new(context, [])
    output = renderer.render

    assert_equal '', output
  end

  def test_generates_correct_html_structure
    books, site = @helper.setup_series_books(2)
    context = create_context({}, { site: site, page: books[0] })

    renderer = Jekyll::RelatedBooks::Renderer.new(context, books)
    output = nil
    BookCardUtils.stub :render, ->(book_obj, _ctx) { "<!-- Card for: #{book_obj.data['title']} -->\n" } do
      output = renderer.render
    end

    assert_match(/<aside class="related">/, output)
    assert_match(%r{<h2>Related Books</h2>}, output)
    assert_match(/<div class="card-grid">/, output)
    assert_equal 2, output.scan('<!-- Card for:').count
    assert_match(%r{</div>\s*</aside>}m, output)
  end

  def test_calls_book_card_utils_for_each_book
    books, site = @helper.setup_series_books(3)
    context = create_context({}, { site: site, page: books[0] })

    card_render_count = 0
    renderer = Jekyll::RelatedBooks::Renderer.new(context, books)
    BookCardUtils.stub :render, lambda { |_book_obj, _ctx|
      card_render_count += 1
      "<!-- Card -->\n"
    } do
      renderer.render
    end

    assert_equal 3, card_render_count
  end

  # Helper class for test setup
  class BookTestHelper
    attr_reader :test_time_now, :site_config_base

    def initialize(test_time_now, site_config_base)
      @test_time_now = test_time_now
      @site_config_base = site_config_base
    end

    def create_book(title:, url_suffix:, authors: nil, series: nil, book_num: nil,
                    date_offset_days: 0, published: true, collection: nil, extra_fm: {})
      authors_data = normalize_authors(authors)
      front_matter = {
        'title' => title, 'series' => series, 'book_number' => book_num,
        'book_authors' => authors_data, 'published' => published,
        'date' => @test_time_now - (60 * 60 * 24 * date_offset_days),
        'image' => "/images/book_#{url_suffix}.jpg",
        'excerpt_output_override' => "#{title} excerpt."
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
          title: "S1B#{i}", series: 'Series 1', book_num: i, authors: ['Auth'],
          date_offset_days: 10 - i, url_suffix: "s1b#{i}", collection: coll
        )
      end
      coll.docs = books.compact
      site = create_site(@site_config_base.dup, { 'books' => coll.docs })
      [books, site]
    end
  end
end
