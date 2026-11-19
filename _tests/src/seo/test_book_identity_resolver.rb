# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../_plugins/src/seo/book_identity_resolver'

# Tests for Jekyll::SEO::BookIdentityResolver.
class TestBookIdentityResolver < Minitest::Test
  def setup
    @canonical_review = create_doc(
      { 'title' => 'Canonical Review', 'book_authors' => ['Author'] },
      '/books/canonical-review/',
    )
    @archived_review = create_doc(
      {
        'title' => 'Canonical Review',
        'book_authors' => ['Author'],
        'canonical_url' => '/books/canonical-review/',
      },
      '/books/archived-review/',
    )
    @external_review = create_doc(
      {
        'title' => 'External Review',
        'book_authors' => ['Author'],
        'canonical_url' => 'https://other.example/books/external-review/',
      },
      '/books/external-review/',
    )
    @original_antimemetics = create_doc(
      { 'title' => 'There Is No Antimemetics Division (Original Edition)' },
      '/books/there-is-no-antimemetics-division-original/',
    )
    @revised_antimemetics = create_doc(
      { 'title' => 'There Is No Antimemetics Division' },
      '/books/there-is-no-antimemetics-division/',
    )
    @site = create_site(
      {},
      {
        'books' => [
          @canonical_review,
          @archived_review,
          @external_review,
          @original_antimemetics,
          @revised_antimemetics,
        ],
      },
    )
  end

  def test_canonical_review_resolves_to_its_own_url
    assert_equal @canonical_review.url, resolve(@canonical_review)
  end

  def test_archived_review_resolves_to_local_canonical_url
    assert_equal @canonical_review.url, resolve(@archived_review)
  end

  # The resolver trims canonical_url only to classify it as local. A padded
  # value would become a padded identity, so the link cache build stops first.
  def test_padded_local_canonical_url_stops_the_build
    padded = create_doc(
      {
        'title' => 'Padded Review',
        'book_authors' => ['Author'],
        'canonical_url' => ' /books/canonical-review/ ',
      },
      '/books/padded-review/',
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [@canonical_review, padded] })
    end
    assert_includes error.message, 'leading or trailing whitespace'
  end

  # The resolver alone still classifies a padded local path as local; the
  # validator, not the resolver, is what rejects the padding.
  def test_padded_local_canonical_url_is_local_to_the_resolver
    review = create_doc({}, '/books/padded-review/')
    map = { '/books/padded-review/' => ' /books/canonical-review/ ' }
    site = Struct.new(:data).new({ 'link_cache' => { 'url_to_canonical_map' => map } })

    assert_equal ' /books/canonical-review/ ', Jekyll::SEO::BookIdentityResolver.resolve(review, site)
  end

  def test_external_canonical_url_does_not_become_book_identity
    assert_equal @external_review.url, resolve(@external_review)
  end

  def test_missing_or_blank_review_url_has_no_identity
    assert_nil resolve(nil)
    assert_nil resolve(create_doc({}, ' '))
  end

  def test_missing_site_data_falls_back_to_review_url
    resolver = Jekyll::SEO::BookIdentityResolver

    assert_equal @archived_review.url, resolver.resolve(@archived_review, nil)
    assert_equal @archived_review.url, resolver.resolve(@archived_review, Struct.new(:data).new({}))
  end

  def test_antimemetics_reviews_keep_separate_book_identities
    refute_equal resolve(@original_antimemetics), resolve(@revised_antimemetics)
    assert_equal @original_antimemetics.url, resolve(@original_antimemetics)
    assert_equal @revised_antimemetics.url, resolve(@revised_antimemetics)
  end

  def test_resolution_does_not_mutate_document_or_cache
    canonical_map_before = @site.data['link_cache']['url_to_canonical_map'].dup
    families_before = @site.data['link_cache']['book_families'].transform_values(&:dup)
    data_before = @archived_review.data.dup

    resolve(@archived_review)

    assert_equal canonical_map_before, @site.data['link_cache']['url_to_canonical_map']
    assert_equal families_before, @site.data['link_cache']['book_families']
    assert_equal data_before, @archived_review.data
  end

  private

  def resolve(document)
    Jekyll::SEO::BookIdentityResolver.resolve(document, @site)
  end
end
