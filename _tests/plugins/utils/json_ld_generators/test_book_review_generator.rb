# _tests/plugins/utils/json_ld_generators/test_book_review_generator.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/utils/json_ld_generators/book_review_generator'
require_relative '../../../../_plugins/utils/front_matter_utils' # Needed by the generator
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
    doc = create_doc(
      {
        'layout' => 'book',
        'title' => 'Hyperion',
        'book_authors' => ['Dan Simmons'], # CHANGED to book_authors array
        'rating' => 5,
        'excerpt_output_override' => '<p>A fantastic space opera.</p>'
      },
      '/books/hyperion.html', 'Full review content here.', '2023-10-26 11:00:00 EST', @books_collection
    )

    expected = {
      "@context" => "https://schema.org", "@type" => "Review",
      "author" => { "@type" => "Person", "name" => "Alex Gude" },
      "datePublished" => "2023-10-26T11:00:00-05:00",
      "publisher" => { "@type" => "Person", "name" => "Alex Gude", "url" => "https://alexgude.com/" },
      "reviewRating" => { "@type" => "Rating", "ratingValue" => "5", "bestRating" => "5", "worstRating" => "1" },
      "reviewBody" => "A fantastic space opera.",
      "url" => "https://alexgude.com/books/hyperion.html",
      "itemReviewed" => {
        "@type" => "Book", "name" => "Hyperion",
        "author" => { "@type" => "Person", "name" => "Dan Simmons" }, # Single author object
        "url" => "https://alexgude.com/books/hyperion.html"
      }
    }
    assert_equal expected, BookReviewLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_book_review_multiple_authors
    doc = create_doc(
      {
        'layout' => 'book', 'title' => 'Good Omens',
        'book_authors' => ['Terry Pratchett', 'Neil Gaiman'], # CHANGED: Multiple authors
        'rating' => 5, 'excerpt_output_override' => 'Very funny.'
      },
      '/books/good-omens.html', 'Review content', '2023-11-01', @books_collection
    )

    expected = {
      "@context" => "https://schema.org", "@type" => "Review",
      "author" => { "@type" => "Person", "name" => "Alex Gude" },
      "datePublished" => Time.parse('2023-11-01').xmlschema,
      "publisher" => { "@type" => "Person", "name" => "Alex Gude", "url" => "https://alexgude.com/" },
      "reviewRating" => { "@type" => "Rating", "ratingValue" => "5", "bestRating" => "5", "worstRating" => "1" },
      "reviewBody" => "Very funny.",
      "url" => "https://alexgude.com/books/good-omens.html",
      "itemReviewed" => {
        "@type" => "Book", "name" => "Good Omens",
        "author" => [ # EXPECTING ARRAY of Person objects
                      { "@type" => "Person", "name" => "Terry Pratchett" },
                      { "@type" => "Person", "name" => "Neil Gaiman" }
        ],
        "url" => "https://alexgude.com/books/good-omens.html"
      }
    }
    actual = BookReviewLdGenerator.generate_hash(doc, @site)
    assert_equal expected, actual
  end


  def test_generate_hash_book_review_all_fields_single_author
    doc = create_doc(
      {
        'layout' => 'book', 'title' => 'Dune',
        'book_authors' => ['Frank Herbert'], # CHANGED
        'rating' => 4, 'description' => 'An epic tale of desert power.',
        'image' => '/assets/covers/dune.jpg', 'isbn' => '978-0441172719',
        'awards' => ["Hugo Award", "Nebula Award"], 'series' => 'Dune Saga', 'book_number' => '1'
      },
      '/books/dune.html', 'Detailed review content.', '2023-11-15', @books_collection
    )

    expected = {
      "@context" => "https://schema.org", "@type" => "Review",
      "author" => { "@type" => "Person", "name" => "Alex Gude" },
      "datePublished" => Time.parse('2023-11-15').xmlschema,
      "publisher" => { "@type" => "Person", "name" => "Alex Gude", "url" => "https://alexgude.com/" },
      "reviewRating" => { "@type" => "Rating", "ratingValue" => "4", "bestRating" => "5", "worstRating" => "1" },
      "reviewBody" => "An epic tale of desert power.",
      "url" => "https://alexgude.com/books/dune.html",
      "itemReviewed" => {
        "@type" => "Book", "name" => "Dune",
        "author" => { "@type" => "Person", "name" => "Frank Herbert" }, # Single Person
        "image" => { "@type" => "ImageObject", "url" => "https://alexgude.com/assets/covers/dune.jpg" },
        "isbn" => "978-0441172719", "award" => ["Hugo Award", "Nebula Award"],
        "isPartOf" => { "@type" => "BookSeries", "name" => "Dune Saga", "position" => "1" },
        "url" => "https://alexgude.com/books/dune.html"
      }
    }
    assert_equal expected, BookReviewLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_book_review_review_body_from_content
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Content Body Book',
        'book_authors' => ['Author'], # CHANGED
        'excerpt_output_override' => '', 'description' => '' },
        '/books/content-body.html', '<p>This is the <strong>full content</strong> used as review body.</p>',
        '2023-01-02', @books_collection
    )
    result = BookReviewLdGenerator.generate_hash(doc, @site)
    assert_equal "This is the full content used as review body.", result["reviewBody"]
  end

  def test_generate_hash_book_review_non_array_awards_logs_warning
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Non Array Awards',
        'book_authors' => ['Author'], # CHANGED
        'awards' => "This is a string, not an array" },
        '/books/non-array-awards.html', 'Content', '2023-01-03', @books_collection
    )
    mock_logger = Minitest::Mock.new
    mock_logger.expect(:warn, nil) { |p, m| p == "JSON-LD (BookReviewGen):" && m.include?("not an Array") }
    result_hash = nil
    Jekyll.stub :logger, mock_logger do
      result_hash = BookReviewLdGenerator.generate_hash(doc, @site)
    end
    assert_nil result_hash.dig("itemReviewed", "award")
    mock_logger.verify
  end

  def test_generate_hash_book_review_minimal_data
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Minimal Book',
        'book_authors' => ['Min Author'] }, # CHANGED
    '/books/minimal-book.html', '', '2024-01-01', @books_collection
    )
    expected = {
      "@context" => "https://schema.org", "@type" => "Review",
      "author" => { "@type" => "Person", "name" => "Alex Gude" },
      "datePublished" => Time.parse('2024-01-01').xmlschema,
      "publisher" => { "@type" => "Person", "name" => "Alex Gude", "url" => "https://alexgude.com/" },
      "url" => "https://alexgude.com/books/minimal-book.html",
      "itemReviewed" => {
        "@type" => "Book", "name" => "Minimal Book",
        "author" => { "@type" => "Person", "name" => "Min Author" }, # Single Person
        "url" => "https://alexgude.com/books/minimal-book.html"
      }
    }
    assert_equal expected, BookReviewLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_book_review_no_authors
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Book With No Authors',
        'book_authors' => [] }, # Empty array
    '/books/no-authors.html', '', '2024-01-02', @books_collection
    )
    result_hash = BookReviewLdGenerator.generate_hash(doc, @site)
    assert_nil result_hash.dig("itemReviewed", "author"), "itemReviewed.author should be nil if book_authors is empty"

    doc_nil_authors = create_doc(
      { 'layout' => 'book', 'title' => 'Book With Nil Authors',
        'book_authors' => nil }, # Nil value
        '/books/nil-authors.html', '', '2024-01-03', @books_collection
    )
    result_hash_nil = BookReviewLdGenerator.generate_hash(doc_nil_authors, @site)
    assert_nil result_hash_nil.dig("itemReviewed", "author"), "itemReviewed.author should be nil if book_authors is nil"

    doc_missing_authors_key = create_doc(
      { 'layout' => 'book', 'title' => 'Book Missing Authors Key' }, # Key 'book_authors' absent
      '/books/missing-authors-key.html', '', '2024-01-04', @books_collection
    )
    result_hash_missing = BookReviewLdGenerator.generate_hash(doc_missing_authors_key, @site)
    assert_nil result_hash_missing.dig("itemReviewed", "author"), "itemReviewed.author should be nil if book_authors key is missing"
  end

end
