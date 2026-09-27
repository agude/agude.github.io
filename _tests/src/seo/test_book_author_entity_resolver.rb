# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../_plugins/src/seo/book_author_entity_resolver'

# Tests for Jekyll::SEO::BookAuthorEntityResolver.
class TestBookAuthorEntityResolver < Minitest::Test
  def setup
    jane_page = create_doc(
      {
        'title' => 'Jane Doe',
        'layout' => 'author_page',
        'pen_names' => ['J.D. Writer'],
        'same_as_urls' => [' https://example.com/jane ', nil, ''],
      },
      '/authors/jane-doe.html',
    )
    john_page = create_doc(
      { 'title' => 'John Smith', 'layout' => 'author_page' },
      '/authors/john-smith.html',
    )
    @site = create_site(
      { 'url' => 'https://mysite.dev', 'baseurl' => '/blog' },
      {},
      [jane_page, john_page],
    )
  end

  def test_resolves_canonical_author_to_person_entity
    document = create_book_document(['Jane Doe'])

    assert_equal(
      {
        '@type' => 'Person',
        '@id' => 'https://mysite.dev/blog/authors/jane-doe.html',
        'url' => 'https://mysite.dev/blog/authors/jane-doe.html',
        'name' => 'Jane Doe',
        'sameAs' => ['https://example.com/jane'],
      },
      resolve(document),
    )
  end

  def test_pen_name_preserves_credited_name_and_canonical_identity
    document = create_book_document(['J.D. Writer'])

    result = resolve(document)

    assert_equal 'J.D. Writer', result['name']
    assert_equal 'https://mysite.dev/blog/authors/jane-doe.html', result['@id']
    assert_equal 'https://mysite.dev/blog/authors/jane-doe.html', result['url']
    assert_equal ['https://example.com/jane'], result['sameAs']
  end

  def test_resolves_multiple_credited_authors_to_an_array
    document = create_book_document(['Jane Doe', 'John Smith'])

    result = resolve(document)

    assert_equal 2, result.length
    assert_equal 'Jane Doe', result.first['name']
    assert_equal 'https://mysite.dev/blog/authors/jane-doe.html', result.first['@id']
    assert_equal 'John Smith', result.last['name']
    assert_equal 'https://mysite.dev/blog/authors/john-smith.html', result.last['@id']
    refute result.last.key?('sameAs')
  end

  def test_missing_author_page_raises_fatal_exception
    document = create_book_document(['Unknown Author'])

    error = assert_raises(Jekyll::Errors::FatalException) { resolve(document) }

    assert_includes error.message, 'could not resolve author page for "Unknown Author"'
    assert_includes error.message, '/books/test-book.html'
  end

  def test_empty_authors_return_nil
    document = create_book_document([])

    assert_nil resolve(document)
  end

  private

  def create_book_document(authors)
    create_doc(
      { 'layout' => 'book', 'title' => 'Test Book', 'book_authors' => authors },
      '/books/test-book.html',
    )
  end

  def resolve(document)
    Jekyll::SEO::BookAuthorEntityResolver.resolve(document, @site)
  end
end
