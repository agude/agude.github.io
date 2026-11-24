# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../ranking/finder'
require_relative '../ranking/renderer'

module Jekyll
  module Books
    module Tags
      # Displays unreviewed works ranked by the number of pages mentioning them.
      class DisplayUnreviewedMentionsTag < Liquid::Tag
        def render(context)
          result = Jekyll::Books::Ranking::Finder.new(context).unreviewed_mentions
          result[:logs] + Jekyll::Books::Ranking::Renderer.render_unreviewed_mentions(result[:mentions])
        end
      end
    end
  end
end

Liquid::Template.register_tag('display_unreviewed_mentions', Jekyll::Books::Tags::DisplayUnreviewedMentionsTag)
