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

  # canonical_url names the canonical review of a book family on this site;
  # anything that is not a local path stops the build.
  def test_non_local_canonical_url_raises
    ['https://example.com/books/hyperion/', '//example.com/books/hyperion/', 'books/hyperion/'].each do |value|
      archived = create_doc(
        { 'title' => 'Hyperion', 'published' => true, 'canonical_url' => value },
        '/books/hyperion/old/',
      )
      canonical = create_doc({ 'title' => 'Hyperion', 'published' => true }, '/books/hyperion/')

      error = assert_raises(Jekyll::Errors::FatalException, value) do
        build_validator([archived, canonical]).validate
      end
      assert_includes error.message, archived.relative_path
      assert_includes error.message, "is not a local path: #{value.inspect}"
    end
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

  def test_error_message_names_each_violation_path_and_url
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
    assert_includes error.message, "  - #{canonical.relative_path} (url: /books/hyperion/)\n"
  end

  def test_book_without_published_key_is_not_treated_as_unpublished
    # A missing `published` key means the book is published, so the
    # canonical page without it is still checked and reported.
    canonical = create_doc(
      { 'title' => 'Hyperion', 'canonical_url' => '/books/somewhere-else/' },
      '/books/hyperion/',
    )
    # create_doc adds `published: true` by default; remove it to model
    # front matter that has no `published` key.
    canonical.data.delete('published')
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

  # The resolver trims canonical_url to detect a local path but keeps the
  # padded value as identity, so the padding must stop the build.
  def test_canonical_url_with_surrounding_whitespace_raises
    canonical = create_doc(
      { 'title' => 'Canonical Review', 'published' => true },
      '/books/canonical-review/',
    )
    archived = create_doc(
      {
        'title' => 'Canonical Review',
        'published' => true,
        'canonical_url' => ' /books/canonical-review/ ',
      },
      '/books/canonical-review/old/',
    )
    validator = build_validator([canonical, archived])

    error = assert_raises(Jekyll::Errors::FatalException) { validator.validate }
    assert_includes error.message, archived.relative_path
    assert error.message.end_with?(
      %(has leading or trailing whitespace: " /books/canonical-review/ ". Remove the whitespace.),
    ),
           error.message
  end

  def test_canonical_url_with_only_leading_or_only_trailing_whitespace_raises
    [' /books/canonical-review/', '/books/canonical-review/ '].each do |padded|
      canonical = create_doc({ 'title' => 'Canonical Review', 'published' => true }, '/books/canonical-review/')
      archived = create_doc(
        { 'title' => 'Canonical Review', 'published' => true, 'canonical_url' => padded },
        '/books/canonical-review/old/',
      )

      error = assert_raises(Jekyll::Errors::FatalException) { build_validator([canonical, archived]).validate }
      assert_includes error.message, 'leading or trailing whitespace', padded.inspect
    end
  end

  def test_format_check_reaches_books_after_a_valid_canonical_url
    canonical = create_doc({ 'title' => 'Page', 'published' => true }, '/books/page/')
    valid = create_doc(
      { 'title' => 'Page', 'published' => true, 'canonical_url' => '/books/page/' },
      '/books/page-a/',
    )
    slashless = create_doc(
      { 'title' => 'Page', 'published' => true, 'canonical_url' => '/books/page' },
      '/books/page-b/',
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      build_validator([canonical, valid, slashless]).validate
    end
    assert_includes error.message, slashless.relative_path
  end

  # A slashless local path never equals the canonical page's url, so the
  # archive would get its own book identity and split the family.
  def test_local_canonical_url_without_trailing_slash_raises
    canonical = create_doc(
      { 'title' => 'Canonical Review', 'published' => true },
      '/books/canonical-review/',
    )
    archived = create_doc(
      {
        'title' => 'Canonical Review',
        'published' => true,
        'canonical_url' => '/books/canonical-review',
      },
      '/books/canonical-review/old/',
    )
    validator = build_validator([canonical, archived])

    error = assert_raises(Jekyll::Errors::FatalException) { validator.validate }
    assert_includes error.message, archived.relative_path
    assert_includes error.message, %(is "/books/canonical-review", but the book page's url is "/books/canonical-review/")
  end

  def test_local_canonical_url_with_an_extra_trailing_slash_raises
    canonical = create_doc({ 'title' => 'Page', 'published' => true }, '/books/page.html')
    archived = create_doc(
      { 'title' => 'Page', 'published' => true, 'canonical_url' => '/books/page.html/' },
      '/books/page-old.html',
    )

    error = assert_raises(Jekyll::Errors::FatalException) { build_validator([canonical, archived]).validate }
    assert_includes error.message, 'Use "/books/page.html"'
  end

  def test_exact_local_canonical_url_without_trailing_slash_is_allowed
    # Only a mismatch with a real book url splits a family; an exact match
    # is fine whatever its form.
    # Equal but distinct strings: the check compares values, not identity.
    canonical = create_doc({ 'title' => 'Page', 'published' => true }, String.new('/books/page.html'))
    archived = create_doc(
      { 'title' => 'Page', 'published' => true, 'canonical_url' => String.new('/books/page.html') },
      '/books/page-old.html',
    )

    build_validator([canonical, archived]).validate
  end

  def test_exact_slashless_canonical_target_that_sets_canonical_url_raises
    # The family check must treat any local value as a target, not only one
    # ending in a slash.
    target = create_doc(
      { 'title' => 'Page', 'published' => true, 'canonical_url' => '/books/elsewhere.html' },
      '/books/page.html',
    )
    archived = create_doc(
      { 'title' => 'Page', 'published' => true, 'canonical_url' => '/books/page.html' },
      '/books/page-old.html',
    )

    error = assert_raises(Jekyll::Errors::FatalException) { build_validator([target, archived]).validate }
    assert_includes error.message, "#{target.relative_path} (url: /books/page.html)"
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
