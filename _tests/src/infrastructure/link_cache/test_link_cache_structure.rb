# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/infrastructure/link_cache_generator'

# Integration test asserting that initialize_cache produces the expected
# structure. Adding or removing a key, or changing a default's type, forces
# a test update.
class TestLinkCacheStructure < Minitest::Test
  EXPECTED_TYPES = {
    'authors' => Hash,
    'backlinks' => Hash,
    'book_families' => Hash,
    'books' => Hash,
    'books_topbar_nav' => Array,
    'favorites_mentions' => Hash,
    'favorites_posts_to_books' => Hash,
    'forward_links' => Hash,
    'series' => Hash,
    'series_map' => Hash,
    'short_stories' => Hash,
    'sidebar_nav' => Array,
    'url_to_canonical_map' => Hash,
  }.freeze

  def setup
    site = create_site
    @cache = site.data['link_cache']
  end

  def test_cache_keys_and_default_types
    assert_equal EXPECTED_TYPES.keys.sort, @cache.keys.sort

    EXPECTED_TYPES.each do |key, type|
      assert_kind_of type, @cache[key], "Expected '#{key}' to be a #{type}"
    end
  end

  def test_book_families_auto_vivifies_empty_array
    result = @cache['book_families']['nonexistent_key']
    assert_equal [], result
  end
end
