# frozen_string_literal: true

require_relative '../../../../test_helper'

# Tests the authoring list through its Liquid tag in both render modes.
class TestDisplayRankedByBacklinksTag < Minitest::Test
  RANKED_LIST = <<~HTML.chomp.freeze
    <ol class="ranked-list">
      <li><a href="/books/dune/"><cite class="book-title">Dune</cite></a> <span class="mention-count">(2 mentions)</span></li>
      <li><a href="/books/hyperion/"><cite class="book-title">Hyperion</cite></a> <span class="mention-count">(1 mention)</span></li>
    </ol>
  HTML

  def setup
    books = [
      create_doc({ 'title' => 'Hyperion' }, '/books/hyperion/'),
      create_doc({ 'title' => 'Dune' }, '/books/dune/'),
    ]
    @site = create_site({ 'url' => 'http://example.com' }, { 'books' => books })
    @site.data['link_cache']['backlinks'] = {
      '/books/hyperion/' => [{ type: 'book' }],
      '/books/dune/' => [{ type: 'book' }, { type: 'series' }],
    }
    page = create_doc({ 'url' => '/test.html' }, '/test.html')
    @context = create_context({}, { site: @site, page: page })
  end

  def test_renders_ranked_list_with_real_data
    assert_equal RANKED_LIST, render_tag
  end

  def test_markdown_mode_preserves_the_html_list
    @context.registers[:render_mode] = :markdown

    assert_equal RANKED_LIST, render_tag
  end

  def test_prepends_error_log_when_prerequisites_missing
    @site.data.delete('link_cache')
    @site.config['plugin_logging']['RANKED_BY_BACKLINKS'] = true

    output = Jekyll.stub(:logger, silent_logger) { render_tag }

    assert_match(%r{\A<!-- \[ERROR\] RANKED_BY_BACKLINKS_FAILURE:.*?-->\s*<p>No books have been mentioned yet\.</p>\z}m, output)
  end

  private

  def render_tag
    Liquid::Template.parse('{% display_ranked_by_backlinks %}').render!(@context)
  end
end
