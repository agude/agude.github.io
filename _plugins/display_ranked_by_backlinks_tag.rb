# frozen_string_literal: true

# _plugins/display_ranked_by_backlinks_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'logic/ranked_by_backlinks/finder'
require_relative 'logic/ranked_by_backlinks/renderer'

module Jekyll
  # Displays books ranked by the number of backlinks from other reviews.
  #
  # Renders an ordered list of books sorted by mention count.
  #
  # Usage in Liquid templates:
  #   {% display_ranked_by_backlinks %}
  class DisplayRankedByBacklinksTag < Liquid::Tag
    def render(context)
      finder = Jekyll::RankedByBacklinks::Finder.new(context)
      result = finder.find

      renderer = Jekyll::RankedByBacklinks::Renderer.new(context, result[:ranked_list])
      html_output = renderer.render

      result[:logs] + html_output
    end
  end
end

Liquid::Template.register_tag('display_ranked_by_backlinks', Jekyll::DisplayRankedByBacklinksTag)
