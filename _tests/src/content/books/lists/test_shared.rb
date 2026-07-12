# frozen_string_literal: true

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

  def test_log_filter_warning_returns_warn_log_html
    set_logging_context
    result = @tester.send(
      :log_filter_warning,
      tag_type: 'SHARED_TEST',
      reason: 'Filter was empty.',
      identifiers: { FilterInput: 'N/A' },
    )
    assert_match(/\[WARN\] SHARED_TEST_FAILURE: Reason='Filter was empty\.'/, result)
    assert_match(%r{FilterInput='N/A'}, result)
    refute_predicate result, :frozen?
  end

  def test_log_no_results_returns_info_log_html
    set_logging_context
    result = @tester.send(
      :log_no_results,
      tag_type: 'SHARED_TEST',
      reason: 'No results found.',
    )
    assert_match(/\[INFO\] SHARED_TEST_FAILURE: Reason='No results found\.'/, result)
    refute_predicate result, :frozen?
  end

  private

  def set_logging_context
    site = create_site(
      {
        'environment' => 'test',
        'plugin_log_level' => 'debug',
        'plugin_logging' => { 'SHARED_TEST' => true },
      },
    )
    page = create_doc({ 'path' => 'shared_test.html' }, '/shared_test.html')
    context = create_context({}, { site: site, page: page })
    @tester.instance_variable_set(:@context, context)
  end
end
