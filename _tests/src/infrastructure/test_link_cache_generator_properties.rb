# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../_plugins/src/seo/book_identity_resolver'

# Exhaustive structural checks of cache building, book-link resolution, and
# book identity. Each case is a book-family shape; the expected results are
# derived from the front matter of the generated documents, not from
# production helpers.
class TestLinkCacheGeneratorProperties < Minitest::Test
  SHARED_TITLE = 'Shared Work'
  ADA_CANONICAL_URL = '/books/shared-work/'
  BEA_CANONICAL_URL = '/books/shared-work-bea/'

  # Dimensions. Each combination is one case.
  ARCHIVE_COUNTS = [0, 1, 2].freeze
  BEA_FAMILY_PRESENT = [true, false].freeze
  AUTHOR_FILTERS = ['  ada pen name  ', 'ADA AUTHOR', nil, 'Nobody Here'].freeze
  ARCHIVES_FIRST = [true, false].freeze
  UNPUBLISHED_ARCHIVE_PRESENT = [true, false].freeze

  FamilyCase = Struct.new(
    :archive_count,
    :bea_family,
    :author_filter,
    :archives_first,
    :unpublished_archive,
  )

  CASES = ARCHIVE_COUNTS
          .product(BEA_FAMILY_PRESENT, AUTHOR_FILTERS, ARCHIVES_FIRST, UNPUBLISHED_ARCHIVE_PRESENT)
          .map { |values| FamilyCase.new(*values) }
          .freeze

  # 3 * 2 * 4 * 2 * 2 = 96 cases. They cover 23 distinct document
  # structures: with no archive and no Bea family, document order has no
  # effect, so the two orders produce the same fixture. A canonical_url that
  # names another site stops the build (BookFamilyValidator), so no case has
  # one.
  EXPECTED_CASE_COUNT = 96
  EXPECTED_DISTINCT_STRUCTURES = 23

  def test_generated_families_resolve_from_document_metadata
    assert_equal EXPECTED_CASE_COUNT, CASES.length
    distinct = CASES.map { |test_case| structure_key(build_fixture(test_case)) }.uniq.length
    assert_equal EXPECTED_DISTINCT_STRUCTURES, distinct

    CASES.each { |test_case| check_case(test_case) }
  end

  private

  def check_case(test_case)
    fixture = build_fixture(test_case)
    site = create_site({}, { 'books' => fixture[:books] }, fixture[:author_pages])
    cache = site.data.fetch('link_cache')

    assert_cache_matches_document_scan(fixture, cache)
    assert_book_link_matches_document_scan(test_case, fixture, site)
    assert_identities_match_document_metadata(fixture[:books], site)
  rescue Minitest::Assertion, StandardError => e
    detail = e.is_a?(Minitest::Assertion) ? e.message : "#{e.class}: #{e.message}"
    raise Minitest::Assertion, "#{format_case(test_case)}\n#{detail}"
  end

  def format_case(test_case)
    'case: ' \
      "archive_count=#{test_case.archive_count}, " \
      "bea_family=#{test_case.bea_family}, " \
      "author_filter=#{test_case.author_filter.inspect}, " \
      "archives_first=#{test_case.archives_first}, " \
      "unpublished_archive=#{test_case.unpublished_archive}"
  end

  def build_fixture(test_case)
    ada_family = family_documents(
      canonical: create_doc(
        { 'title' => SHARED_TITLE, 'published' => true, 'book_authors' => ['Ada Author'] },
        ADA_CANONICAL_URL,
      ),
      archives: ada_archives(test_case),
      archives_first: test_case.archives_first,
    )

    bea_family = test_case.bea_family ? bea_documents(test_case.archives_first) : []

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
      author_filter: test_case.author_filter,
      author_pages: author_pages,
      books: ada_family + bea_family,
    }
  end

  def ada_archives(test_case)
    archives = Array.new(test_case.archive_count) do |index|
      archive_doc(
        url: "/books/shared-work/review-#{index + 1}/",
        published: true,
        authors: ['Ada Pen Name'],
        canonical_url: ADA_CANONICAL_URL,
      )
    end
    if test_case.unpublished_archive
      archives << archive_doc(
        url: '/books/shared-work/draft-review/',
        published: false,
        authors: ['Ada Pen Name'],
        canonical_url: ADA_CANONICAL_URL,
      )
    end
    archives
  end

  def bea_documents(archives_first)
    canonical = create_doc(
      { 'title' => SHARED_TITLE, 'published' => true, 'book_authors' => ['Bea Author'] },
      BEA_CANONICAL_URL,
    )
    archive = archive_doc(
      url: '/books/shared-work-bea/review/',
      published: true,
      authors: ['Bea Author'],
      canonical_url: BEA_CANONICAL_URL,
    )
    family_documents(canonical: canonical, archives: [archive], archives_first: archives_first)
  end

  def archive_doc(url:, published:, authors:, canonical_url:)
    create_doc(
      {
        'title' => SHARED_TITLE,
        'published' => published,
        'book_authors' => authors,
        'canonical_url' => canonical_url,
      },
      url,
    )
  end

  # Document order: archives either all before or all after their canonical page.
  def family_documents(canonical:, archives:, archives_first:)
    archives_first ? archives + [canonical] : [canonical] + archives
  end

  def structure_key(fixture)
    fixture[:books].map do |book|
      [book.url, book.data['published'], book.data['canonical_url'], book.data['title'], book.data['book_authors']]
    end
  end

  # Mirrors the documented contract: a review is an archive when its
  # canonical_url is a local path. Archives never reach book_link.
  def indexed?(book)
    book.data['published'] != false
  end

  def archive?(book)
    book.data['canonical_url'].to_s.start_with?('/')
  end

  def assert_cache_matches_document_scan(fixture, cache)
    expected = fixture[:books]
               .select { |book| indexed?(book) }
               .group_by { |book| book.data['title'].downcase }
               .transform_values { |books| books.map(&:url) }
    actual = cache.fetch('books').transform_values { |entries| entries.map { |entry| entry.fetch('url') } }

    assert_equal expected, actual
  end

  def assert_book_link_matches_document_scan(test_case, fixture, site)
    page = create_doc({ 'title' => 'Property Source' }, '/property-source.html')
    context = create_context({}, { site: site, page: page })
    resolver = Jekyll::Books::Core::BookLinkResolver.new(context)
    expected_status, expected_url = expected_link(test_case, fixture)

    if expected_status == :ambiguous
      assert_raises(Jekyll::Errors::FatalException) do
        resolver.resolve_data(SHARED_TITLE, nil, test_case.author_filter)
      end
      return
    end

    actual = resolver.resolve_data(SHARED_TITLE, nil, test_case.author_filter)
    assert_equal expected_status, actual[:status]
    expected_url ? assert_equal(expected_url, actual[:url]) : assert_nil(actual[:url])
  end

  # @return [Array] [:ambiguous], [:found, url], or [:not_found, nil].
  def expected_link(test_case, fixture)
    candidates = fixture[:books].select do |book|
      indexed?(book) && book.data['title'] == SHARED_TITLE && !archive?(book)
    end
    requested = author_name_from_metadata(test_case.author_filter, fixture)

    return [:ambiguous, nil] if requested.nil? && candidates.length > 1
    return [:found, candidates.first.url] if requested.nil?

    match = candidates.find do |book|
      Array(book.data['book_authors']).any? do |author|
        author_name_from_metadata(author, fixture) == requested
      end
    end
    match ? [:found, match.url] : [:not_found, nil]
  end

  # Canonical author name from the author pages' title and pen_names, or nil
  # for a blank name. Names are compared case-insensitively.
  def author_name_from_metadata(name, fixture)
    stripped = name.to_s.strip
    return nil if stripped.empty?

    fixture[:author_pages].each do |page|
      canonical = page.data['title']
      names = [canonical, *Array(page.data['pen_names'])]
      return canonical if names.any? { |candidate| candidate.casecmp?(stripped) }
    end
    stripped
  end

  def assert_identities_match_document_metadata(books, site)
    books.each do |book|
      expected_url = expected_identity(book)
      actual_url = Jekyll::SEO::BookIdentityResolver.resolve(book, site)
      assert_equal expected_url, actual_url, "identity for #{book.url}"
    end
  end

  def expected_identity(book)
    canonical_url = book.data['canonical_url']
    local_canonical = canonical_url.to_s.start_with?('/')
    local_canonical && indexed?(book) && !book.data['title'].to_s.strip.empty? ? canonical_url : book.url
  end
end
