# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/seo/generators/author_profile_generator'
require_relative '../../../../_plugins/src/seo/generators/book_review_generator'
require_relative '../../../../_plugins/src/seo/generators/series_page_generator'
require_relative '../../../../_plugins/src/infrastructure/front_matter_utils'
require 'minitest/mock'

# Tests for Jekyll::SEO::Generators::BookReviewLdGenerator module.
#
# Verifies that the generator correctly creates JSON-LD structured data for book reviews.
class TestBookReviewLdGenerator < Minitest::Test
  # Verbatim book link with hover preview, from the built
  # /books/a_fire_upon_the_deep/ page (BookPreviewRenderer output).
  BLINDSIGHT_LINK_WITH_PREVIEW = '<a href="/books/blindsight/"><cite class="book-title">Blindsight</cite><!--book-preview--><span class="book-link-preview" aria-hidden="true" hidden=""><img class="book-link-preview-cover" src="/books/covers/blindsight.jpg" alt="Cover of Blindsight" loading="lazy" decoding="async" /><span class="book-link-preview-text"><span class="book-link-preview-title">Blindsight</span><span class="book-link-preview-author">by Peter Watts</span><span class="book-rating star-rating-5" role="img" aria-label="Rating: 5 out of 5 stars. Masterpiece — I loved it" title="Masterpiece — I loved it"><span class="book_star full_star" aria-hidden="true">★</span><span class="book_star full_star" aria-hidden="true">★</span><span class="book_star full_star" aria-hidden="true">★</span><span class="book_star full_star" aria-hidden="true">★</span><span class="book_star full_star" aria-hidden="true">★</span></span><span class="book-link-preview-series"><span class="book-series">Firefall</span> #1</span></span><span class="book-link-preview-lede"><cite class="book-title">Blindsight</cite> is a hard sci-fi novel about first contact with aliens in the near future. A crew of four transhumans and a vampire are sent on a spaceship to investigate an anomaly in the solar system after a swarm of alien probes scan Earth.</span></span><!--/book-preview--></a>'

  def setup
    @site_config = {
      'url' => 'https://alexgude.com',
      'baseurl' => '',
      'author' => { 'name' => 'Alex Gude', 'url' => '/resume/' },
    }
    @site = create_site(@site_config, {}, author_pages + series_pages)
    @books_collection = MockCollection.new([], 'books')
  end

  def test_generate_hash_basic_book_review_single_author
    doc = create_single_author_doc
    expected = build_expected_single_author_hash
    assert_equal expected, Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_book_review_multiple_authors
    doc = create_multiple_authors_doc
    expected = build_expected_multiple_authors_hash
    actual = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)
    assert_equal expected, actual
  end

  def test_generate_hash_book_review_preserves_pen_name_with_canonical_author_identity
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Pen Name Book', 'book_authors' => ['J.D. Writer'] },
      '/books/pen-name-book.html',
      'Review content',
      '2024-01-01',
      @books_collection,
    )

    result = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)

    assert_equal(
      {
        '@type' => 'Person',
        '@id' => 'https://alexgude.com/authors/jane-doe.html#person',
        'url' => 'https://alexgude.com/authors/jane-doe.html',
        'name' => 'J.D. Writer',
        'sameAs' => ['https://example.com/jane'],
      },
      result.dig('itemReviewed', 'author'),
    )
  end

  def test_generate_hash_book_review_uses_canonical_book_id_for_archived_review
    canonical = create_doc(
      { 'title' => 'Family Book', 'book_authors' => ['Author'] },
      '/books/family-book/',
    )
    archived = create_doc(
      {
        'title' => 'Family Book',
        'book_authors' => ['Author'],
        'canonical_url' => canonical.url,
      },
      '/books/family-book-archived/',
    )
    site = create_site(
      @site_config,
      { 'books' => [canonical, archived] },
      [create_author_page('Author', '/authors/author.html')],
    )

    result = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(archived, site)

    assert_equal 'https://alexgude.com/books/family-book/#book', result.dig('itemReviewed', '@id')
    assert_equal 'https://alexgude.com/books/family-book/', result.dig('itemReviewed', 'url')
    assert_equal 'https://alexgude.com/books/family-book-archived/', result['url']
  end

  def test_generate_hash_book_review_all_fields_single_author
    doc = create_all_fields_doc
    expected = build_expected_all_fields_hash
    assert_equal expected, Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)
  end

  # schema.org defines reviewBody as "the actual body of the review". The
  # excerpt is only the first paragraph and the description is a summary,
  # so neither may stand in for the review text.
  def test_generate_hash_review_body_is_full_content_not_excerpt_or_description
    doc = create_doc(
      {
        'layout' => 'book',
        'title' => 'Full Body Book',
        'book_authors' => ['Author'],
        'excerpt_output_override' => '<p>Opening paragraph.</p>',
        'description' => 'A summary.',
      },
      '/books/full-body.html',
      "<p>Opening paragraph.</p>\n<p>Second paragraph of the <em>review</em>.</p>", # Kramdown separates blocks
      '2023-01-02',
      @books_collection,
    )
    result = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)
    assert_equal 'Opening paragraph. Second paragraph of the review.', result['reviewBody']
  end

  def test_generate_hash_review_body_excludes_book_link_preview
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Preview Book', 'book_authors' => ['Author'] },
      '/books/preview-book.html',
      "<p>One of the best books I have read, behind only #{BLINDSIGHT_LINK_WITH_PREVIEW}.</p>",
      '2023-01-02',
      @books_collection,
    )
    result = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)
    assert_equal 'One of the best books I have read, behind only Blindsight.', result['reviewBody']
  end

  def test_generate_hash_book_review_non_array_awards_logs_warning
    doc = create_non_array_awards_doc
    result_hash = generate_with_mock_logger(doc)
    assert_nil result_hash.dig('itemReviewed', 'award')
  end

  def test_generate_hash_book_review_non_array_same_as_urls_logs_warning
    doc = create_doc(
      {
        'layout' => 'book',
        'title' => 'Non Array SameAs',
        'book_authors' => ['Author'],
        'same_as_urls' => 'This is a string, not an array',
      },
      '/books/non-array-same-as.html',
      'Content',
      '2023-01-03',
      @books_collection,
    )
    mock_logger = Minitest::Mock.new
    mock_logger.expect(:warn, nil) { |p, m| p == 'JSON-LD:' && m.include?('not an Array') }
    result_hash = nil
    Jekyll.stub :logger, mock_logger do
      result_hash = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)
    end
    mock_logger.verify
    assert_nil result_hash.dig('itemReviewed', 'sameAs')
  end

  def test_generate_hash_book_review_minimal_data
    doc = create_minimal_data_doc
    expected = build_expected_minimal_hash
    assert_equal expected, Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_markdown_alternate_href_includes_encoding
    doc = create_doc(
      {
        'layout' => 'book',
        'title' => 'Markdown Book',
        'book_authors' => ['Author'],
        'markdown_alternate_href' => '/books/markdown-book.md',
      },
      '/books/markdown-book.html',
      '<p>Content</p>',
      '2024-01-15',
      @books_collection,
    )
    result = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)
    expected_encoding = {
      '@type' => 'MediaObject',
      'encodingFormat' => 'text/markdown',
      'contentUrl' => 'https://alexgude.com/books/markdown-book.md',
    }
    assert_equal expected_encoding, result['encoding']
  end

  def test_generate_hash_without_markdown_alternate_href_omits_encoding
    doc = create_minimal_data_doc
    result = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)
    refute result.key?('encoding'), 'No markdown_alternate_href should omit encoding'
  end

  def test_generate_hash_book_review_no_authors_empty_array
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Book With No Authors', 'book_authors' => [] },
      '/books/no-authors.html',
      '',
      '2024-01-02',
      @books_collection,
    )
    result_hash = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)
    assert_nil result_hash.dig('itemReviewed', 'author'),
               'itemReviewed.author should be nil if book_authors is empty'
  end

  def test_generate_hash_book_review_no_authors_nil_value
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Book With Nil Authors', 'book_authors' => nil },
      '/books/nil-authors.html',
      '',
      '2024-01-03',
      @books_collection,
    )
    result_hash = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)
    assert_nil result_hash.dig('itemReviewed', 'author'),
               'itemReviewed.author should be nil if book_authors is nil'
  end

  def test_generate_hash_book_review_no_authors_missing_key
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Book Missing Authors Key' },
      '/books/missing-authors-key.html',
      '',
      '2024-01-04',
      @books_collection,
    )
    result_hash = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)
    assert_nil result_hash.dig('itemReviewed', 'author'),
               'itemReviewed.author should be nil if book_authors key is missing'
  end

  # BookSeries is identified from the series page URL, the same way
  # Book.author is identified from the author page URL. Without it, reviews
  # never connect to the series page that lists them. Two reviews in one
  # series must reference the series page's BookSeries node by the same @id,
  # and each Book keeps its own position.
  def test_generate_hash_series_identity_matches_series_page_across_reviews
    series_page = create_doc({ 'title' => 'Dune Saga', 'layout' => 'series_page' }, '/books/series/dune-saga/')
    first = create_series_book_doc('Dune', 1)
    second = create_series_book_doc('Dune Messiah', 2)

    page_hash = Jekyll::SEO::Generators::SeriesPageLdGenerator.generate_hash(series_page, @site)
    first_book = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(first, @site)['itemReviewed']
    second_book = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(second, @site)['itemReviewed']

    series_id = page_hash.dig('about', '@id')
    assert_equal 'https://alexgude.com/books/series/dune-saga/#series', series_id
    assert_equal series_id, first_book.dig('isPartOf', '@id')
    assert_equal series_id, second_book.dig('isPartOf', '@id')
    assert_equal first_book['isPartOf'], second_book['isPartOf'], 'Shared series node must be identical'
    assert_equal '1', first_book['position']
    assert_equal '2', second_book['position']
  end

  # The author page's `about` Person and each reviewed Book's author must
  # be one node, so they must share an @id. A book credited under a pen
  # name still references the canonical author page's Person.
  def test_generate_hash_author_identity_matches_author_page
    author_page = create_author_page('Jane Doe', '/authors/jane-doe.html', pen_names: ['J.D. Writer'])
    review = create_doc(
      { 'layout' => 'book', 'title' => 'Pen Name Book', 'book_authors' => ['J.D. Writer'] },
      '/books/pen-name-book.html',
      'Review content',
      '2024-01-01',
      @books_collection,
    )

    page_person = Jekyll::SEO::Generators::AuthorProfileLdGenerator.generate_hash(author_page, @site)['about']
    book_author = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(review, @site).dig('itemReviewed', 'author')

    assert_equal 'https://alexgude.com/authors/jane-doe.html#person', page_person['@id']
    assert_equal page_person['@id'], book_author['@id']
    assert_equal page_person['url'], book_author['url']
  end

  # Standalone books carry `series: null` and `book_number: 1` (the front
  # matter validator requires book_number). They must get neither a series
  # link nor a position, and must not trip the unresolved-series check.
  def test_generate_hash_standalone_book_has_no_series_or_position
    doc = create_doc(
      {
        'layout' => 'book',
        'title' => 'Standalone Book',
        'book_authors' => ['Author'],
        'series' => nil,
        'book_number' => 1,
      },
      '/books/standalone-book/',
      'Content',
      '2024-01-01',
      @books_collection,
    )
    book = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)['itemReviewed']

    refute book.key?('isPartOf'), 'Standalone book must not reference a series'
    refute book.key?('position'), 'Standalone book must not have a series position'
  end

  def test_generate_hash_unresolved_series_stops_build
    doc = create_doc(
      {
        'layout' => 'book',
        'title' => 'Orphan Book',
        'book_authors' => ['Author'],
        'series' => 'Series Without A Page',
        'book_number' => 2,
      },
      '/books/orphan-book.html',
      'Content',
      '2024-01-01',
      @books_collection,
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)
    end
    assert_match 'Series Without A Page', error.message
  end

  def test_generate_hash_book_name_strips_title_markup
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'First&nbsp;Part<br>Second Part', 'book_authors' => ['Author'] },
      '/books/markup.html',
      'Content',
      '2024-01-01',
      @books_collection,
    )
    result = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)
    assert_equal "First\u00A0Part Second Part", result.dig('itemReviewed', 'name')
  end

  private

  def author_pages
    [
      create_author_page(
        'Dan Simmons',
        '/authors/dan-simmons.html',
        same_as_urls: ['https://example.com/dan-simmons'],
      ),
      create_author_page('Terry Pratchett', '/authors/terry-pratchett.html'),
      create_author_page('Neil Gaiman', '/authors/neil-gaiman.html'),
      create_author_page('Frank Herbert', '/authors/frank-herbert.html'),
      create_author_page('Author', '/authors/author.html'),
      create_author_page('Min Author', '/authors/min-author.html'),
      create_author_page(
        'Jane Doe',
        '/authors/jane-doe.html',
        pen_names: ['J.D. Writer'],
        same_as_urls: ['https://example.com/jane'],
      ),
    ]
  end

  def create_series_book_doc(title, book_number)
    slug = title.downcase.tr(' ', '-')
    create_doc(
      {
        'layout' => 'book',
        'title' => title,
        'book_authors' => ['Frank Herbert'],
        'series' => 'Dune Saga',
        'book_number' => book_number,
      },
      "/books/#{slug}/",
      'Content',
      '2024-01-01',
      @books_collection,
    )
  end

  def series_pages
    [create_doc({ 'title' => 'Dune Saga', 'layout' => 'series_page' }, '/books/series/dune-saga/')]
  end

  def create_author_page(title, url, pen_names: [], same_as_urls: [])
    create_doc(
      {
        'title' => title,
        'layout' => 'author_page',
        'pen_names' => pen_names,
        'same_as_urls' => same_as_urls,
      },
      url,
    )
  end

  def create_single_author_doc
    create_doc(
      {
        'layout' => 'book',
        'title' => 'Hyperion',
        'book_authors' => ['Dan Simmons'],
        'rating' => 5,
        'excerpt_output_override' => '<p>A fantastic space opera.</p>',
      },
      '/books/hyperion.html',
      'Full review content here.',
      '2023-10-26 11:00:00 EST',
      @books_collection,
    )
  end

  def build_expected_single_author_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'Review',
      'license' => 'https://creativecommons.org/licenses/by-sa/4.0/',
      'author' => { '@type' => 'Person', 'name' => 'Alex Gude', '@id' => 'https://alexgude.com/resume/#person', 'url' => 'https://alexgude.com/resume/' },
      'datePublished' => '2023-10-26T11:00:00-05:00',
      'publisher' => { '@type' => 'Person', 'name' => 'Alex Gude', '@id' => 'https://alexgude.com/resume/#person', 'url' => 'https://alexgude.com/resume/' },
      'reviewRating' => { '@type' => 'Rating', 'ratingValue' => '5', 'bestRating' => '5', 'worstRating' => '1' },
      'reviewBody' => 'Full review content here.',
      'url' => 'https://alexgude.com/books/hyperion.html',
      'itemReviewed' => {
        '@type' => 'Book',
        'name' => 'Hyperion',
        '@id' => 'https://alexgude.com/books/hyperion.html#book',
        'url' => 'https://alexgude.com/books/hyperion.html',
        'author' => {
          '@type' => 'Person',
          '@id' => 'https://alexgude.com/authors/dan-simmons.html#person',
          'url' => 'https://alexgude.com/authors/dan-simmons.html',
          'name' => 'Dan Simmons',
          'sameAs' => ['https://example.com/dan-simmons'],
        },
        'inLanguage' => 'en',
      },
    }
  end

  def create_multiple_authors_doc
    create_doc(
      {
        'layout' => 'book',
        'title' => 'Good Omens',
        'book_authors' => ['Terry Pratchett', 'Neil Gaiman'],
        'rating' => 5,
        'excerpt_output_override' => 'Very funny.',
      },
      '/books/good-omens.html',
      'Review content',
      '2023-11-01',
      @books_collection,
    )
  end

  def build_expected_multiple_authors_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'Review',
      'license' => 'https://creativecommons.org/licenses/by-sa/4.0/',
      'author' => { '@type' => 'Person', 'name' => 'Alex Gude', '@id' => 'https://alexgude.com/resume/#person', 'url' => 'https://alexgude.com/resume/' },
      'datePublished' => Time.parse('2023-11-01').xmlschema,
      'publisher' => { '@type' => 'Person', 'name' => 'Alex Gude', '@id' => 'https://alexgude.com/resume/#person', 'url' => 'https://alexgude.com/resume/' },
      'reviewRating' => { '@type' => 'Rating', 'ratingValue' => '5', 'bestRating' => '5', 'worstRating' => '1' },
      'reviewBody' => 'Review content',
      'url' => 'https://alexgude.com/books/good-omens.html',
      'itemReviewed' => {
        '@type' => 'Book',
        'name' => 'Good Omens',
        '@id' => 'https://alexgude.com/books/good-omens.html#book',
        'url' => 'https://alexgude.com/books/good-omens.html',
        'author' => [
          {
            '@type' => 'Person',
            '@id' => 'https://alexgude.com/authors/terry-pratchett.html#person',
            'url' => 'https://alexgude.com/authors/terry-pratchett.html',
            'name' => 'Terry Pratchett',
          },
          {
            '@type' => 'Person',
            '@id' => 'https://alexgude.com/authors/neil-gaiman.html#person',
            'url' => 'https://alexgude.com/authors/neil-gaiman.html',
            'name' => 'Neil Gaiman',
          },
        ],
        'inLanguage' => 'en',
      },
    }
  end

  def create_all_fields_doc
    create_doc(
      {
        'layout' => 'book',
        'title' => 'Dune',
        'book_authors' => ['Frank Herbert'],
        'rating' => 4,
        'description' => 'An epic tale of desert power.',
        'image' => '/assets/covers/dune.jpg',
        'isbn' => '978-0441172719',
        'awards' => %w[hugo nebula],
        'series' => 'Dune Saga',
        'book_number' => '1',
        'date_published' => '1965-08',
        'same_as_urls' => [
          'https://www.wikidata.org/wiki/Q190159',
          'https://en.wikipedia.org/wiki/Dune_(novel)',
        ],
      },
      '/books/dune.html',
      'Detailed review content.',
      '2023-11-15',
      @books_collection,
    )
  end

  def build_expected_all_fields_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'Review',
      'license' => 'https://creativecommons.org/licenses/by-sa/4.0/',
      'author' => { '@type' => 'Person', 'name' => 'Alex Gude', '@id' => 'https://alexgude.com/resume/#person', 'url' => 'https://alexgude.com/resume/' },
      'datePublished' => Time.parse('2023-11-15').xmlschema,
      'publisher' => { '@type' => 'Person', 'name' => 'Alex Gude', '@id' => 'https://alexgude.com/resume/#person', 'url' => 'https://alexgude.com/resume/' },
      'reviewRating' => { '@type' => 'Rating', 'ratingValue' => '4', 'bestRating' => '5', 'worstRating' => '1' },
      'reviewBody' => 'Detailed review content.',
      'url' => 'https://alexgude.com/books/dune.html',
      'itemReviewed' => build_expected_dune_item_reviewed,
    }
  end

  # Each entity's @id is its page URL plus a fragment naming the kind of
  # thing (#book, #person, #series). The bare URL is the web page; per W3C
  # Cool URIs, one URI must not name both a page and the thing it describes.
  # Without the fragment, Review.url and Book @id would be the same IRI,
  # which types the review page itself as a Book.
  def build_expected_dune_item_reviewed
    {
      '@type' => 'Book',
      'name' => 'Dune',
      '@id' => 'https://alexgude.com/books/dune.html#book',
      'url' => 'https://alexgude.com/books/dune.html',
      'author' => {
        '@type' => 'Person',
        '@id' => 'https://alexgude.com/authors/frank-herbert.html#person',
        'url' => 'https://alexgude.com/authors/frank-herbert.html',
        'name' => 'Frank Herbert',
      },
      'image' => { '@type' => 'ImageObject', 'url' => 'https://alexgude.com/assets/covers/dune.jpg' },
      'isbn' => '978-0441172719',
      'inLanguage' => 'en',
      'datePublished' => '1965-08',
      'award' => ['Hugo Award', 'Nebula Award'],
      'isPartOf' => {
        '@type' => 'BookSeries',
        '@id' => 'https://alexgude.com/books/series/dune-saga/#series',
        'url' => 'https://alexgude.com/books/series/dune-saga/',
        'name' => 'Dune Saga',
      },
      'position' => '1',
      'sameAs' => [
        'https://www.wikidata.org/wiki/Q190159',
        'https://en.wikipedia.org/wiki/Dune_(novel)',
      ],
    }
  end

  def create_non_array_awards_doc
    create_doc(
      {
        'layout' => 'book',
        'title' => 'Non Array Awards',
        'book_authors' => ['Author'],
        'awards' => 'This is a string, not an array',
      },
      '/books/non-array-awards.html',
      'Content',
      '2023-01-03',
      @books_collection,
    )
  end

  def generate_with_mock_logger(doc)
    mock_logger = Minitest::Mock.new
    mock_logger.expect(:warn, nil) { |p, m| p == 'JSON-LD:' && m.include?('not an Array') }
    result_hash = nil
    Jekyll.stub :logger, mock_logger do
      result_hash = Jekyll::SEO::Generators::BookReviewLdGenerator.generate_hash(doc, @site)
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
      @books_collection,
    )
  end

  def build_expected_minimal_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'Review',
      'license' => 'https://creativecommons.org/licenses/by-sa/4.0/',
      'author' => { '@type' => 'Person', 'name' => 'Alex Gude', '@id' => 'https://alexgude.com/resume/#person', 'url' => 'https://alexgude.com/resume/' },
      'datePublished' => Time.parse('2024-01-01').xmlschema,
      'publisher' => { '@type' => 'Person', 'name' => 'Alex Gude', '@id' => 'https://alexgude.com/resume/#person', 'url' => 'https://alexgude.com/resume/' },
      'url' => 'https://alexgude.com/books/minimal-book.html',
      'itemReviewed' => {
        '@type' => 'Book',
        'name' => 'Minimal Book',
        '@id' => 'https://alexgude.com/books/minimal-book.html#book',
        'url' => 'https://alexgude.com/books/minimal-book.html',
        'author' => {
          '@type' => 'Person',
          '@id' => 'https://alexgude.com/authors/min-author.html#person',
          'url' => 'https://alexgude.com/authors/min-author.html',
          'name' => 'Min Author',
        },
        'inLanguage' => 'en',
      },
    }
  end
end
