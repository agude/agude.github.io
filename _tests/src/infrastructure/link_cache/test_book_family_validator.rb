# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::Infrastructure::LinkCache::BookFamilyValidator
#
# Verifies that the validator breaks the build when a canonical book page
# (one referenced by another book's canonical_url) also has canonical_url
# set in its own front matter.
class TestBookFamilyValidator < Minitest::Test
  # --- Unit tests for validate ---

  def test_canonical_page_without_canonical_url_passes
    canonical = create_doc(
      { 'title' => 'Hyperion', 'published' => true },
      '/books/hyperion/',
    )
    archived = create_doc(
      {
        'title' => 'Hyperion',
        'published' => true,
        'canonical_url' => '/books/hyperion/',
      },
      '/books/hyperion/review-2023-10-17/',
    )
    validator = build_validator([canonical, archived])

    # Should not raise
    validator.validate
  end

  def test_canonical_page_with_canonical_url_raises
    canonical = create_doc(
      {
        'title' => 'Hyperion',
        'published' => true,
        'canonical_url' => '/books/something-else/',
      },
      '/books/hyperion/',
    )
    archived = create_doc(
      {
        'title' => 'Hyperion',
        'published' => true,
        'canonical_url' => '/books/hyperion/',
      },
      '/books/hyperion/review-2023-10-17/',
    )
    validator = build_validator([canonical, archived])

    error = assert_raises(Jekyll::Errors::FatalException) { validator.validate }
    assert_includes error.message, 'BookFamilyValidator'
    assert_includes error.message, 'canonical_url'
  end

  def test_canonical_page_with_self_referencing_canonical_url_raises
    canonical = create_doc(
      {
        'title' => 'Hyperion',
        'published' => true,
        'canonical_url' => '/books/hyperion/',
      },
      '/books/hyperion/',
    )
    archived = create_doc(
      {
        'title' => 'Hyperion',
        'published' => true,
        'canonical_url' => '/books/hyperion/',
      },
      '/books/hyperion/review-2023-10-17/',
    )
    validator = build_validator([canonical, archived])

    error = assert_raises(Jekyll::Errors::FatalException) { validator.validate }
    assert_includes error.message, 'BookFamilyValidator'
  end

  def test_standalone_book_without_canonical_url_passes
    book = create_doc(
      { 'title' => 'Hyperion', 'published' => true },
      '/books/hyperion/',
    )
    validator = build_validator([book])

    # Should not raise — no family, no canonical_url
    validator.validate
  end

  def test_multiple_violations_all_reported
    canonical_a = create_doc(
      {
        'title' => 'Book A',
        'published' => true,
        'canonical_url' => '/books/x/',
      },
      '/books/a/',
    )
    archived_a = create_doc(
      {
        'title' => 'Book A',
        'published' => true,
        'canonical_url' => '/books/a/',
      },
      '/books/a/old/',
    )
    canonical_b = create_doc(
      {
        'title' => 'Book B',
        'published' => true,
        'canonical_url' => '/books/y/',
      },
      '/books/b/',
    )
    archived_b = create_doc(
      {
        'title' => 'Book B',
        'published' => true,
        'canonical_url' => '/books/b/',
      },
      '/books/b/old/',
    )
    validator = build_validator([canonical_a, archived_a, canonical_b, archived_b])

    error = assert_raises(Jekyll::Errors::FatalException) { validator.validate }
    assert_includes error.message, '/books/a/'
    assert_includes error.message, '/books/b/'
  end

  def test_published_archived_with_unpublished_canonical_is_ignored
    # Archived book creates a canonical target, but the canonical book is
    # unpublished so it's excluded from iteration — no error.
    canonical = create_doc(
      {
        'title' => 'Draft',
        'published' => false,
        'canonical_url' => '/books/draft/',
      },
      '/books/draft/',
    )
    archived = create_doc(
      {
        'title' => 'Draft',
        'published' => true,
        'canonical_url' => '/books/draft/',
      },
      '/books/draft/old/',
    )
    validator = build_validator([canonical, archived])

    validator.validate
  end

  def test_unpublished_archived_with_published_canonical_is_ignored
    # Archived book is unpublished so no canonical target is created — no
    # error even though the canonical book has canonical_url.
    canonical = create_doc(
      {
        'title' => 'Draft',
        'published' => true,
        'canonical_url' => '/books/somewhere-else/',
      },
      '/books/draft/',
    )
    archived = create_doc(
      {
        'title' => 'Draft',
        'published' => false,
        'canonical_url' => '/books/draft/',
      },
      '/books/draft/old/',
    )
    validator = build_validator([canonical, archived])

    validator.validate
  end

  def test_external_canonical_url_is_ignored
    # External canonical_url should not pollute the canonical_targets set.
    archived = create_doc(
      {
        'title' => 'Hyperion',
        'published' => true,
        'canonical_url' => 'https://example.com/books/hyperion/',
      },
      '/books/hyperion/old/',
    )
    canonical = create_doc(
      { 'title' => 'Hyperion', 'published' => true },
      '/books/hyperion/',
    )
    validator = build_validator([archived, canonical])

    validator.validate
  end

  def test_no_books_collection_does_not_raise
    site = create_site({}, {}, [])
    validator = Jekyll::Infrastructure::LinkCache::BookFamilyValidator.new(site)

    # Should not raise
    validator.validate
  end

  def test_error_message_includes_file_path
    canonical = create_doc(
      {
        'title' => 'Hyperion',
        'published' => true,
        'canonical_url' => '/books/hyperion/',
      },
      '/books/hyperion/',
    )
    archived = create_doc(
      {
        'title' => 'Hyperion',
        'published' => true,
        'canonical_url' => '/books/hyperion/',
      },
      '/books/hyperion/old/',
    )
    validator = build_validator([canonical, archived])

    error = assert_raises(Jekyll::Errors::FatalException) { validator.validate }
    assert_includes error.message, canonical.relative_path
  end

  # --- Integration tests through create_site ---

  def test_integration_canonical_with_canonical_url_breaks_build
    canonical = create_doc(
      {
        'title' => 'Hyperion',
        'published' => true,
        'canonical_url' => '/books/hyperion/',
      },
      '/books/hyperion/',
    )
    archived = create_doc(
      {
        'title' => 'Hyperion',
        'published' => true,
        'canonical_url' => '/books/hyperion/',
      },
      '/books/hyperion/old/',
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [canonical, archived] })
    end

    assert_includes error.message, 'BookFamilyValidator'
  end

  def test_integration_proper_family_passes
    canonical = create_doc(
      { 'title' => 'Hyperion', 'published' => true },
      '/books/hyperion/',
    )
    archived = create_doc(
      {
        'title' => 'Hyperion',
        'published' => true,
        'canonical_url' => '/books/hyperion/',
      },
      '/books/hyperion/review-2023-10-17/',
    )

    # Should not raise
    site = create_site({}, { 'books' => [canonical, archived] })
    refute_nil site.data['link_cache']
  end

  private

  def build_validator(books)
    site = MockSite.new(
      build_test_site_config({}),
      { 'books' => MockCollection.new(books, 'books') },
      [],
      MockCollection.new([], 'posts'),
      '',
      '',
      [create_mock_converter({})],
      {},
      {},
    )
    Jekyll::Infrastructure::LinkCache::BookFamilyValidator.new(site)
  end
end
