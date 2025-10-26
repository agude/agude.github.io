# _tests/plugins/test_display_ranked_by_backlinks_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_ranked_by_backlinks_tag'

class TestDisplayRankedByBacklinksTag < Minitest::Test
  def setup
    # --- Mock Documents ---
    @book_a = create_doc({ 'title' => 'Book A' }, '/a.html')
    @book_b = create_doc({ 'title' => 'Book B' }, '/b.html')
    @book_c = create_doc({ 'title' => 'Book C' }, '/c.html')

    # --- Site & Context ---
    @site = create_site
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current.md' }, '/current.html') })

    # --- Pre-populate the link_cache for tests ---
    # This simulates what the LinkCacheGenerator would do.
    @site.data['link_cache']['books'] = {
      'book a' => [{ 'url' => '/a.html', 'title' => 'Book A', 'authors' => [] }],
      'book b' => [{ 'url' => '/b.html', 'title' => 'Book B', 'authors' => [] }],
      'book c' => [{ 'url' => '/c.html', 'title' => 'Book C', 'authors' => [] }]
    }
  end

  # Helper to render the tag
  def render_tag(context = @context)
    Liquid::Template.parse("{% display_ranked_by_backlinks %}").render!(context)
  end

  def test_renders_ranked_list_correctly_sorted
    # --- Setup backlink data for this specific test ---
    # Book B is mentioned most, then A, then C.
    @site.data['link_cache']['backlinks'] = {
      '/a.html' => [
        { source: create_doc, type: 'book' },
        { source: create_doc, type: 'series' }
      ], # 2 mentions
      '/b.html' => [
        { source: create_doc, type: 'book' },
        { source: create_doc, type: 'book' },
        { source: create_doc, type: 'direct' }
      ], # 3 mentions
      '/c.html' => [
        { source: create_doc, type: 'book' }
      ]  # 1 mention
    }

    # Stub the link utility to return predictable HTML
    BookLinkUtils.stub :render_book_link_from_data, ->(title, url, ctx) { "<a href=\"#{url}\">#{title}</a>" } do
      output = render_tag

      assert_match %r{<ol class="ranked-list">}, output

      # Check for list items and their content
      assert_match %r{<li><a href="/b.html">Book B</a> <span class="mention-count">\(3 mentions\)</span></li>}, output
      assert_match %r{<li><a href="/a.html">Book A</a> <span class="mention-count">\(2 mentions\)</span></li>}, output
      assert_match %r{<li><a href="/c.html">Book C</a> <span class="mention-count">\(1 mention\)</span></li>}, output

      # Verify the order
      idx_b = output.index("Book B")
      idx_a = output.index("Book A")
      idx_c = output.index("Book C")

      assert idx_b < idx_a, "Book B (3 mentions) should appear before Book A (2 mentions)"
      assert idx_a < idx_c, "Book A (2 mentions) should appear before Book C (1 mention)"
    end
  end

  def test_renders_message_when_no_backlinks_exist
    # Backlinks cache is empty for this test
    @site.data['link_cache']['backlinks'] = {}

    output = render_tag
    assert_equal "<p>No books have been mentioned yet.</p>", output
  end

  def test_logs_error_if_cache_is_missing
    # Simulate a missing cache by using a fresh site object
    fresh_site = create_site
    fresh_site.data.delete('link_cache') # Remove the cache
    fresh_context = create_context({}, { site: fresh_site, page: @context.registers[:page] })
    fresh_site.config['plugin_logging']['RANKED_BY_BACKLINKS'] = true

    output = ""
    capture_io do
      output = render_tag(fresh_context)
    end

    assert_match %r{<!-- \[ERROR\] RANKED_BY_BACKLINKS_FAILURE: Reason='Prerequisites missing: link_cache, backlinks, or books cache\.' .*? -->}, output
  end

  def test_logs_error_if_backlinks_key_is_missing
    @site.data['link_cache'].delete('backlinks')
    @site.config['plugin_logging']['RANKED_BY_BACKLINKS'] = true

    output = ""
    capture_io do
      output = render_tag
    end
    assert_match %r{<!-- \[ERROR\] RANKED_BY_BACKLINKS_FAILURE: Reason='Prerequisites missing: link_cache, backlinks, or books cache\.' .*? -->}, output
  end
end
