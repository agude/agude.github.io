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
    @target_page = create_doc({ 'title' => 'My Target Page', 'url' => '/target.html', 'path' => 'target.md' })

    # --- Site & Context ---
    @site = create_site({}, { 'books' => [@source_doc_alpha, @source_doc_beta, @source_doc_gamma] })
    @context = create_context({}, { site: @site, page: @target_page })
  end

  # Helper to render the tag
  def render_tag(context = @context)
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

    mock_link_html = {
      "Book Alpha" => "<a href='/a'>Alpha Link</a>",
      "Book Beta" => "<a href='/b'>Beta Link</a>",
      "Book Gamma" => "<a href='/g'>Gamma Link</a>"
    }

    output = ""
    BookLinkUtils.stub :render_book_link_from_data, ->(title, url, _ctx) { mock_link_html[title] } do
      output = render_tag
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

    mock_link_html = {
      "Book Beta" => "<a href='/b'>Beta Link</a>",
      "Book Gamma" => "<a href='/g'>Gamma Link</a>"
    }

    output = ""
    BookLinkUtils.stub :render_book_link_from_data, ->(title, url, _ctx) { mock_link_html[title] } do
      output = render_tag
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
    output = ""
    BookLinkUtils.stub :render_book_link_from_data, ->(t, u, c) { flunk "render_book_link_from_data should not be called" } do
      output = render_tag
    end
    assert_equal "", output.strip
  end

  def test_passes_correct_arguments_to_render_book_link_from_data
    @site.data['link_cache']['backlinks'][@target_page.url] = [
      { source: @source_doc_alpha, type: 'book' },
      { source: @source_doc_beta, type: 'series' }
    ]

    captured_render_args = []
    stub_render_logic = ->(title_arg, url_arg, context_arg) {
      captured_render_args << { title: title_arg, url: url_arg, context: context_arg }
      "<cite>#{title_arg}</cite>"
    }

    BookLinkUtils.stub :render_book_link_from_data, stub_render_logic do
      render_tag
    end

    assert_equal 2, captured_render_args.length
    captured_render_args.sort_by! { |args| args[:title] }
    assert_equal @source_doc_alpha.data['title'], captured_render_args[0][:title]
    assert_equal @source_doc_alpha.url, captured_render_args[0][:url]
    assert_equal @source_doc_beta.data['title'], captured_render_args[1][:title]
    assert_equal @source_doc_beta.url, captured_render_args[1][:url]
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
