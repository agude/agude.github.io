# frozen_string_literal: true

require_relative '../../../../test_helper'

# Book card data, HTML, and front-matter fallbacks.
class TestBookCardRenderer < Minitest::Test
  Renderer = Jekyll::Books::Core::BookCardRenderer

  def setup
    @site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/site' })
    @context = create_context({}, { site: @site, page: create_doc })
    @book = create_doc(
      {
        'title' => 'Part & Whole',
        'book_authors' => ['A & B', 'Second', 'Third', 'Fourth'],
        'rating' => 4,
        'image' => '/covers/book.jpg',
        'image_alt' => 'Front & back',
        'excerpt' => Struct.new(:output).new("  <p>Book excerpt.</p>\n"),
        'description' => 'Ignored for books.',
      },
      '/books/book/',
    )
  end

  def test_extract_data_returns_raw_values
    data = Renderer.new(@book, @context, 'Custom Title', 'First edition').extract_data

    assert_predicate data, :frozen?
    assert_equal(
      {
        title: 'Custom Title',
        url: 'https://example.com/site/books/book/',
        image_url: 'https://example.com/site/covers/book.jpg',
        authors: ['A & B', 'Second', 'Third', 'Fourth'],
        rating: 4,
        excerpt: '<p>Book excerpt.</p>',
        image_alt: 'Front & back',
        subtitle: 'First edition',
      },
      data,
    )
  end

  def test_render_book_card_html
    output = Renderer.render(@book, @context, subtitle: 'First <edition>')
    card = Nokogiri::HTML5.fragment(output).at_css('li.book-card')
    image = card.at_css('.card-book-cover img')

    assert_includes output, '<strong><cite class="book-title">Part &amp; Whole</cite></strong>'
    assert_includes output, 'alt="Front &amp; back"'
    assert_includes output, '<i>First &lt;edition&gt;</i>'
    assert_equal 'https://example.com/site/books/book/', image.parent['href']
    assert_equal 'https://example.com/site/covers/book.jpg', image['src']
    assert_equal 'lazy', image['loading']
    assert_equal 'async', image['decoding']
    assert_equal "auto, #{Renderer::COVER_SIZES}", image['sizes']
    assert_includes output, '<span class="author-name">A &amp; B</span> <abbr class="etal">et al.</abbr>'
    refute_includes output, 'Second'
    details = card.css('.by-author, .card-subtitle, .book-rating')
    detail_classes = details.map { |element| element['class'].split.first }
    assert_equal %w[by-author card-subtitle book-rating], detail_classes
    assert_equal '★★★★☆', card.at_css('.star-rating-4').text
    assert_equal 'Book excerpt.', card.at_css('.card-text .card-text').text.strip
  end

  def test_uses_display_title_override_when_provided
    @book.data.delete('image_alt')
    data = Renderer.new(@book, @context, 'Custom Title', nil).extract_data

    assert_equal 'Custom Title', data[:title]
    assert_equal 'Book cover of Custom Title.', data[:image_alt]

    blank_overrides = Renderer.new(@book, @context, '  ', '  ').extract_data
    assert_equal 'Part & Whole', blank_overrides[:title]
    assert_nil blank_overrides[:subtitle]
  end

  def test_render_book_card_minimal_data
    enable_logging('BOOK_CARD_MISSING_AUTHORS', 'BOOK_CARD_MISSING_EXCERPT', 'BOOK_CARD_MISSING_IMAGE_PATH')
    [nil, '  '].each do |blank|
      book = create_doc(
        { 'title' => 'Minimal Book', 'book_authors' => [], 'image' => blank, 'rating' => nil, 'excerpt' => blank },
        '/books/minimal/',
      )
      output = render_with_silent_logger(book)

      assert_match(/BOOK_CARD_MISSING_AUTHORS_FAILURE/, output)
      assert_match(/BOOK_CARD_MISSING_EXCERPT_FAILURE/, output)
      assert_match(/BOOK_CARD_MISSING_IMAGE_PATH_FAILURE/, output)
      assert_includes output, '<li class="book-card">'
      refute_match(/<img|by-author|card-subtitle|book-rating/, output)
      assert_equal 1, Nokogiri::HTML5.fragment(output).css('.card-text').size
    end
  end

  def test_render_returns_log_if_base_data_has_no_item_data_source
    enable_logging('BOOK_CARD_UTIL')
    assert_match(
      /\A<!-- \[WARN\] BOOK_CARD_UTIL_FAILURE:.*Invalid item_object.*-->\s*\z/,
      render_with_silent_logger(nil),
    )
  end

  def test_render_with_missing_title_logs_error
    enable_logging('BOOK_CARD_MISSING_TITLE')
    book = create_doc({ 'title' => nil }, '/books/untitled/')
    output = render_with_silent_logger(book)

    assert_match(/BOOK_CARD_MISSING_TITLE_FAILURE:.*Book title is missing and defaulted/, output)
    assert_includes output, '<cite class="book-title">Untitled Book</cite>'
  end

  def test_render_with_invalid_rating_logs_error_and_continues
    enable_logging('BOOK_CARD_RATING_ERROR')
    @book.data['rating'] = 'invalid'

    output = render_with_silent_logger(@book)

    assert_match(/\[WARN\] BOOK_CARD_RATING_ERROR_FAILURE:.*Invalid or malformed.*rating.*value/, output)
    assert_includes output, '<li class="book-card">'
    refute_includes output, 'book-rating'
  end

  def test_extract_data_returns_nil_when_base_extraction_fails
    Jekyll.stub :logger, silent_logger do
      assert_nil Renderer.new(@book, nil, nil, nil).extract_data
    end
  end

  private

  def enable_logging(*types)
    types.each { |type| @site.config['plugin_logging'][type] = true }
  end

  def render_with_silent_logger(book)
    Jekyll.stub(:logger, silent_logger) { Renderer.render(book, @context) }
  end
end
