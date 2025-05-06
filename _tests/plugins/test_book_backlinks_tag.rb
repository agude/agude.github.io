# _tests/plugins/test_book_backlinks_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/book_backlinks_tag' # Load the tag class
# Utils are loaded via test_helper

class TestBookBacklinksTag < Minitest::Test

  def setup
    # Basic setup - specific books/pages might not be needed if we stub well
    @target_page = create_doc({ 'title' => 'My Target Page', 'url' => '/target.html' })
    @site = create_site({}, { 'books' => [] }) # Need 'books' key, but content irrelevant due to stubbing
    @context = create_context({}, { site: @site, page: @target_page })
  end

  # Helper to render the tag
  def render_tag(context = @context)
    # No arguments for this tag
    Liquid::Template.parse("{% book_backlinks %}").render!(context)
  end

  # --- Test Cases ---

  def test_renders_correct_structure_with_backlinks
    # Utility now returns [title, url] pairs
    mock_pairs = [
      ["Book Alpha", "/a"],
      ["Book Gamma", "/g"],
      ["Book Beta", "/b"]
    ]
    # Mock HTML output for each link based on title
    mock_link_html = {
      "Book Alpha" => "<a href='/a'>Alpha Link</a>",
      "Book Beta" => "<a href='/b'>Beta Link</a>",
      "Book Gamma" => "<a href='/g'>Gamma Link</a>"
    }
    # Capture calls to render_book_link_from_data
    rendered_links_args = []

    # Define the replacement method
    replacement_render_method = ->(title, url, _ctx) {
      rendered_links_args << { title: title, url: url }
      mock_link_html[title] || "<cite>#{title}</cite>" # Return mock HTML
    }
    # Store the original method
    original_render_method = BookLinkUtils.method(:render_book_link_from_data)
    # Replace the method on the module's singleton class
    BookLinkUtils.define_singleton_method(:render_book_link_from_data, replacement_render_method)

    output = nil
    begin
      # Stub the backlink finder utility (using Module.stub is fine here)
      BacklinkUtils.stub :find_book_backlinks, mock_pairs do
        output = render_tag # Render the tag while methods are replaced/stubbed
      end
    ensure
      # --- Restore the original method ALWAYS ---
      BookLinkUtils.define_singleton_method(:render_book_link_from_data, original_render_method)
    end

    # --- Assertions ---
    refute_nil output, "Output should not be nil"

    # Check outer structure
    assert_match(/^<aside class="book-backlinks">/, output)
    assert_match(/<h2 class="book-backlink-section"> Reviews that mention <span class="book-title">My Target Page<\/span><\/h2>/, output)
    assert_match(/<ul class="book-backlink-list">/, output)
    assert_match(/<\/ul>\s*<\/aside>$/, output)

    # Check list items using the mock HTML
    assert_match(/<li class="book-backlink-item">#{Regexp.escape(mock_link_html["Book Alpha"])}<\/li>/, output)
    assert_match(/<li class="book-backlink-item">#{Regexp.escape(mock_link_html["Book Beta"])}<\/li>/, output)
    assert_match(/<li class="book-backlink-item">#{Regexp.escape(mock_link_html["Book Gamma"])}<\/li>/, output)

    # Verify render_book_link_from_data was called correctly via captured args
    assert_equal mock_pairs.length, rendered_links_args.length
    assert_equal mock_pairs.map(&:first).sort, rendered_links_args.map { |a| a[:title] }.sort
    # Check that urls from pairs were passed correctly
    assert_equal mock_pairs.map(&:last).sort, rendered_links_args.map { |a| a[:url] }.sort
  end

  # Other tests remain the same, but ensure they stub the correct method if needed
  # (e.g., test_passes_correct_arguments_to_render_book_link_from_data needs no change
  # as it already captures args correctly, just ensure the stub target is right)

  def test_renders_empty_string_when_no_backlinks_found
    mock_pairs = [] # Utility returns empty list

    # Stub the backlink finder utility
    BacklinkUtils.stub :find_book_backlinks, mock_pairs do
      # Stub render_book_link_from_data (using Module.stub is fine here as it's not nested)
      BookLinkUtils.stub :render_book_link_from_data, ->(t, u, c) { flunk "render_book_link_from_data should not be called" } do
        output = render_tag
        assert_equal "", output
      end
    end
  end

  def test_passes_correct_arguments_to_backlink_util
    captured_args = nil

    # Stub find_book_backlinks to capture arguments and return empty list
    stub_logic = ->(page_arg, site_arg, context_arg) {
      captured_args = { page: page_arg, site: site_arg, context: context_arg }
      [] # Return empty list is fine for this test
    }

    BacklinkUtils.stub :find_book_backlinks, stub_logic do
      BookLinkUtils.stub :render_book_link_from_data, "" do
        render_tag
      end
    end

    # Assertions after the stub block
    refute_nil captured_args, "find_book_backlinks should have been called"
    assert_equal @target_page, captured_args[:page]
    assert_equal @site, captured_args[:site]
    assert_equal @context, captured_args[:context]
  end

  def test_passes_correct_arguments_to_render_book_link_from_data
    mock_pairs = [["Title One", "/url/one"], ["Title Two", "/url/two"]]
    captured_render_args = []

    BacklinkUtils.stub :find_book_backlinks, mock_pairs do
      # Stub render_book_link_from_data to capture arguments
      stub_render_logic = ->(title_arg, url_arg, context_arg) {
        captured_render_args << { title: title_arg, url: url_arg, context: context_arg }
        "<cite>#{title_arg}</cite>" # Return simple mock HTML
      }
      # Using Module.stub here is okay as it's not nested inside another stub in this test
      BookLinkUtils.stub :render_book_link_from_data, stub_render_logic do
        render_tag
      end
    end

    # Assertions after the stub block
    assert_equal 2, captured_render_args.length, "render_book_link_from_data should have been called twice"
    # Check args for first call (matches first pair from mock_pairs)
    assert_equal mock_pairs[0][0], captured_render_args[0][:title]
    assert_equal mock_pairs[0][1], captured_render_args[0][:url]
    assert_equal @context, captured_render_args[0][:context]
    # Check args for second call
    assert_equal mock_pairs[1][0], captured_render_args[1][:title]
    assert_equal mock_pairs[1][1], captured_render_args[1][:url]
    assert_equal @context, captured_render_args[1][:context]
  end

  # Initial Context Failure tests remain the same

  def test_returns_empty_and_logs_if_page_missing
    ctx_no_page = create_context({}, { site: @site }) # No :page register
    # Expect log_failure to be called by the *tag* itself
    # Since logging is off by default, it returns "", so tag returns ""
    assert_equal "", render_tag(ctx_no_page)
  end

  def test_returns_empty_and_logs_if_site_missing
    ctx_no_site = create_context({}, { page: @target_page }) # No :site register
    output = nil
    # Capture stdout/stderr to suppress the expected internal log error message
    # from log_failure when it receives an invalid context.
    capture_io do
      output = render_tag(ctx_no_site)
    end
    # Assert the tag still returns an empty string as expected
    assert_equal "", output
    # We don't assert the captured IO because the internal message is a side effect.
    # The main goal is that the tag returns "" when site is missing.
  end

  def test_returns_empty_and_logs_if_books_collection_missing
    site_no_books = create_site({}, {})
    ctx_no_books = create_context({}, { site: site_no_books, page: @target_page })
    assert_equal "", render_tag(ctx_no_books)
  end

  def test_returns_empty_and_logs_if_page_url_missing
    page_no_url = create_doc({ 'title' => 'No URL Page' }, nil)
    ctx_no_url = create_context({}, { site: @site, page: page_no_url })
    assert_equal "", render_tag(ctx_no_url)
  end

  def test_returns_empty_and_logs_if_page_title_missing
    page_no_title = create_doc({ 'title' => nil, 'url' => '/no-title.html' })
    ctx_no_title = create_context({}, { site: @site, page: page_no_title })
    assert_equal "", render_tag(ctx_no_title)
  end

end
