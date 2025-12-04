# frozen_string_literal: true

# _plugins/display_ranked_by_backlinks_tag.rb
require 'jekyll'
require 'liquid'
require_relative '../ranking/finder'
require_relative '../ranking/renderer'

# Displays books ranked by the number of backlinks from other reviews.
#
# Renders an ordered list of books sorted by mention count.
#
# Usage in Liquid templates:
module Jekyll
  #   {% display_ranked_by_backlinks %}
  module Books
    module Tags
      # Liquid tag for displaying books ranked by backlink count.
      # Shows books sorted by the number of mentions from other reviews.
      class DisplayRankedByBacklinksTag < Liquid::Tag
        def render(context)
          finder = Jekyll::Books::Ranking::RankedByBacklinks::Finder.new(context)
          result = finder.find

          renderer = Jekyll::Books::Ranking::RankedByBacklinks::Renderer.new(context, result[:ranked_list])
          html_output = renderer.render

          result[:logs] + html_output
        end
      end
    end
  end
end

Liquid::Template.register_tag('display_ranked_by_backlinks', Jekyll::Books::Tags::DisplayRankedByBacklinksTag)
