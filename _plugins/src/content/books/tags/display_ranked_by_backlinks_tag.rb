# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../ranking/finder'
require_relative '../ranking/renderer'

module Jekyll
  module Books
    module Tags
      # Displays reviewed books ranked by their cached backlink count.
      class DisplayRankedByBacklinksTag < Liquid::Tag
        def render(context)
          result = Jekyll::Books::Ranking::Finder.new(context).by_backlinks
          result[:logs] + Jekyll::Books::Ranking::Renderer.render_backlinks(context, result[:ranked_list])
        end
      end
    end
  end
end

Liquid::Template.register_tag('display_ranked_by_backlinks', Jekyll::Books::Tags::DisplayRankedByBacklinksTag)
