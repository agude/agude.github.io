# frozen_string_literal: true

# _tests/plugins/logic/previous_reviews/test_finder.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/reviews/finder'

# Tests for Jekyll::PreviousReviews::Finder.
#
# Verifies that the Finder correctly locates and sorts archived reviews.
class TestPreviousReviewsFinder < Minitest::Test
  def setup
    setup_test_documents
    setup_site_and_logger
  end

  def test_returns_empty_reviews_when_no_archived_reviews
    context = create_context({}, { site: @site, page: @unrelated_book })
    finder = Jekyll::PreviousReviews::Finder.new(context)
    result = finder.find

    assert_equal '', result[:logs]
    assert_equal [], result[:reviews]
  end

  def test_finds_and_sorts_archived_reviews_by_date_descending
    context = create_context({}, { site: @site, page: @canonical_page })
    finder = Jekyll::PreviousReviews::Finder.new(context)
    result = finder.find

    assert_equal '', result[:logs]
    assert_equal 2, result[:reviews].length
    assert_equal @archive_new, result[:reviews][0] # Newest first
    assert_equal @archive_old, result[:reviews][1] # Oldest second
  end

  def test_returns_error_when_prerequisites_missing
    context_no_page = create_context({}, { site: @site }) # No page
    finder = Jekyll::PreviousReviews::Finder.new(context_no_page)
    result = nil

    Jekyll.stub :logger, @silent_logger_stub do
      result = finder.find
    end

    refute_empty result[:logs]
    assert_match(/PREVIOUS_REVIEWS_FAILURE/, result[:logs])
    assert_match(/Prerequisites missing/, result[:logs])
    assert_equal [], result[:reviews]
  end

  def test_does_not_include_page_itself_in_results
    # Even if the canonical page has canonical_url pointing to itself
    @canonical_page.data['canonical_url'] = '/books/canonical.html'

    context = create_context({}, { site: @site, page: @canonical_page })
    finder = Jekyll::PreviousReviews::Finder.new(context)
    result = finder.find

    # Should only find the two archive documents, not the canonical page
    assert_equal 2, result[:reviews].length
    assert_includes result[:reviews], @archive_new
    assert_includes result[:reviews], @archive_old
    refute_includes result[:reviews], @canonical_page
  end

  private

  def setup_test_documents
    # The main page the tag will be rendered on
    @canonical_page = create_doc({ 'title' => 'Canonical Book' }, '/books/canonical.html')

    # Archived reviews that point to the canonical page
    @archive_new = create_doc({
                                'title' => 'Archived (New)',
                                'date' => Time.parse('2023-01-01'),
                                'canonical_url' => '/books/canonical.html'
                              }, '/books/archive-new.html')

    @archive_old = create_doc({
                                'title' => 'Archived (Old)',
                                'date' => Time.parse('2022-01-01'),
                                'canonical_url' => '/books/canonical.html'
                              }, '/books/archive-old.html')

    # An unrelated book that should be ignored
    @unrelated_book = create_doc({ 'title' => 'Unrelated' }, '/books/unrelated.html')
  end

  def setup_site_and_logger
    # Create the site with the books collection already populated
    all_books = [@canonical_page, @archive_new, @archive_old, @unrelated_book]
    @site = create_site({}, { 'books' => all_books })
    @site.config['plugin_logging']['PREVIOUS_REVIEWS'] = true

    # Silent logger for tests not asserting specific console output
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
  end
end
