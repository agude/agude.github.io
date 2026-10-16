# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/game_title_tag'

# Tests for the game_title Liquid tag. Parsing and render modes are
# tested on the CiteTitleTag base class in test_cite_title_tag.rb. This
# file checks only the registered name and the CSS class.
class TestGameTitleTag < Minitest::Test
  def test_registered_tag_renders_game_title_class
    context = create_context({}, { site: create_site })
    output = Liquid::Template.parse('{% game_title "Elden Ring" %}').render!(context)
    assert_equal '<cite class="game-title">Elden Ring</cite>', output
  end
end
