# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/infrastructure/link_cache/author_lookup'

# Tests for Jekyll::Infrastructure::LinkCache::AuthorLookup
class TestAuthorLookup < Minitest::Test
  Lookup = Jekyll::Infrastructure::LinkCache::AuthorLookup

  def test_returns_nil_for_nil_name
    assert_nil Lookup.canonical_author(nil, {})
  end

  def test_returns_nil_for_empty_name
    assert_nil Lookup.canonical_author('', {})
  end

  def test_returns_nil_for_whitespace_name
    assert_nil Lookup.canonical_author('   ', {})
  end

  def test_returns_canonical_title_when_in_cache
    cache = { 'john doe' => { 'title' => 'John Doe' } }
    assert_equal 'John Doe', Lookup.canonical_author('john doe', cache)
  end

  def test_lookup_normalizes_case_and_whitespace
    cache = { 'john doe' => { 'title' => 'John Doe' } }
    assert_equal 'John Doe', Lookup.canonical_author("  John\nDOE  ", cache)
  end

  def test_returns_stripped_name_when_not_in_cache
    assert_equal 'Unknown Author', Lookup.canonical_author(' Unknown Author ', {})
  end
end
