# frozen_string_literal: true

# _tests/plugins/test_book_backlinks_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/src/content/books/tags/book_backlinks_tag' # Load the tag class
# Utils are loaded via test_helper

# Tests for BookBacklinksTag Liquid tag and its components.
#
# This test suite is organized into three sections:
# 1. Finder tests - Test data retrieval logic directly
# 2. Renderer tests - Test HTML generation directly
# 3. Tag integration tests - Test the tag orchestration
class TestBookBacklinksTag < Minitest::Test
  def setup
    # --- Mock Documents ---
    @source_doc_alpha = create_doc({ 'title' => 'Book Alpha' }, '/a.html')
    @source_doc_beta = create_doc({ 'title' => 'Book Beta' }, '/b.html')
    @source_doc_gamma = create_doc({ 'title' => 'Book Gamma' }, '/g.html')

    # --- Target Page ---
    # The target page must be part of the 'books' collection for the cache generator
    # to process it and add it to the canonical URL maps.
    @target_page = create_doc({ 'title' => 'My Target Page', 'url' => '/target.html', 'path' => 'target.md' })

    # --- Site ---
    # The site is created here, which runs the generator. Context is created in each test.
    all_books_for_setup = [@source_doc_alpha, @source_doc_beta, @source_doc_gamma, @target_page]
    @site = create_site({}, { 'books' => all_books_for_setup })
  end

  # Helper to render the tag
  def render_tag(context)
    Liquid::Template.parse('{% book_backlinks %}').render!(context)
  end

  # Helper to build expected list item with dagger
  def build_expected_li_with_dagger(link_html)
    dagger_html = '<sup class="series-mention-indicator" role="img" ' \
                  'aria-label="Mentioned via series link" ' \
                  'title="Mentioned via series link">†</sup>'
    '<li class="book-backlink-item" data-link-type="series">' \
      "#{Regexp.escape(link_html)}#{Regexp.escape(dagger_html)}</li>"
  end

  # Helper to build expected list item without dagger
  def build_expected_li(link_type, link_html)
    "<li class=\"book-backlink-item\" data-link-type=\"#{link_type}\">" \
      "#{Regexp.escape(link_html)}</li>"
  end

  # ========================================================================
  # Finder Tests - Test data retrieval logic directly
  # ========================================================================

  def test_finder_returns_correct_structure
    @site.data['link_cache']['backlinks'][@target_page.url] = [
      { source: @source_doc_alpha, type: 'book' }
    ]
    context = create_context({}, { site: @site, page: @target_page })
    finder = Jekyll::BookBacklinks::Finder.new(context)
    result = finder.find

    assert_kind_of Hash, result
    assert_kind_of String, result[:logs]
    assert_kind_of Array, result[:backlinks]
  end

  def test_finder_returns_sorted_backlinks_by_title
    @site.data['link_cache']['backlinks'][@target_page.url] = [
      { source: @source_doc_gamma, type: 'book' },
      { source: @source_doc_alpha, type: 'book' },
      { source: @source_doc_beta, type: 'direct' }
    ]
    context = create_context({}, { site: @site, page: @target_page })
    finder = Jekyll::BookBacklinks::Finder.new(context)
    result = finder.find

    assert_equal 3, result[:backlinks].length
    # Should be sorted alphabetically by title
    assert_equal 'Book Alpha', result[:backlinks][0][0]
    assert_equal 'Book Beta', result[:backlinks][1][0]
    assert_equal 'Book Gamma', result[:backlinks][2][0]
  end

  def test_finder_includes_link_types_in_results
    @site.data['link_cache']['backlinks'][@target_page.url] = [
      { source: @source_doc_alpha, type: 'series' },
      { source: @source_doc_beta, type: 'direct' }
    ]
    context = create_context({}, { site: @site, page: @target_page })
    finder = Jekyll::BookBacklinks::Finder.new(context)
    result = finder.find

    assert_equal 2, result[:backlinks].length
    # Check structure: [title, url, type]
    assert_equal ['Book Alpha', '/a.html', 'series'], result[:backlinks][0]
    assert_equal ['Book Beta', '/b.html', 'direct'], result[:backlinks][1]
  end

  def test_finder_deduplicates_backlinks_from_same_canonical_book
    target_book = create_doc({ 'title' => 'Target' }, '/target.html')
    source_canonical = create_doc({ 'title' => 'Source Book' }, '/source.html')
    archived_data = { 'title' => 'Source Book', 'canonical_url' => '/source.html' }
    source_archived = create_doc(archived_data, '/source-archived.html')

    site = create_site({}, { 'books' => [target_book, source_canonical, source_archived] })
    link_cache = site.data['link_cache']
    link_cache['backlinks'] = {
      '/target.html' => [
        { source: source_canonical, type: 'book' },
        { source: source_archived, type: 'book' }
      ]
    }

    context = create_context({}, { site: site, page: target_book })
    finder = Jekyll::BookBacklinks::Finder.new(context)
    result = finder.find

    assert_equal 1, result[:backlinks].length
    assert_equal 'Source Book', result[:backlinks][0][0]
  end

  def test_finder_includes_series_mentions_for_series_books
    series_data_1 = { 'title' => 'Series Book 1', 'series' => 'My Series' }
    series_data_2 = { 'title' => 'Series Book 2', 'series' => 'My Series' }
    series_book_1 = create_doc(series_data_1, '/series-1.html')
    series_book_2 = create_doc(series_data_2, '/series-2.html')
    source_for_series = create_doc({ 'title' => 'Source for Series' }, '/source-series.html')

    all_series_books = [series_book_1, series_book_2, source_for_series]
    site = create_site({}, { 'books' => all_series_books })
    link_cache = site.data['link_cache']
    link_cache['backlinks'] = {
      '/series-1.html' => [{ source: source_for_series, type: 'series' }]
    }

    # Test on Series Book 2, which only gets the series mention indirectly
    context = create_context({}, { site: site, page: series_book_2 })
    finder = Jekyll::BookBacklinks::Finder.new(context)
    result = finder.find

    assert_equal 1, result[:backlinks].length
    assert_equal 'Source for Series', result[:backlinks][0][0]
    assert_equal 'series', result[:backlinks][0][2]
  end

  def test_finder_returns_empty_when_no_backlinks_found
    context = create_context({}, { site: @site, page: @target_page })
    finder = Jekyll::BookBacklinks::Finder.new(context)
    result = finder.find

    assert_empty result[:backlinks]
    assert_equal '', result[:logs]
  end

  def test_finder_logs_error_when_prerequisites_missing
    config = { 'plugin_logging' => { 'BOOK_BACKLINKS_TAG' => true } }
    site = create_site(config, {})
    page = create_doc({ 'title' => 'Test' }, '/test.html')
    context = create_context({}, { site: site, page: page })

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil) do |prefix, msg|
      prefix == 'PluginLiquid:' &&
        msg.include?('BOOK_BACKLINKS_TAG_FAILURE') &&
        msg.include?('site.collections') &&
        msg.include?('books')
    end

    Jekyll.stub :logger, mock_logger do
      finder = Jekyll::BookBacklinks::Finder.new(context)
      result = finder.find

      assert_empty result[:backlinks]
      assert_match(/BOOK_BACKLINKS_TAG_FAILURE/, result[:logs])
      assert_match(/site\.collections/, result[:logs])
    end

    mock_logger.verify
  end

  # ========================================================================
  # Renderer Tests - Test HTML generation directly
  # ========================================================================

  def test_renderer_returns_empty_string_for_empty_backlinks
    renderer = Jekyll::BookBacklinks::Renderer.new(@site.config, @target_page, [])
    output = renderer.render

    assert_equal '', output
  end

  def test_renderer_generates_correct_html_structure
    backlinks = [
      ['Book Alpha', '/a.html', 'book'],
      ['Book Beta', '/b.html', 'direct']
    ]

    context = create_context({}, { site: @site, page: @target_page })
    renderer = Jekyll::BookBacklinks::Renderer.new(context, @target_page, backlinks)
    output = nil

    BookLinkUtils.stub :render_book_link_from_data, ->(title, _url, _ctx) { "<a>#{title}</a>" } do
      output = renderer.render
    end

    assert_match(/^<aside class="book-backlinks">/, output)
    assert_match(/<h2 class="book-backlink-section">/, output)
    assert_match(/<ul class="book-backlink-list">/, output)
    assert_match(%r{</aside>$}, output)
  end

  def test_renderer_includes_dagger_for_series_links
    backlinks = [
      ['Book Alpha', '/a.html', 'series'],
      ['Book Beta', '/b.html', 'book']
    ]

    context = create_context({}, { site: @site, page: @target_page })
    renderer = Jekyll::BookBacklinks::Renderer.new(context, @target_page, backlinks)
    output = nil

    BookLinkUtils.stub :render_book_link_from_data, ->(title, _url, _ctx) { "<a>#{title}</a>" } do
      output = renderer.render
    end

    # Should have dagger for series link
    assert_match(/series-mention-indicator/, output)
    assert_match(/†/, output)
  end

  def test_renderer_includes_explanation_when_series_links_present
    backlinks = [['Book Alpha', '/a.html', 'series']]

    context = create_context({}, { site: @site, page: @target_page })
    renderer = Jekyll::BookBacklinks::Renderer.new(context, @target_page, backlinks)
    output = nil

    BookLinkUtils.stub :render_book_link_from_data, ->(title, _url, _ctx) { "<a>#{title}</a>" } do
      output = renderer.render
    end

    expected_explanation = '<p class="backlink-explanation"><sup>†</sup> ' \
                           '<em>Mentioned via a link to the series.</em></p>'
    assert_match(/#{Regexp.escape(expected_explanation)}/, output)
  end

  def test_renderer_omits_explanation_when_no_series_links
    backlinks = [
      ['Book Alpha', '/a.html', 'book'],
      ['Book Beta', '/b.html', 'direct']
    ]

    context = create_context({}, { site: @site, page: @target_page })
    renderer = Jekyll::BookBacklinks::Renderer.new(context, @target_page, backlinks)
    output = nil

    BookLinkUtils.stub :render_book_link_from_data, ->(title, _url, _ctx) { "<a>#{title}</a>" } do
      output = renderer.render
    end

    refute_match(/<p class="backlink-explanation">/, output)
    refute_match(/†/, output)
  end

  # ========================================================================
  # Tag Integration Tests - Test orchestration
  # ========================================================================

  def test_tag_orchestrates_finder_and_renderer_correctly
    # Inject test data directly into the cache. Includes a 'series' type link.
    @site.data['link_cache']['backlinks'][@target_page.url] = [
      { source: @source_doc_gamma, type: 'book' },
      { source: @source_doc_alpha, type: 'series' },
      { source: @source_doc_beta, type: 'direct' }
    ]
    context = create_context({}, { site: @site, page: @target_page })

    mock_link_html = {
      'Book Alpha' => "<a href='/a'>Alpha Link</a>",
      'Book Beta' => "<a href='/b'>Beta Link</a>",
      'Book Gamma' => "<a href='/g'>Gamma Link</a>"
    }

    output = ''
    stub_logic = ->(title, _url, _ctx) { mock_link_html[title] }
    BookLinkUtils.stub :render_book_link_from_data, stub_logic do
      output = render_tag(context)
    end

    # --- Assertions ---
    refute_empty output, 'Output should not be empty'

    # Check outer structure
    assert_match(/^<aside class="book-backlinks">/, output)
    assert_match(/<h2 class="book-backlink-section">/, output)
    assert_match(/<ul class="book-backlink-list">/, output)

    # Book Alpha (series link) - should have sup dagger with title attribute
    expected_alpha_li = build_expected_li_with_dagger(mock_link_html['Book Alpha'])
    assert_match(/#{expected_alpha_li}/, output)

    # Book Beta (direct link) - should NOT have dagger
    expected_beta_li = build_expected_li('direct', mock_link_html['Book Beta'])
    assert_match(/#{expected_beta_li}/, output)

    # Book Gamma (book link) - should NOT have dagger
    expected_gamma_li = build_expected_li('book', mock_link_html['Book Gamma'])
    assert_match(/#{expected_gamma_li}/, output)

    # Assert that the explanatory paragraph IS present
    expected_explanation = '<p class="backlink-explanation"><sup>†</sup> ' \
                           '<em>Mentioned via a link to the series.</em></p>'
    assert_match(/#{Regexp.escape(expected_explanation)}/, output)
    assert_match(%r{</ul>.*?<p class="backlink-explanation">.*?</aside>$}m, output,
                 'Explanation should be after the list and before the aside closes')
  end

  def test_tag_returns_empty_when_no_backlinks_found
    context = create_context({}, { site: @site, page: @target_page })
    output = ''
    BookLinkUtils.stub :render_book_link_from_data, lambda { |_t, _u, _c|
      flunk 'render_book_link_from_data should not be called'
    } do
      output = render_tag(context)
    end
    assert_equal '', output.strip
  end

  def test_tag_passes_correct_arguments_to_render_book_link_from_data
    @site.data['link_cache']['backlinks'][@target_page.url] = [
      { source: @source_doc_alpha, type: 'book' },
      { source: @source_doc_beta, type: 'series' }
    ]
    context = create_context({}, { site: @site, page: @target_page })

    captured_render_args = []
    stub_render_logic = lambda { |title_arg, url_arg, context_arg|
      captured_render_args << { title: title_arg, url: url_arg, context: context_arg }
      "<cite>#{title_arg}</cite>"
    }

    BookLinkUtils.stub :render_book_link_from_data, stub_render_logic do
      render_tag(context)
    end

    assert_equal 2, captured_render_args.length
    captured_render_args.sort_by! { |args| args[:title] }
    assert_equal @source_doc_alpha.data['title'], captured_render_args[0][:title]
    assert_equal @source_doc_alpha.url, captured_render_args[0][:url]
    assert_equal @source_doc_beta.data['title'], captured_render_args[1][:title]
    assert_equal @source_doc_beta.url, captured_render_args[1][:url]
  end

  # --- Prerequisite Failure Tests ---

  def test_returns_empty_and_logs_if_page_missing
    ctx_no_page = create_context({}, { site: @site })
    assert_equal '', render_tag(ctx_no_page).strip
  end

  def test_returns_empty_and_logs_if_site_missing
    ctx_no_site = create_context({}, { page: @target_page })
    output = nil
    capture_io { output = render_tag(ctx_no_site) }
    assert_equal '', output.strip
  end

  def test_returns_empty_and_logs_if_books_collection_missing
    site_no_books = create_site({}, {})
    ctx_no_books = create_context({}, { site: site_no_books, page: @target_page })
    assert_equal '', render_tag(ctx_no_books).strip
  end

  def test_returns_empty_and_logs_if_page_url_missing
    page_no_url = create_doc({ 'title' => 'No URL Page' }, nil)
    ctx_no_url = create_context({}, { site: @site, page: page_no_url })
    assert_equal '', render_tag(ctx_no_url).strip
  end

  def test_returns_empty_and_logs_if_page_title_missing
    page_no_title = create_doc({ 'title' => nil, 'url' => '/no-title.html' })
    ctx_no_title = create_context({}, { site: @site, page: page_no_title })
    assert_equal '', render_tag(ctx_no_title).strip
  end
end
