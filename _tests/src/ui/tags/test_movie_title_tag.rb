# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/movie_title_tag'

# Tests for the movie_title Liquid tag. Parsing and render modes are
# tested on the CiteTitleTag base class in test_cite_title_tag.rb. This
# file checks only the registered name and the CSS class.
class TestMovieTitleTag < Minitest::Test
  def test_registered_tag_renders_movie_title_class
    context = create_context({}, { site: create_site })
    output = Liquid::Template.parse('{% movie_title "The Matrix" %}').render!(context)
    assert_equal '<cite class="movie-title">The Matrix</cite>', output
  end
end
