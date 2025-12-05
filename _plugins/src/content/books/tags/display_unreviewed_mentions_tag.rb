# frozen_string_literal: true

# _plugins/display_unreviewed_mentions_tag.rb
require 'jekyll'
require 'liquid'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../ranking/unreviewed_mentions/finder'
require_relative '../ranking/unreviewed_mentions/renderer'

# Displays a ranked list of unreviewed books mentioned in the site.
#
# Shows books that have been referenced but don't have review pages yet,
# ranked by mention count.
#
# Usage in Liquid templates:
module Jekyll
  #   {% display_unreviewed_mentions %}
  module Books
    module Tags
      # Liquid tag for displaying unreviewed books mentioned on the site.
      # Shows books referenced without review pages, ranked by mention count.
      class DisplayUnreviewedMentionsTag < Liquid::Tag
        def render(context)
          finder = Jekyll::Books::Ranking::UnreviewedMentions::Finder.new(context)
          result = finder.find

          renderer = Jekyll::Books::Ranking::UnreviewedMentions::Renderer.new(result[:mentions])
          html_output = renderer.render

          result[:logs] + html_output
        end
      end
    end
  end
end

Liquid::Template.register_tag('display_unreviewed_mentions', Jekyll::Books::Tags::DisplayUnreviewedMentionsTag)
