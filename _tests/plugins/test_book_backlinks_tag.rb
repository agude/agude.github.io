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

  def test_renders_correct_structure_with_backlinks
    # Inject test data directly into the cache
    @site.data['link_cache']['backlinks'][@target_page.url] = [
      { source: @source_doc_gamma, type: 'book' },
      { source: @source_doc_alpha, type: 'series' },
      { source: @source_doc_beta, type: 'direct' }
    ]

    # Mock the final link rendering utility to simplify assertions
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
    assert_match(/<h2 class="book-backlink-section"> Reviews that mention <span class="book-title">My Target Page<\/span><\/h2>/, output)
    assert_match(/<ul class="book-backlink-list">/, output)
    assert_match(/<\/ul>\s*<\/aside>$/, output)

    # Check list items using the mock HTML. The tag should sort them alphabetically.
    assert_match(/<li class="book-backlink-item">#{Regexp.escape(mock_link_html["Book Alpha"])}<\/li>/, output)
    assert_match(/<li class="book-backlink-item">#{Regexp.escape(mock_link_html["Book Beta"])}<\/li>/, output)
    assert_match(/<li class="book-backlink-item">#{Regexp.escape(mock_link_html["Book Gamma"])}<\/li>/, output)

    # Verify the order
    alpha_index = output.index("Alpha Link")
    beta_index = output.index("Beta Link")
    gamma_index = output.index("Gamma Link")
    assert alpha_index < beta_index && beta_index < gamma_index, "Backlinks should be sorted alphabetically by title"
  end

  def test_renders_empty_string_when_no_backlinks_found
    # The cache will have no entry for @target_page.url by default
    output = ""
    BookLinkUtils.stub :render_book_link_from_data, ->(t, u, c) { flunk "render_book_link_from_data should not be called" } do
      output = render_tag
    end
    assert_equal "", output.strip
  end

  def test_passes_correct_arguments_to_render_book_link_from_data
    # Inject test data directly into the cache
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

    assert_equal 2, captured_render_args.length, "render_book_link_from_data should have been called twice"

    # Sort captured args by title to make assertions predictable
    captured_render_args.sort_by! { |args| args[:title] }

    # Check args for first call (Book Alpha)
    assert_equal @source_doc_alpha.data['title'], captured_render_args[0][:title]
    assert_equal @source_doc_alpha.url, captured_render_args[0][:url]
    assert_equal @context, captured_render_args[0][:context]

    # Check args for second call (Book Beta)
    assert_equal @source_doc_beta.data['title'], captured_render_args[1][:title]
    assert_equal @source_doc_beta.url, captured_render_args[1][:url]
    assert_equal @context, captured_render_args[1][:context]
  end

  # --- Prerequisite Failure Tests (Unchanged) ---

  def test_returns_empty_and_logs_if_page_missing
    ctx_no_page = create_context({}, { site: @site }) # No :page register
    assert_equal "", render_tag(ctx_no_page).strip
  end

  def test_returns_empty_and_logs_if_site_missing
    ctx_no_site = create_context({}, { page: @target_page }) # No :site register
    output = nil
    capture_io do
      output = render_tag(ctx_no_site)
    end
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
