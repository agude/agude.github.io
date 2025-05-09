# _tests/plugins/utils/json_ld_generators/test_book_review_generator.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/utils/json_ld_generators/book_review_generator'
require 'minitest/mock' # For mocking logger

class TestBookReviewLdGenerator < Minitest::Test

  def setup
    @site_config = {
      'url' => 'https://alexgude.com',
      'baseurl' => '', # No baseurl for simplicity in these tests
      'author' => { 'name' => 'Alex Gude' } # Site author for review.author
    }
    @site = create_site(@site_config)
    @books_collection = MockCollection.new([], 'books') # For create_doc
  end

  def test_generate_hash_basic_book_review
    doc = create_doc(
      {
        'layout' => 'book',
        'title' => 'Hyperion', # This is book title and review headline effectively
        'book_author' => 'Dan Simmons',
        'rating' => 5,
        'excerpt_output_override' => '<p>A fantastic space opera.</p>' # For reviewBody
      },
      '/books/hyperion.html', # URL of the review page
      'Full review content here.', # document.content (fallback for reviewBody)
      '2023-10-26 11:00:00 EST', # date_str
      @books_collection
    )

    expected = {
      "@context" => "https://schema.org",
      "@type" => "Review",
      "author" => { "@type" => "Person", "name" => "Alex Gude" },
      "datePublished" => "2023-10-26T11:00:00-05:00",
      "publisher" => { "@type" => "Person", "name" => "Alex Gude", "url" => "https://alexgude.com/" },
      "reviewRating" => { "@type" => "Rating", "ratingValue" => "5", "bestRating" => "5", "worstRating" => "1" },
      "reviewBody" => "A fantastic space opera.",
      "url" => "https://alexgude.com/books/hyperion.html",
      "itemReviewed" => {
        "@type" => "Book",
        "name" => "Hyperion",
        "author" => { "@type" => "Person", "name" => "Dan Simmons" },
        "url" => "https://alexgude.com/books/hyperion.html" # URL of the review page for the book item
      }
    }
    assert_equal expected, BookReviewLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_book_review_all_fields
    doc = create_doc(
      {
        'layout' => 'book',
        'title' => 'Dune',
        'book_author' => 'Frank Herbert',
        'rating' => 4,
        'description' => 'An epic tale of desert power.', # reviewBody source if excerpt is empty
        'image' => '/assets/covers/dune.jpg', # For itemReviewed.image
        'isbn' => '978-0441172719',
        'awards' => ["Hugo Award", "Nebula Award"], # As an array
        'series' => 'Dune Saga',
        'book_number' => '1'
      },
      '/books/dune.html',
      'Detailed review content.',
      '2023-11-15', # date_str
      @books_collection
    )

    expected = {
      "@context" => "https://schema.org",
      "@type" => "Review",
      "author" => { "@type" => "Person", "name" => "Alex Gude" },
      "datePublished" => Time.parse('2023-11-15').xmlschema,
      "publisher" => { "@type" => "Person", "name" => "Alex Gude", "url" => "https://alexgude.com/" },
      "reviewRating" => { "@type" => "Rating", "ratingValue" => "4", "bestRating" => "5", "worstRating" => "1" },
      "reviewBody" => "An epic tale of desert power.",
      "url" => "https://alexgude.com/books/dune.html",
      "itemReviewed" => {
        "@type" => "Book",
        "name" => "Dune",
        "author" => { "@type" => "Person", "name" => "Frank Herbert" },
        "image" => { "@type" => "ImageObject", "url" => "https://alexgude.com/assets/covers/dune.jpg" },
        "isbn" => "978-0441172719",
        "award" => ["Hugo Award", "Nebula Award"],
        "isPartOf" => { "@type" => "BookSeries", "name" => "Dune Saga", "position" => "1" },
        "url" => "https://alexgude.com/books/dune.html"
      }
    }
    assert_equal expected, BookReviewLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_book_review_review_body_from_content
    doc = create_doc(
      {
        'layout' => 'book', 'title' => 'Content Body Book', 'book_author' => 'Author',
        'excerpt_output_override' => '', # Empty excerpt
        'description' => ''             # Empty description
      },
      '/books/content-body.html',
      '<p>This is the <strong>full content</strong> used as review body.</p>', # document.content
      '2023-01-02', @books_collection
    )
    result = BookReviewLdGenerator.generate_hash(doc, @site)
    assert_equal "This is the full content used as review body.", result["reviewBody"]
  end

  def test_generate_hash_book_review_non_array_awards_logs_warning
    doc = create_doc(
      {
        'layout' => 'book', 'title' => 'Non Array Awards', 'book_author' => 'Author',
        'awards' => "This is a string, not an array" # Invalid awards format
      },
      '/books/non-array-awards.html',
      'Content',
      '2023-01-03',
      @books_collection
    )

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:warn, nil) do |prefix, message|
      prefix == "JSON-LD (BookReviewGen):" && message.include?("not an Array") && message.include?(doc.url)
    end

    result_hash = nil
    Jekyll.stub :logger, mock_logger do
      result_hash = BookReviewLdGenerator.generate_hash(doc, @site)
    end

    assert_nil result_hash.dig("itemReviewed", "award"), "Awards should not be set if input is not an array"
    mock_logger.verify
  end

  def test_generate_hash_book_review_minimal_data
    # Only required fields for a book review page (title, book_author)
    # Site author, publisher, and dates will be added.
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Minimal Book', 'book_author' => 'Min Author' },
      '/books/minimal-book.html',
      '', # content_attr_val
      '2024-01-01', # date_str
      @books_collection
    )
    expected = {
      "@context" => "https://schema.org",
      "@type" => "Review",
      "author" => { "@type" => "Person", "name" => "Alex Gude" },
      "datePublished" => Time.parse('2024-01-01').xmlschema,
      "publisher" => { "@type" => "Person", "name" => "Alex Gude", "url" => "https://alexgude.com/" },
      "url" => "https://alexgude.com/books/minimal-book.html",
      "itemReviewed" => {
        "@type" => "Book",
        "name" => "Minimal Book",
        "author" => { "@type" => "Person", "name" => "Min Author" },
        "url" => "https://alexgude.com/books/minimal-book.html"
      }
      # No rating, reviewBody, image, isbn, awards, series
    }
    assert_equal expected, BookReviewLdGenerator.generate_hash(doc, @site)
  end

end
