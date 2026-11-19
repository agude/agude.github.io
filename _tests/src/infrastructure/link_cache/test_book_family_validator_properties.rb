# frozen_string_literal: true

require_relative '../../../test_helper'
require 'support/property_test'

# Compares family validation with a direct pairwise scan of document metadata.
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

  def test_validator_matches_scan_for_valid_families_and_local_chains
    check_property(FAMILY_SHAPES_GENERATOR, seed: 4401) do |shape|
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
      canonical_url = (sequence_id + archive_index).even? ? target_url.chomp('/') : target_url
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
                      elsif (sequence_id + index).even?
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
    expected_paths = books.select { |book| violation_by_pairwise_scan?(book, books) }
                          .map(&:relative_path)
    error = validation_error(books)

    if expected_paths.empty?
      assert_nil error
    else
      refute_nil error
      assert_equal expected_paths, paths_reported_by(error)
    end
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
