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
    mock_titles = ["Book Alpha", "Book Gamma", "Book Beta"] # Unsorted list from util
    mock_link_html = {
      "Book Alpha" => "<a href='/a'>Alpha</a>",
      "Book Beta" => "<a href='/b'>Beta</a>",
      "Book Gamma" => "<a href='/g'>Gamma</a>"
    }
    # Capture calls to render_book_link
    rendered_links_order = []

    # Stub the backlink finder utility
    BacklinkUtils.stub :find_book_backlinks, mock_titles do
      # Stub the book link renderer utility
      BookLinkUtils.stub :render_book_link, ->(title, _ctx) {
        rendered_links_order << title # Record the order it was called
        mock_link_html[title] || "<cite>#{title}</cite>" # Return mock HTML
      } do
        output = render_tag
        # Check outer structure
        assert_match(/^<aside class="book-backlinks">/, output)
        assert_match(/<h2 class="book-backlink-section"> Reviews that mention <span class="book-title">My Target Page<\/span><\/h2>/, output)
        assert_match(/<ul class="book-backlink-list">/, output)
        assert_match(/<\/ul>\s*<\/aside>$/, output)

        # Check list items (order matters based on mock_link_html keys)
        assert_match(/<li class="book-backlink-item">#{Regexp.escape(mock_link_html["Book Alpha"])}<\/li>/, output)
        assert_match(/<li class="book-backlink-item">#{Regexp.escape(mock_link_html["Book Beta"])}<\/li>/, output)
        assert_match(/<li class="book-backlink-item">#{Regexp.escape(mock_link_html["Book Gamma"])}<\/li>/, output)
      end
    end

    # Verify render_book_link was called for each title from the utility
    assert_equal mock_titles.sort, rendered_links_order.sort # Compare content ignoring order for this check
    assert_equal mock_titles.length, rendered_links_order.length # Ensure correct number of calls
  end

  def test_renders_empty_string_when_no_backlinks_found
    mock_titles = [] # Utility returns empty list

    # Stub the backlink finder utility
    BacklinkUtils.stub :find_book_backlinks, mock_titles do
      # Stub the book link renderer (shouldn't be called)
      BookLinkUtils.stub :render_book_link, ->(title, _ctx) { flunk "render_book_link should not be called" } do
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
      # Stub render_book_link as it won't be called anyway
      BookLinkUtils.stub :render_book_link, "" do
        render_tag
      end
    end

    # Assertions after the stub block
    refute_nil captured_args, "find_book_backlinks should have been called"
    assert_equal @target_page, captured_args[:page]
    assert_equal @site, captured_args[:site]
    assert_equal @context, captured_args[:context]
  end

  def test_passes_correct_arguments_to_render_book_link
    mock_titles = ["Title One", "Title Two"]
    captured_render_args = []

    BacklinkUtils.stub :find_book_backlinks, mock_titles do
      # Stub render_book_link to capture arguments
      stub_render_logic = ->(title_arg, context_arg) {
        captured_render_args << { title: title_arg, context: context_arg }
        "<cite>#{title_arg}</cite>" # Return simple mock HTML
      }
      BookLinkUtils.stub :render_book_link, stub_render_logic do
        render_tag
      end
    end

    # Assertions after the stub block
    assert_equal 2, captured_render_args.length, "render_book_link should have been called twice"
    # Check args for first call
    assert_equal mock_titles[0], captured_render_args[0][:title]
    assert_equal @context, captured_render_args[0][:context]
    # Check args for second call
    assert_equal mock_titles[1], captured_render_args[1][:title]
    assert_equal @context, captured_render_args[1][:context]
  end

  # --- Test Initial Context Failures (Before Utility is Called) ---

  def test_returns_empty_and_logs_if_page_missing
    ctx_no_page = create_context({}, { site: @site }) # No :page register
    # Expect log_failure to be called by the *tag* itself
    # Since logging is off by default, it returns "", so tag returns ""
    assert_equal "", render_tag(ctx_no_page)
    # TODO: Add assertion for log_failure call if logging tests are enhanced
  end

  def test_returns_empty_and_logs_if_site_missing
    ctx_no_site = create_context({}, { page: @target_page }) # No :site register
    assert_equal "", render_tag(ctx_no_site)
    # TODO: Add assertion for log_failure call
  end

  def test_returns_empty_and_logs_if_books_collection_missing
    site_no_books = create_site({}, {}) # No 'books' collection
    ctx_no_books = create_context({}, { site: site_no_books, page: @target_page })
    assert_equal "", render_tag(ctx_no_books)
    # TODO: Add assertion for log_failure call
  end

  def test_returns_empty_and_logs_if_page_url_missing
    page_no_url = create_doc({ 'title' => 'No URL Page' }, nil) # URL is nil
    ctx_no_url = create_context({}, { site: @site, page: page_no_url })
    assert_equal "", render_tag(ctx_no_url)
    # TODO: Add assertion for log_failure call
  end

  def test_returns_empty_and_logs_if_page_title_missing
    page_no_title = create_doc({ 'title' => nil, 'url' => '/no-title.html' }) # Title is nil
    ctx_no_title = create_context({}, { site: @site, page: page_no_title })
    assert_equal "", render_tag(ctx_no_title)
    # TODO: Add assertion for log_failure call
  end

end
