# frozen_string_literal: true

require_relative '../../../test_helper'

# Checks the Review and Book nodes produced from book review documents.
class TestBookReviewLdGenerator < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://alexgude.com',
      'baseurl' => '',
      'author' => { 'name' => 'Alex Gude', 'url' => '/resume/' },
    }
    @site = create_site(@site_config, {}, author_pages + series_pages)
    @books_collection = MockCollection.new([], 'books')
  end

  def test_generate_hash_book_review_multiple_authors
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Good Omens', 'book_authors' => ['Terry Pratchett', 'Neil Gaiman'] },
      '/books/good-omens/',
    )
    expected = [
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
    ]
    assert_equal expected, generate(doc).dig('itemReviewed', 'author')
  end

  def test_generate_hash_book_review_uses_canonical_book_id_for_archived_review
    canonical = create_doc(
      { 'title' => 'Family Book', 'book_authors' => ['Author'] },
      '/books/family-book/',
    )
    archived = create_doc(
      {
        'layout' => 'book',
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

    result = generate(archived, site)

    assert_equal 'https://alexgude.com/books/family-book/#book', result.dig('itemReviewed', '@id')
    assert_equal 'https://alexgude.com/books/family-book/', result.dig('itemReviewed', 'url')
    assert_equal 'https://alexgude.com/books/family-book-archived/', result['url']
  end

  def test_generate_hash_book_review_all_fields_single_author
    doc = create_all_fields_doc
    expected = build_expected_all_fields_hash
    assert_equal expected, generate(doc)
  end

  # schema.org defines reviewBody as "the actual body of the review". The
  # excerpt is only the first paragraph and the description is a summary,
  # so neither may stand in for the review text.
  def test_book_review_omits_invalid_awards
    doc = create_minimal_data_doc
    doc.data['awards'] = 'hugo'
    refute generate(doc).fetch('itemReviewed').key?('award')
  end

  def test_generate_hash_book_review_minimal_data
    doc = create_minimal_data_doc
    expected = build_expected_minimal_hash
    assert_equal expected, generate(doc)
  end

  def test_book_review_omits_missing_or_empty_authors
    doc = create_minimal_data_doc
    doc.data.delete('book_authors')
    refute generate(doc).fetch('itemReviewed').key?('author')

    [nil, []].each do |authors|
      doc.data['book_authors'] = authors
      refute generate(doc).fetch('itemReviewed').key?('author')
    end
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

    page_hash = Jekyll::SEO::JsonLdInjector.generate_hash(series_page, @site)
    first_book = generate(first)['itemReviewed']
    second_book = generate(second)['itemReviewed']

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

    page_person = Jekyll::SEO::JsonLdInjector.generate_hash(author_page, @site)['about']
    book_author = generate(review).dig('itemReviewed', 'author')

    assert_equal 'https://alexgude.com/authors/jane-doe.html#person', page_person['@id']
    assert_equal page_person['@id'], book_author['@id']
    assert_equal page_person['url'], book_author['url']
    assert_equal 'J.D. Writer', book_author['name']
    assert_equal ['https://example.com/jane'], book_author['sameAs']
  end

  # Standalone books carry `series: null` and `book_number: 1` (the front
  # matter validator requires book_number). They must get neither a series
  # link nor a position, and must not trip the unresolved-series check.
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
      generate(doc)
    end
    assert_match 'Series Without A Page', error.message
  end

  private

  def generate(doc, site = @site)
    Jekyll::SEO::JsonLdInjector.generate_hash(doc, site)
  end

  def author_pages
    [
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

  def create_all_fields_doc
    create_doc(
      {
        'layout' => 'book',
        'title' => 'Dune&nbsp;Saga<br>Book One',
        'book_authors' => ['Frank Herbert'],
        'rating' => 4,
        'description' => 'An epic tale of desert power.',
        'excerpt_output_override' => '<p>Only an excerpt.</p>',
        'markdown_alternate_href' => '/books/dune.md',
        'language' => 'fr',
        'image' => '/assets/covers/dune.jpg',
        'isbn' => '978-0441172719',
        'awards' => %w[hugo nebula],
        'series' => 'Dune Saga',
        'book_number' => '1',
        'date_published' => '1965-08',
        'wikidata_qid' => 'Q190159',
        'same_as_urls' => ['https://en.wikipedia.org/wiki/Dune_(novel)'],
      },
      '/books/dune.html',
      '<p>Detailed review of <a href="/books/test/">Test<!--book-preview--><span class="book-link-preview">Hidden text.</span><!--/book-preview--></a>.</p>',
      '2023-11-15 11:00:00 EST',
      @books_collection,
    )
  end

  def build_expected_all_fields_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'Review',
      'license' => 'https://creativecommons.org/licenses/by-sa/4.0/',
      'author' => { '@type' => 'Person', 'name' => 'Alex Gude', '@id' => 'https://alexgude.com/resume/#person', 'url' => 'https://alexgude.com/resume/' },
      'datePublished' => '2023-11-15T11:00:00-05:00',
      'publisher' => { '@type' => 'Person', 'name' => 'Alex Gude', '@id' => 'https://alexgude.com/resume/#person', 'url' => 'https://alexgude.com/resume/' },
      'reviewRating' => { '@type' => 'Rating', 'ratingValue' => '4', 'bestRating' => '5', 'worstRating' => '1' },
      'reviewBody' => 'Detailed review of Test.',
      'url' => 'https://alexgude.com/books/dune.html',
      'encoding' => { '@type' => 'MediaObject', 'encodingFormat' => 'text/markdown', 'contentUrl' => 'https://alexgude.com/books/dune.md' },
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
      'name' => "Dune\u00A0Saga Book One",
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
      'inLanguage' => 'fr',
      'datePublished' => '1965-08',
      'award' => ['Hugo Award', 'Nebula Award'],
      'isPartOf' => {
        '@type' => 'BookSeries',
        '@id' => 'https://alexgude.com/books/series/dune-saga/#series',
        'url' => 'https://alexgude.com/books/series/dune-saga/',
        'name' => 'Dune Saga',
      },
      'position' => '1',
      # The Wikidata link comes from wikidata_qid, ahead of same_as_urls.
      'sameAs' => [
        'https://www.wikidata.org/wiki/Q190159',
        'https://en.wikipedia.org/wiki/Dune_(novel)',
      ],
    }
  end

  def create_minimal_data_doc
    create_doc(
      { 'layout' => 'book', 'title' => 'Minimal Book', 'book_authors' => ['Min Author'], 'series' => nil, 'book_number' => 1 },
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
