# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../_plugins/src/seo/book_identity_resolver'
require 'support/property_test'

# Exercises cache building, candidate selection, and book identity together.
class TestLinkCacheGeneratorProperties < Minitest::Test
  include PropertyTestSupport

  Generators = PropCheck::Generators
  FixtureVariationGenerator = Generators.tuple(Generators.choose(1..17), Generators.choose(1..2))

  def test_generated_reviews_resolve_from_document_metadata
    check_property(FixtureVariationGenerator, seed: 4501) do |variation|
      sequence_id, archive_count = variation
      fixture = build_fixture(sequence_id, archive_count)
      site = create_site({}, { 'books' => fixture[:books] }, fixture[:author_pages])
      cache = site.data.fetch('link_cache')

      assert_cache_matches_document_scan(fixture, cache)
      assert_book_link_matches_document_scan(fixture, site)
      assert_identities_match_document_metadata(fixture[:books], site)
    end
  end

  private

  def build_fixture(sequence_id, archive_count)
    shared_title = "Shared Work #{sequence_id}"
    ada_url = "/books/shared-ada-#{sequence_id}/"
    bea_url = "/books/shared-bea-#{sequence_id}/"

    ada_archives = Array.new(archive_count) do |archive_index|
      create_doc(
        {
          'title' => shared_title,
          'published' => true,
          'book_authors' => ['Ada Pen Name'],
          'canonical_url' => ada_url,
        },
        "/books/shared-ada-#{sequence_id}/review-#{archive_index + 1}/",
      )
    end

    ada_canonical = create_doc(
      { 'title' => shared_title, 'published' => true, 'book_authors' => ['Ada Author'] },
      ada_url,
    )

    bea_archive = create_doc(
      {
        'title' => shared_title,
        'published' => true,
        'book_authors' => ['Bea Author'],
        'canonical_url' => bea_url,
      },
      "/books/shared-bea-#{sequence_id}/review/",
    )
    bea_canonical = create_doc(
      { 'title' => shared_title, 'published' => true, 'book_authors' => ['Bea Author'] },
      bea_url,
    )

    external_review = create_doc(
      {
        'title' => "External Edition #{sequence_id}",
        'published' => true,
        'book_authors' => ['Cora Author'],
        'canonical_url' => "https://publisher.example/books/external-#{sequence_id}/",
      },
      "/books/external-edition-#{sequence_id}/",
    )

    unpublished_archive = create_doc(
      {
        'title' => shared_title,
        'published' => false,
        'book_authors' => ['Ada Pen Name'],
        'canonical_url' => ada_url,
      },
      "/books/shared-ada-#{sequence_id}/draft-review/",
    )

    author_pages = [
      create_doc(
        { 'title' => 'Ada Author', 'layout' => 'author_page', 'pen_names' => ['Ada Pen Name'] },
        '/authors/ada-author.html',
      ),
      create_doc(
        { 'title' => 'Bea Author', 'layout' => 'author_page' },
        '/authors/bea-author.html',
      ),
    ]

    {
      title: shared_title,
      author_filter: '  ada pen name  ',
      books: ada_archives + [ada_canonical, bea_archive, bea_canonical, external_review, unpublished_archive],
      author_pages: author_pages,
      aliases: { 'ada author' => 'Ada Author', 'ada pen name' => 'Ada Author' },
    }
  end

  def assert_cache_matches_document_scan(fixture, cache)
    expected_entries = fixture[:books].select do |book|
      book.data['published'] != false && book.data['title'] == fixture[:title]
    end
    actual_entries = cache.dig('books', fixture[:title].downcase)
    actual_urls = actual_entries.map { |entry| entry.fetch('url') }

    assert_equal expected_entries.map(&:url), actual_urls
  end

  def assert_book_link_matches_document_scan(fixture, site)
    page = create_doc({ 'title' => 'Property Source' }, '/property-source.html')
    context = create_context({}, { site: site, page: page })
    expected_url = expected_candidate_from_scan(fixture)&.url

    actual = Jekyll::Books::Core::BookLinkResolver.new(context).resolve_data(
      fixture[:title],
      nil,
      fixture[:author_filter],
    )

    assert_equal :found, actual[:status]
    assert_equal expected_url, actual[:url]
  end

  def expected_candidate_from_scan(fixture)
    candidates = fixture[:books].select do |book|
      book.data['published'] != false &&
        book.data['title'] == fixture[:title] &&
        !book.data['canonical_url']&.start_with?('/')
    end
    requested_author = canonical_author_from_fixture(fixture[:author_filter], fixture[:aliases])

    candidates.find do |book|
      Array(book.data['book_authors']).any? do |author_name|
        canonical_author_from_fixture(author_name, fixture[:aliases]).casecmp(requested_author).zero?
      end
    end
  end

  def canonical_author_from_fixture(name, aliases)
    trimmed_name = name.to_s.strip
    aliases.fetch(trimmed_name.downcase, trimmed_name)
  end

  def assert_identities_match_document_metadata(books, site)
    books.each do |book|
      local_canonical = book.data['canonical_url']&.start_with?('/')
      is_indexed = book.data['published'] != false && !book.data['title'].to_s.strip.empty?
      expected_url = local_canonical && is_indexed ? book.data['canonical_url'] : book.url

      actual_url = Jekyll::SEO::BookIdentityResolver.resolve(book, site)
      assert_equal expected_url, actual_url, "identity for #{book.url}"
    end
  end
end
