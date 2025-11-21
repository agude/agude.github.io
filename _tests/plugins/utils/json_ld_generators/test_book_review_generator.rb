# frozen_string_literal: true

# _tests/plugins/utils/json_ld_generators/test_book_review_generator.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/utils/json_ld_generators/book_review_generator'
require_relative '../../../../_plugins/utils/front_matter_utils'
require 'minitest/mock'

class TestBookReviewLdGenerator < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://alexgude.com',
      'baseurl' => '',
      'author' => { 'name' => 'Alex Gude' }
    }
    @site = create_site(@site_config)
    @books_collection = MockCollection.new([], 'books')
  end

  def test_generate_hash_basic_book_review_single_author
    doc = create_single_author_doc
    expected = build_expected_single_author_hash
    assert_equal expected, BookReviewLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_book_review_multiple_authors
    doc = create_multiple_authors_doc
    expected = build_expected_multiple_authors_hash
    actual = BookReviewLdGenerator.generate_hash(doc, @site)
    assert_equal expected, actual
  end

  def test_generate_hash_book_review_all_fields_single_author
    doc = create_all_fields_doc
    expected = build_expected_all_fields_hash
    assert_equal expected, BookReviewLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_book_review_review_body_from_content
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Content Body Book',
        'book_authors' => ['Author'],
        'excerpt_output_override' => '', 'description' => '' },
      '/books/content-body.html',
      '<p>This is the <strong>full content</strong> used as review body.</p>',
      '2023-01-02',
      @books_collection
    )
    result = BookReviewLdGenerator.generate_hash(doc, @site)
    assert_equal 'This is the full content used as review body.', result['reviewBody']
  end

  def test_generate_hash_book_review_non_array_awards_logs_warning
    doc = create_non_array_awards_doc
    result_hash = generate_with_mock_logger(doc)
    assert_nil result_hash.dig('itemReviewed', 'award')
  end

  def test_generate_hash_book_review_minimal_data
    doc = create_minimal_data_doc
    expected = build_expected_minimal_hash
    assert_equal expected, BookReviewLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_book_review_no_authors_empty_array
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Book With No Authors', 'book_authors' => [] },
      '/books/no-authors.html', '', '2024-01-02', @books_collection
    )
    result_hash = BookReviewLdGenerator.generate_hash(doc, @site)
    assert_nil result_hash.dig('itemReviewed', 'author'),
               'itemReviewed.author should be nil if book_authors is empty'
  end

  def test_generate_hash_book_review_no_authors_nil_value
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Book With Nil Authors', 'book_authors' => nil },
      '/books/nil-authors.html', '', '2024-01-03', @books_collection
    )
    result_hash = BookReviewLdGenerator.generate_hash(doc, @site)
    assert_nil result_hash.dig('itemReviewed', 'author'),
               'itemReviewed.author should be nil if book_authors is nil'
  end

  def test_generate_hash_book_review_no_authors_missing_key
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Book Missing Authors Key' },
      '/books/missing-authors-key.html', '', '2024-01-04', @books_collection
    )
    result_hash = BookReviewLdGenerator.generate_hash(doc, @site)
    assert_nil result_hash.dig('itemReviewed', 'author'),
               'itemReviewed.author should be nil if book_authors key is missing'
  end

  private

  def create_single_author_doc
    create_doc(
      {
        'layout' => 'book',
        'title' => 'Hyperion',
        'book_authors' => ['Dan Simmons'],
        'rating' => 5,
        'excerpt_output_override' => '<p>A fantastic space opera.</p>'
      },
      '/books/hyperion.html',
      'Full review content here.',
      '2023-10-26 11:00:00 EST',
      @books_collection
    )
  end

  def build_expected_single_author_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'Review',
      'author' => { '@type' => 'Person', 'name' => 'Alex Gude' },
      'datePublished' => '2023-10-26T11:00:00-05:00',
      'publisher' => { '@type' => 'Person', 'name' => 'Alex Gude', 'url' => 'https://alexgude.com/' },
      'reviewRating' => { '@type' => 'Rating', 'ratingValue' => '5', 'bestRating' => '5', 'worstRating' => '1' },
      'reviewBody' => 'A fantastic space opera.',
      'url' => 'https://alexgude.com/books/hyperion.html',
      'itemReviewed' => {
        '@type' => 'Book',
        'name' => 'Hyperion',
        'author' => { '@type' => 'Person', 'name' => 'Dan Simmons' },
        'url' => 'https://alexgude.com/books/hyperion.html'
      }
    }
  end

  def create_multiple_authors_doc
    create_doc(
      {
        'layout' => 'book', 'title' => 'Good Omens',
        'book_authors' => ['Terry Pratchett', 'Neil Gaiman'],
        'rating' => 5, 'excerpt_output_override' => 'Very funny.'
      },
      '/books/good-omens.html',
      'Review content',
      '2023-11-01',
      @books_collection
    )
  end

  def build_expected_multiple_authors_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'Review',
      'author' => { '@type' => 'Person', 'name' => 'Alex Gude' },
      'datePublished' => Time.parse('2023-11-01').xmlschema,
      'publisher' => { '@type' => 'Person', 'name' => 'Alex Gude', 'url' => 'https://alexgude.com/' },
      'reviewRating' => { '@type' => 'Rating', 'ratingValue' => '5', 'bestRating' => '5', 'worstRating' => '1' },
      'reviewBody' => 'Very funny.',
      'url' => 'https://alexgude.com/books/good-omens.html',
      'itemReviewed' => {
        '@type' => 'Book',
        'name' => 'Good Omens',
        'author' => [
          { '@type' => 'Person', 'name' => 'Terry Pratchett' },
          { '@type' => 'Person', 'name' => 'Neil Gaiman' }
        ],
        'url' => 'https://alexgude.com/books/good-omens.html'
      }
    }
  end

  def create_all_fields_doc
    create_doc(
      {
        'layout' => 'book', 'title' => 'Dune',
        'book_authors' => ['Frank Herbert'],
        'rating' => 4, 'description' => 'An epic tale of desert power.',
        'image' => '/assets/covers/dune.jpg', 'isbn' => '978-0441172719',
        'awards' => ['Hugo Award', 'Nebula Award'], 'series' => 'Dune Saga', 'book_number' => '1'
      },
      '/books/dune.html',
      'Detailed review content.',
      '2023-11-15',
      @books_collection
    )
  end

  def build_expected_all_fields_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'Review',
      'author' => { '@type' => 'Person', 'name' => 'Alex Gude' },
      'datePublished' => Time.parse('2023-11-15').xmlschema,
      'publisher' => { '@type' => 'Person', 'name' => 'Alex Gude', 'url' => 'https://alexgude.com/' },
      'reviewRating' => { '@type' => 'Rating', 'ratingValue' => '4', 'bestRating' => '5', 'worstRating' => '1' },
      'reviewBody' => 'An epic tale of desert power.',
      'url' => 'https://alexgude.com/books/dune.html',
      'itemReviewed' => build_expected_dune_item_reviewed
    }
  end

  def build_expected_dune_item_reviewed
    {
      '@type' => 'Book',
      'name' => 'Dune',
      'author' => { '@type' => 'Person', 'name' => 'Frank Herbert' },
      'image' => { '@type' => 'ImageObject', 'url' => 'https://alexgude.com/assets/covers/dune.jpg' },
      'isbn' => '978-0441172719',
      'award' => ['Hugo Award', 'Nebula Award'],
      'isPartOf' => { '@type' => 'BookSeries', 'name' => 'Dune Saga', 'position' => '1' },
      'url' => 'https://alexgude.com/books/dune.html'
    }
  end

  def create_non_array_awards_doc
    create_doc(
      {
        'layout' => 'book', 'title' => 'Non Array Awards',
        'book_authors' => ['Author'],
        'awards' => 'This is a string, not an array'
      },
      '/books/non-array-awards.html',
      'Content',
      '2023-01-03',
      @books_collection
    )
  end

  def generate_with_mock_logger(doc)
    mock_logger = Minitest::Mock.new
    mock_logger.expect(:warn, nil) { |p, m| p == 'JSON-LD (BookReviewGen):' && m.include?('not an Array') }
    result_hash = nil
    Jekyll.stub :logger, mock_logger do
      result_hash = BookReviewLdGenerator.generate_hash(doc, @site)
    end
    mock_logger.verify
    result_hash
  end

  def create_minimal_data_doc
    create_doc(
      { 'layout' => 'book', 'title' => 'Minimal Book', 'book_authors' => ['Min Author'] },
      '/books/minimal-book.html',
      '',
      '2024-01-01',
      @books_collection
    )
  end

  def build_expected_minimal_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'Review',
      'author' => { '@type' => 'Person', 'name' => 'Alex Gude' },
      'datePublished' => Time.parse('2024-01-01').xmlschema,
      'publisher' => { '@type' => 'Person', 'name' => 'Alex Gude', 'url' => 'https://alexgude.com/' },
      'url' => 'https://alexgude.com/books/minimal-book.html',
      'itemReviewed' => {
        '@type' => 'Book',
        'name' => 'Minimal Book',
        'author' => { '@type' => 'Person', 'name' => 'Min Author' },
        'url' => 'https://alexgude.com/books/minimal-book.html'
      }
    }
  end
end
