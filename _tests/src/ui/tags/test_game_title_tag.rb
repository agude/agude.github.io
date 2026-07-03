# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/game_title_tag'

# Tests for the game_title Liquid tag.
class TestGameTitleTag < Minitest::Test
  def setup
    @site = create_site
    @html_context = create_context({}, { site: @site })
    @md_context = create_context({}, { site: @site, render_mode: :markdown })
  end

  def test_game_title_html
    output = Liquid::Template.parse('{% game_title "Elden Ring" %}').render!(@html_context)
    assert_equal '<cite class="game-title">Elden Ring</cite>', output
  end

  def test_game_title_markdown
    output = Liquid::Template.parse('{% game_title "Elden Ring" %}').render!(@md_context)
    assert_equal '_Elden Ring_', output
  end
end
