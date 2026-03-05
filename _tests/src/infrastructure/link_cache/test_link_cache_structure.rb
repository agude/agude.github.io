# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/infrastructure/link_cache_generator'

# Integration test asserting that initialize_cache produces the expected
# structure. Adding or removing a key forces a test update.
class TestLinkCacheStructure < Minitest::Test
  EXPECTED_KEYS = %w[
    authors
    backlinks
    book_families
    books
    books_topbar_nav
    favorites_mentions
    favorites_posts_to_books
    series
    series_map
    short_stories
    sidebar_nav
    url_to_canonical_map
  ].freeze

  HASH_KEYS = %w[
    authors
    backlinks
    book_families
    books
    favorites_mentions
    favorites_posts_to_books
    series
    series_map
    short_stories
    url_to_canonical_map
  ].freeze

  ARRAY_KEYS = %w[
    books_topbar_nav
    sidebar_nav
  ].freeze

  def setup
    site = create_site
    @cache = site.data['link_cache']
  end

  def test_initialize_cache_returns_all_expected_keys
    assert_equal EXPECTED_KEYS, @cache.keys.sort
  end

  def test_type_keys_cover_all_expected_keys
    assert_equal EXPECTED_KEYS, (HASH_KEYS + ARRAY_KEYS).sort
  end

  def test_hash_keys_have_hash_defaults
    HASH_KEYS.each do |key|
      assert_instance_of Hash, @cache[key], "Expected '#{key}' to be a Hash"
    end
  end

  def test_array_keys_have_array_defaults
    ARRAY_KEYS.each do |key|
      assert_instance_of Array, @cache[key], "Expected '#{key}' to be an Array"
    end
  end

  def test_book_families_auto_vivifies_empty_array
    result = @cache['book_families']['nonexistent_key']
    assert_equal [], result
  end
end
