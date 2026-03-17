# frozen_string_literal: true

# _tests/plugins/test_display_previous_reviews_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/tags/display_previous_reviews_tag'

# Tests for Jekyll::Books::Tags::DisplayPreviousReviewsTag Liquid tag.
#
# Uses real Finder and Renderer with mock site data, stubbing only
# BookCardRenderer.render (the leaf dependency) to avoid deep HTML rendering
# while verifying actual tag integration.
class TestDisplayPreviousReviewsTag < Minitest::Test
  def setup
    @canonical_url = '/books/hyperion/'
  end

  def render_tag(context)
    Liquid::Template.parse('{% display_previous_reviews %}').render!(context)
  end

  def test_syntax_error_with_arguments
    assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_previous_reviews some_arg %}')
    end
  end

  def test_renders_previous_reviews_sorted_by_date_newest_first
    archived_old = create_archived_review('2020-06-15', @canonical_url)
    archived_new = create_archived_review('2023-10-17', @canonical_url)
    current_page = create_doc(
      { 'title' => 'Hyperion' },
      @canonical_url,
      'content',
      nil,
      MockCollection.new(nil, 'books'),
    )

    site = create_site(
      { 'url' => 'http://example.com' },
      { 'books' => [current_page, archived_old, archived_new] },
    )
    context = create_context({}, { site: site, page: current_page })

    output = stub_card_renderer { render_tag(context) }

    assert_includes output, '<aside class="previous-reviews">'
    assert_includes output, '<h2 class="previous-reviews-headline">Previous Reviews</h2>'
    assert_includes output, '</aside>'
    # Newest first: 2023 review should appear before 2020 review
    pos_2023 = output.index('2023')
    pos_2020 = output.index('2020')
    assert pos_2023 && pos_2020, 'Both review years should appear in output'
    assert pos_2023 < pos_2020, 'Newest review should appear first'
  end

  def test_returns_only_logs_when_no_archived_reviews
    current_page = create_doc(
      { 'title' => 'Hyperion' },
      @canonical_url,
      'content',
      nil,
      MockCollection.new(nil, 'books'),
    )
    site = create_site(
      { 'url' => 'http://example.com' },
      { 'books' => [current_page] },
    )
    context = create_context({}, { site: site, page: current_page })

    output = render_tag(context)

    # No archived reviews → Finder returns empty reviews → tag returns logs only
    refute_includes output, '<aside'
    refute_includes output, 'Previous Reviews'
  end

  def test_logs_error_when_page_is_nil
    site = create_site({ 'url' => 'http://example.com' }, { 'books' => [] })
    site.config['plugin_logging']['PREVIOUS_REVIEWS'] = true
    context = create_context({}, { site: site, page: nil })

    output = Jekyll.stub(:logger, silent_logger) { render_tag(context) }

    assert_match(/PREVIOUS_REVIEWS_FAILURE/, output)
    refute_includes output, '<aside'
  end

  private

  def create_archived_review(date_str, canonical_url)
    create_doc(
      {
        'title' => 'Hyperion',
        'date' => Time.parse(date_str),
        'canonical_url' => canonical_url,
        'authors' => ['Dan Simmons'],
      },
      "/books/hyperion/review-#{date_str}.html",
      'content',
      nil,
      MockCollection.new(nil, 'books'),
    )
  end

  def stub_card_renderer(&)
    Jekyll::Books::Core::BookCardRenderer.stub(
      :render,
      lambda { |doc, _context, subtitle: nil|
        "<div class=\"book-card\">#{doc.data['title']} — #{subtitle}</div>"
      },
      &
    )
  end
end
