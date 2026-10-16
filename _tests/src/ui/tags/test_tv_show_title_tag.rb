# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/tv_show_title_tag'

# Tests for the tv_show_title Liquid tag. Parsing and render modes are
# tested on the CiteTitleTag base class in test_cite_title_tag.rb. This
# file checks only the registered name and the CSS class.
class TestTvShowTitleTag < Minitest::Test
  def test_registered_tag_renders_tv_show_title_class
    context = create_context({}, { site: create_site })
    output = Liquid::Template.parse('{% tv_show_title "Breaking Bad" %}').render!(context)
    assert_equal '<cite class="tv-show-title">Breaking Bad</cite>', output
  end
end
