# _tests/plugins/test_book_backlinks_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/book_backlinks_tag' # Load the tag class
# Utils are loaded via test_helper

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
    Liquid::Template.parse("{% book_backlinks %}").render!(context)
  end

  # --- Test Cases ---

  def test_renders_correct_structure_with_backlinks_and_dagger
    # Inject test data directly into the cache. Includes a 'series' type link.
    @site.data['link_cache']['backlinks'][@target_page.url] = [
      { source: @source_doc_gamma, type: 'book' },
      { source: @source_doc_alpha, type: 'series' },
      { source: @source_doc_beta, type: 'direct' }
    ]
    context = create_context({}, { site: @site, page: @target_page })

    mock_link_html = {
      "Book Alpha" => "<a href='/a'>Alpha Link</a>",
      "Book Beta" => "<a href='/b'>Beta Link</a>",
      "Book Gamma" => "<a href='/g'>Gamma Link</a>"
    }

    output = ""
    BookLinkUtils.stub :render_book_link_from_data, ->(title, url, _ctx) { mock_link_html[title] } do
      output = render_tag(context)
    end

    # --- Assertions ---
    refute_empty output, "Output should not be empty"

    # Check outer structure
    assert_match(/^<aside class="book-backlinks">/, output)
    assert_match(/<h2 class="book-backlink-section">/, output)
    assert_match(/<ul class="book-backlink-list">/, output)

    # Book Alpha (series link) - should have sup dagger with title attribute
    expected_alpha_li = "<li class=\"book-backlink-item\" data-link-type=\"series\">#{Regexp.escape(mock_link_html["Book Alpha"])}<sup class=\"series-mention-indicator\" role=\"img\" aria-label=\"Mentioned via series link\" title=\"Mentioned via series link\">†</sup></li>"
    assert_match(/#{expected_alpha_li}/, output)

    # Book Beta (direct link) - should NOT have dagger
    expected_beta_li = "<li class=\"book-backlink-item\" data-link-type=\"direct\">#{Regexp.escape(mock_link_html["Book Beta"])}</li>"
    assert_match(/#{expected_beta_li}/, output)

    # Book Gamma (book link) - should NOT have dagger
    expected_gamma_li = "<li class=\"book-backlink-item\" data-link-type=\"book\">#{Regexp.escape(mock_link_html["Book Gamma"])}</li>"
    assert_match(/#{expected_gamma_li}/, output)

    # Assert that the explanatory paragraph IS present
    assert_match %r{<p class="backlink-explanation"><sup>†</sup> <em>Mentioned via a link to the series.</em></p>}, output
    assert_match(/<\/ul>.*?<p class="backlink-explanation">.*?<\/aside>$/m, output, "Explanation should be after the list and before the aside closes")
  end

  def test_does_not_render_explanation_when_no_series_links
    # Inject backlink data with NO 'series' type links
    @site.data['link_cache']['backlinks'][@target_page.url] = [
      { source: @source_doc_gamma, type: 'book' },
      { source: @source_doc_beta, type: 'direct' }
    ]
    context = create_context({}, { site: @site, page: @target_page })

    mock_link_html = {
      "Book Beta" => "<a href='/b'>Beta Link</a>",
      "Book Gamma" => "<a href='/g'>Gamma Link</a>"
    }

    output = ""
    BookLinkUtils.stub :render_book_link_from_data, ->(title, url, _ctx) { mock_link_html[title] } do
      output = render_tag(context)
    end

    # Assert that the main structure is there
    assert_match(/^<aside class="book-backlinks">/, output)
    assert_match(/<ul class="book-backlink-list">/, output)

    # Assert that NO daggers are present
    refute_match %r{<sup>†</sup>}, output

    # Assert that the explanatory paragraph IS ABSENT
    refute_match %r{<p class="backlink-explanation">}, output
  end


  def test_renders_empty_string_when_no_backlinks_found
    context = create_context({}, { site: @site, page: @target_page })
    output = ""
    BookLinkUtils.stub :render_book_link_from_data, ->(t, u, c) { flunk "render_book_link_from_data should not be called" } do
      output = render_tag(context)
    end
    assert_equal "", output.strip
  end

  def test_passes_correct_arguments_to_render_book_link_from_data
    @site.data['link_cache']['backlinks'][@target_page.url] = [
      { source: @source_doc_alpha, type: 'book' },
      { source: @source_doc_beta, type: 'series' }
    ]
    context = create_context({}, { site: @site, page: @target_page })

    captured_render_args = []
    stub_render_logic = ->(title_arg, url_arg, context_arg) {
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

  def test_aggregates_backlinks_and_excludes_self_references
    canonical_book = create_doc({ 'title' => 'Canonical' }, '/canonical.html')
    archived_book = create_doc({ 'title' => 'Archived' }, '/archived.html')
    source_book = create_doc({ 'title' => 'Source' }, '/source.html')

    site = @site # Use site from setup to get the cache structure
    link_cache = site.data['link_cache']

    # Manually populate all necessary caches to isolate this test from the generator.
    link_cache['url_to_canonical_map'] = {
      '/canonical.html' => '/canonical.html',
      '/archived.html' => '/canonical.html',
      '/source.html' => '/source.html'
    }
    link_cache['book_families'] = {
      '/canonical.html' => ['/canonical.html', '/archived.html'],
      '/source.html' => ['/source.html']
    }
    link_cache['backlinks'] = {
      '/canonical.html' => [{ source: source_book, type: 'book' }],
      '/archived.html' => [{ source: canonical_book, type: 'book' }] # A self-reference
    }

    # Stub the link rendering to isolate the tag's logic.
    stub_render_logic = ->(title, _url, _ctx) { "<a>#{title}</a>" }

    # 1. Test rendering on the canonical page
    context_canonical = create_context({}, { site: site, page: canonical_book })
    output_canonical = ""
    BookLinkUtils.stub :render_book_link_from_data, stub_render_logic do
      output_canonical = render_tag(context_canonical)
    end
    assert_match(/<a>Source<\/a>/, output_canonical)
    refute_match(/<a>(Canonical|Archived)<\/a>/, output_canonical)

    # 2. Test rendering on the archived page
    context_archived = create_context({}, { site: site, page: archived_book })
    output_archived = ""
    BookLinkUtils.stub :render_book_link_from_data, stub_render_logic do
      output_archived = render_tag(context_archived)
    end
    assert_match(/<a>Source<\/a>/, output_archived)
    refute_match(/<a>(Canonical|Archived)<\/a>/, output_archived)
  end

  def test_deduplicates_backlinks_from_multiple_versions_of_same_book
    target_book = create_doc({ 'title' => 'Target' }, '/target.html')
    source_canonical = create_doc({ 'title' => 'Source Book' }, '/source.html')
    source_archived = create_doc({ 'title' => 'Source Book', 'canonical_url' => '/source.html' }, '/source-archived.html')

    # Create a fresh site so the generator populates all maps correctly
    site = create_site({}, { 'books' => [target_book, source_canonical, source_archived] })
    link_cache = site.data['link_cache']
    link_cache['backlinks'] = {
      '/target.html' => [
        { source: source_canonical, type: 'book' },
        { source: source_archived, type: 'book' }
      ]
    }

    context = create_context({}, { site: site, page: target_book })
    output = render_tag(context)

    assert_equal 1, output.scan(/Source Book/).count, "Should only list 'Source Book' once"
  end

  def test_includes_backlinks_from_series_mentions_for_all_series_books
    series_book_1 = create_doc({ 'title' => 'Series Book 1', 'series' => 'My Series' }, '/series-1.html')
    series_book_2 = create_doc({ 'title' => 'Series Book 2', 'series' => 'My Series' }, '/series-2.html')
    source_for_series = create_doc({ 'title' => 'Source for Series' }, '/source-series.html')
    source_for_book1 = create_doc({ 'title' => 'Source for Book 1' }, '/source-book1.html')

    # Create a fresh site so the generator populates all maps correctly
    site = create_site({}, { 'books' => [series_book_1, series_book_2, source_for_series, source_for_book1] })
    link_cache = site.data['link_cache']
    link_cache['backlinks'] = {
      '/series-1.html' => [
        { source: source_for_series, type: 'series' },
        { source: source_for_book1, type: 'book' }
      ],
      '/series-2.html' => [
        { source: source_for_series, type: 'series' }
      ]
    }

    # Test on Series Book 2, which only has an indirect series mention
    context_book2 = create_context({}, { site: site, page: series_book_2 })
    output_book2 = render_tag(context_book2)

    assert_match(/Source for Series/, output_book2, "Book 2 should find backlink from series mention")
    refute_match(/Source for Book 1/, output_book2, "Book 2 should not find backlink meant only for Book 1")
    assert_match(/series-mention-indicator/, output_book2, "Should have the dagger for series mentions")

    # Test on Series Book 1, which has both
    context_book1 = create_context({}, { site: site, page: series_book_1 })
    output_book1 = render_tag(context_book1)
    assert_match(/Source for Series/, output_book1, "Book 1 should also find backlink from series mention")
    assert_match(/Source for Book 1/, output_book1, "Book 1 should find its direct backlink")
  end

  # --- Prerequisite Failure Tests (Unchanged) ---

  def test_returns_empty_and_logs_if_page_missing
    ctx_no_page = create_context({}, { site: @site })
    assert_equal "", render_tag(ctx_no_page).strip
  end

  def test_returns_empty_and_logs_if_site_missing
    ctx_no_site = create_context({}, { page: @target_page })
    output = nil
    capture_io { output = render_tag(ctx_no_site) }
    assert_equal "", output.strip
  end

  def test_returns_empty_and_logs_if_books_collection_missing
    site_no_books = create_site({}, {})
    ctx_no_books = create_context({}, { site: site_no_books, page: @target_page })
    assert_equal "", render_tag(ctx_no_books).strip
  end

  def test_returns_empty_and_logs_if_page_url_missing
    page_no_url = create_doc({ 'title' => 'No URL Page' }, nil)
    ctx_no_url = create_context({}, { site: @site, page: page_no_url })
    assert_equal "", render_tag(ctx_no_url).strip
  end

  def test_returns_empty_and_logs_if_page_title_missing
    page_no_title = create_doc({ 'title' => nil, 'url' => '/no-title.html' })
    ctx_no_title = create_context({}, { site: @site, page: page_no_title })
    assert_equal "", render_tag(ctx_no_title).strip
  end

end
