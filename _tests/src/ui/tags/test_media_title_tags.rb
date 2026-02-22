# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/movie_title_tag'
require_relative '../../../../_plugins/src/ui/tags/game_title_tag'
require_relative '../../../../_plugins/src/ui/tags/tv_show_title_tag'

# Integration tests verifying each media title tag emits its own CSS class.
class TestMediaTitleTags < Minitest::Test
  def setup
    @site = create_site
    @html_context = create_context({}, { site: @site })
    @md_context = create_context({}, { site: @site, render_mode: :markdown })
  end

  # --- movie_title ---

  def test_movie_title_html
    output = Liquid::Template.parse('{% movie_title "The Matrix" %}').render!(@html_context)
    assert_equal '<cite class="movie-title">The Matrix</cite>', output
  end

  def test_movie_title_markdown
    output = Liquid::Template.parse('{% movie_title "The Matrix" %}').render!(@md_context)
    assert_equal '_The Matrix_', output
  end

  # --- game_title ---

  def test_game_title_html
    output = Liquid::Template.parse('{% game_title "Elden Ring" %}').render!(@html_context)
    assert_equal '<cite class="game-title">Elden Ring</cite>', output
  end

  def test_game_title_markdown
    output = Liquid::Template.parse('{% game_title "Elden Ring" %}').render!(@md_context)
    assert_equal '_Elden Ring_', output
  end

  # --- tv_show_title ---

  def test_tv_show_title_html
    output = Liquid::Template.parse('{% tv_show_title "Breaking Bad" %}').render!(@html_context)
    assert_equal '<cite class="tv-show-title">Breaking Bad</cite>', output
  end

  def test_tv_show_title_markdown
    output = Liquid::Template.parse('{% tv_show_title "Breaking Bad" %}').render!(@md_context)
    assert_equal '_Breaking Bad_', output
  end
end
