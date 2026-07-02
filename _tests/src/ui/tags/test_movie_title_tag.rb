# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/movie_title_tag'

# Tests for the movie_title Liquid tag.
class TestMovieTitleTag < Minitest::Test
  def setup
    @site = create_site
    @html_context = create_context({}, { site: @site })
    @md_context = create_context({}, { site: @site, render_mode: :markdown })
  end

  def test_movie_title_html
    output = Liquid::Template.parse('{% movie_title "The Matrix" %}').render!(@html_context)
    assert_equal '<cite class="movie-title">The Matrix</cite>', output
  end

  def test_movie_title_markdown
    output = Liquid::Template.parse('{% movie_title "The Matrix" %}').render!(@md_context)
    assert_equal '_The Matrix_', output
  end
end
