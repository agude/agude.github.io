# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/tv_show_title_tag'

# Tests for the tv_show_title Liquid tag.
class TestTvShowTitleTag < Minitest::Test
  def setup
    @site = create_site
    @html_context = create_context({}, { site: @site })
    @md_context = create_context({}, { site: @site, render_mode: :markdown })
  end

  def test_tv_show_title_html
    output = Liquid::Template.parse('{% tv_show_title "Breaking Bad" %}').render!(@html_context)
    assert_equal '<cite class="tv-show-title">Breaking Bad</cite>', output
  end

  def test_tv_show_title_markdown
    output = Liquid::Template.parse('{% tv_show_title "Breaking Bad" %}').render!(@md_context)
    assert_equal '_Breaking Bad_', output
  end
end
