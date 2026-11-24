# frozen_string_literal: true

require_relative '../../../../test_helper'

# Tests the authoring list through its Liquid tag in both render modes.
class TestDisplayUnreviewedMentionsTag < Minitest::Test
  RANKED_LIST = <<~HTML.chomp.freeze
    <ol class="ranked-list">
      <li><cite>Book &amp; Sequel</cite> <span class="mention-count">(2 mentions)</span></li>
      <li><cite>&lt;Unreviewed Book&gt;</cite> <span class="mention-count">(1 mention)</span></li>
    </ol>
  HTML

  def setup
    @site = create_site
    @site.data['mention_tracker'] = {
      'unreviewed book' => { original_titles: { '<Unreviewed Book>' => 1 }, sources: Set['/one.html'] },
      'book sequel' => { original_titles: { 'Book & Sequel' => 2 }, sources: Set['/one.html', '/two.html'] },
    }
    @context = create_context({}, { site: @site })
  end

  def test_renders_ranked_list_with_escaped_titles
    assert_equal RANKED_LIST, render_tag
  end

  def test_markdown_mode_preserves_the_html_list
    @context.registers[:render_mode] = :markdown

    assert_equal RANKED_LIST, render_tag
  end

  def test_tag_includes_error_logs_when_prerequisites_missing
    @site.data.delete('mention_tracker')
    @site.config['plugin_logging']['UNREVIEWED_MENTIONS'] = true

    output = Jekyll.stub(:logger, silent_logger) { render_tag }

    assert_match(
      %r{\A<!-- \[ERROR\] UNREVIEWED_MENTIONS_FAILURE:.*?-->\s*<p>No unreviewed works have been mentioned yet\.</p>\z}m,
      output,
    )
  end

  private

  def render_tag
    Liquid::Template.parse('{% display_unreviewed_mentions %}').render!(@context)
  end
end
