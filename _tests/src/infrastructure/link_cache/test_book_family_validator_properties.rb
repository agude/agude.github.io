# frozen_string_literal: true

require_relative '../../../test_helper'
require 'support/property_test'

# Compares family validation with a direct scan of document metadata: first
# the canonical_url format check (a local value must spell its target's url
# exactly), then the pairwise scan for canonical pages that set canonical_url.
class TestBookFamilyValidatorProperties < Minitest::Test
  include PropertyTestSupport

  Validator = Jekyll::Infrastructure::LinkCache::BookFamilyValidator
  Generators = PropCheck::Generators

  FAMILY_SHAPES_GENERATOR = Generators.tuple(
    Generators.choose(1..13),
    Generators.choose(0..2).map { |count| count + 1 },
    Generators.choose(0..3),
    Generators.choose(0..2).map { |length| length + 3 },
    Generators.choose(0..2),
  )

  INTERACTIONS = %w[
    valid_family_with_archives
    valid_family_without_archives
    family_slash_variant_rejected
    valid_family_external_canonical
    illegal_local_chain
    local_chain_slash_variant_rejected
  ].freeze

  # Names what a generated shape builds, from the shape's fields.
  def self.shape_interactions(shape)
    sequence_id, _canonical_count, archive_count, chain_length, external_count = shape
    names = []
    names << (archive_count.positive? ? 'valid_family_with_archives' : 'valid_family_without_archives')
    names << 'family_slash_variant_rejected' if archive_count.positive? && slash_variant_shape?(sequence_id)
    names << 'valid_family_external_canonical' if external_count.positive?
    names << 'illegal_local_chain' if chain_length >= 2
    names << 'local_chain_slash_variant_rejected' if slash_variant_shape?(sequence_id)
    names
  end

  # One shape in three spells its first local canonical_url without the
  # trailing slash, which the format check rejects before the pairwise scan.
  # The rest keep the pairwise scan reachable.
  def self.slash_variant_shape?(sequence_id)
    (sequence_id % 3).zero?
  end

  def test_validator_matches_scan_for_valid_families_and_local_chains
    check_property(
      FAMILY_SHAPES_GENERATOR,
      seed: 4401,
      classify: ->(shape) { self.class.shape_interactions(shape) },
      interactions: INTERACTIONS,
    ) do |shape|
      sequence_id, canonical_count, archive_count, chain_length, external_count = shape
      valid_books = build_valid_family(sequence_id, canonical_count, archive_count, external_count)
      assert_validation_matches_scan(valid_books)

      chain_books = build_local_chain(sequence_id, chain_length)
      assert_validation_matches_scan(chain_books)
    end
  end

  private

  def build_valid_family(sequence_id, canonical_count, archive_count, external_count)
    canonical_urls = Array.new(canonical_count) do |index|
      "/books/canonical-#{sequence_id}-#{index}/"
    end

    canonical_books = canonical_urls.each_with_index.map do |url, index|
      create_doc({ 'title' => "Canonical #{sequence_id}-#{index}" }, url)
    end

    archived_books = Array.new(archive_count) do |archive_index|
      target_index = (sequence_id + archive_index) % canonical_count
      target_url = canonical_urls[target_index]
      slash_variant = archive_index.zero? && self.class.slash_variant_shape?(sequence_id)
      canonical_url = slash_variant ? target_url.chomp('/') : target_url
      archive_url = "/books/archived-#{sequence_id}-#{archive_index}/"
      create_doc(
        {
          'title' => "Archived #{sequence_id}-#{archive_index}",
          'published' => true,
          'canonical_url' => canonical_url,
        },
        archive_url,
      )
    end

    external_books = Array.new(external_count) do |external_index|
      create_doc(
        {
          'title' => "External #{sequence_id}-#{external_index}",
          'published' => true,
          'canonical_url' => "https://books.example/#{sequence_id}/#{external_index}/",
        },
        "/books/external-#{sequence_id}-#{external_index}/",
      )
    end

    draft_book = create_doc(
      {
        'title' => "Draft #{sequence_id}",
        'published' => false,
        'canonical_url' => canonical_urls.first,
      },
      "/books/draft-#{sequence_id}/",
    )

    canonical_books + archived_books + external_books + [draft_book]
  end

  def build_local_chain(sequence_id, chain_length)
    urls = Array.new(chain_length) { |index| "/books/chain-#{sequence_id}-#{index}/" }

    chain_books = urls.each_with_index.map do |url, index|
      canonical_url = if index == chain_length - 1
                        nil
                      elsif index.zero? && self.class.slash_variant_shape?(sequence_id)
                        urls[index + 1].chomp('/')
                      else
                        urls[index + 1]
                      end

      create_doc(
        {
          'title' => "Chain #{sequence_id}-#{index}",
          'published' => true,
          'canonical_url' => canonical_url,
        },
        url,
      )
    end

    chain_books + [
      create_doc(
        {
          'title' => "External Target #{sequence_id}",
          'published' => true,
          'canonical_url' => "https://books.example/chain/#{sequence_id}/",
        },
        "/books/external-chain-#{sequence_id}/",
      ),
    ]
  end

  def assert_validation_matches_scan(books)
    error = validation_error(books)
    offender = books.find { |book| slash_variant_canonical?(book, books) }
    if offender
      refute_nil error
      assert_includes error.message, "canonical_url in '#{offender.relative_path}' is"
      assert_includes error.message, "but the book page's url is"
      return
    end

    expected_paths = books.select { |book| violation_by_pairwise_scan?(book, books) }
                          .map(&:relative_path)

    if expected_paths.empty?
      assert_nil error
    else
      refute_nil error
      assert_equal expected_paths, paths_reported_by(error)
    end
  end

  # A local canonical_url that names a book page but not with that page's
  # exact url, differing only in the trailing slash.
  def slash_variant_canonical?(book, books)
    value = book.data['canonical_url']
    return false unless value.is_a?(String) && value.start_with?('/')

    books.any? { |target| target.url != value && target.url.chomp('/') == value.chomp('/') }
  end

  def violation_by_pairwise_scan?(candidate, books)
    return false if candidate.data['published'] == false
    return false unless candidate.data['canonical_url']

    books.any? do |source|
      next false if source.data['published'] == false

      target_url = source.data['canonical_url']
      target_url&.start_with?('/') && target_url.chomp('/') == candidate.url.chomp('/')
    end
  end

  def validation_error(books)
    Validator.new(site_with_books(books)).validate
    nil
  rescue Jekyll::Errors::FatalException => e
    e
  end

  def site_with_books(books)
    MockSite.new(
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
  end

  def paths_reported_by(error)
    error.message.lines.filter_map do |line|
      match = line.match(/^\s+- (.+?) \(url:/)
      match && match[1]
    end
  end
end
