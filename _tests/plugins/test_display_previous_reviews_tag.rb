# frozen_string_literal: true

# _tests/plugins/test_display_previous_reviews_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_previous_reviews_tag'

# Tests for DisplayPreviousReviewsTag Liquid tag.
#
# Verifies that the tag correctly finds and displays previous reviews of the same book.
class TestDisplayPreviousReviewsTag < Minitest::Test
  def setup
    setup_test_documents
    setup_site_and_logger
  end

  def render_tag(page)
    context = create_context({}, { site: @site, page: page })
    Liquid::Template.parse('{% display_previous_reviews %}').render!(context)
  end

  def test_syntax_error_with_arguments
    assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_previous_reviews some_arg %}')
    end
  end

  def test_renders_nothing_when_no_archived_reviews
    # Use a page that has no archives pointing to it
    output = render_tag(@unrelated_book)
    assert_equal '', output.strip
  end

  def test_renders_correct_structure_and_sorts_reviews
    captured_args = []
    BookCardUtils.stub :render, lambda { |doc, _ctx, subtitle:|
      captured_args << { doc: doc, subtitle: subtitle }
      "<!-- Card for #{doc.data['title']} -->"
    } do
      output = render_tag(@canonical_page)

      assert_correct_html_structure(output)
      assert_correct_rendering_order(captured_args)
    end
  end

  def test_calls_book_card_utils_with_correct_subtitle
    captured_args = []
    BookCardUtils.stub :render, lambda { |doc, _ctx, subtitle:|
      captured_args << { doc: doc, subtitle: subtitle }
      ''
    } do
      render_tag(@canonical_page)

      assert_equal 2, captured_args.length
      assert_correct_subtitle_for_newest_archive(captured_args[0])
      assert_correct_subtitle_for_oldest_archive(captured_args[1])
    end
  end

  def test_logs_error_if_prerequisites_missing
    context_no_page = create_context({}, { site: @site }) # No page
    output = ''
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse('{% display_previous_reviews %}').render!(context_no_page)
    end
    expected_pattern = /<!-- \[ERROR\] PREVIOUS_REVIEWS_FAILURE: Reason='Prerequisites missing: /
    assert_match(expected_pattern, output)
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

  def assert_correct_html_structure(output)
    assert_match(/<aside class="previous-reviews">/, output)
    assert_match %r{<h2 class="book-review-headline">Previous Reviews</h2>}, output
    assert_match(/<div class="card-grid">/, output)
  end

  def assert_correct_rendering_order(captured_args)
    assert_equal 2, captured_args.length
    assert_equal @archive_new, captured_args[0][:doc] # Newest first
    assert_equal @archive_old, captured_args[1][:doc] # Oldest second
  end

  def assert_correct_subtitle_for_newest_archive(captured_arg)
    assert_equal @archive_new, captured_arg[:doc]
    assert_equal 'Review from January 01, 2023', captured_arg[:subtitle]
  end

  def assert_correct_subtitle_for_oldest_archive(captured_arg)
    assert_equal @archive_old, captured_arg[:doc]
    assert_equal 'Review from January 01, 2022', captured_arg[:subtitle]
  end
end
