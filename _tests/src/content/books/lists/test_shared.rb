# frozen_string_literal: true

# _tests/plugins/logic/book_lists/test_shared.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/lists/shared'

# Tests for Jekyll::Books::Lists::Shared module
#
# Tests the private helper methods that are shared across all BookList finder classes.
class TestBookListsShared < Minitest::Test
  # Create a test class that includes the module to test shared methods
  class SharedTester
    include Jekyll::Books::Lists::Shared
  end

  def setup
    @tester = SharedTester.new
  end

  def test_get_canonical_author_returns_nil_for_nil_name
    # Tests line 32: `return nil if name.nil? || name.to_s.strip.empty?`
    result = @tester.send(:get_canonical_author, nil, {})
    assert_nil result
  end

  def test_get_canonical_author_returns_nil_for_empty_name
    # Tests line 32: `return nil if name.nil? || name.to_s.strip.empty?`
    result = @tester.send(:get_canonical_author, '', {})
    assert_nil result
  end

  def test_get_canonical_author_returns_nil_for_whitespace_name
    # Tests line 32: `return nil if name.nil? || name.to_s.strip.empty?`
    result = @tester.send(:get_canonical_author, '   ', {})
    assert_nil result
  end

  def test_get_canonical_author_returns_canonical_title_when_in_cache
    # Tests normal path: returns data['title'] from cache
    cache = { 'john doe' => { 'title' => 'John Doe' } }
    result = @tester.send(:get_canonical_author, 'john doe', cache)
    assert_equal 'John Doe', result
  end

  def test_get_canonical_author_returns_stripped_name_when_not_in_cache
    # Tests else path: when name not in cache, returns stripped original
    result = @tester.send(:get_canonical_author, ' Unknown Author ', {})
    assert_equal 'Unknown Author', result
  end
end
