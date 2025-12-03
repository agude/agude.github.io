# frozen_string_literal: true

# _plugins/display_unreviewed_mentions_tag.rb
require 'jekyll'
require 'liquid'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../ranking/unreviewed_mentions/finder'
require_relative '../ranking/unreviewed_mentions/renderer'

module Jekyll
  # Displays a ranked list of unreviewed books mentioned in the site.
  #
  # Shows books that have been referenced but don't have review pages yet,
  # ranked by mention count.
  #
  # Usage in Liquid templates:
  #   {% display_unreviewed_mentions %}
  class DisplayUnreviewedMentionsTag < Liquid::Tag
    def render(context)
      finder = Jekyll::DisplayUnreviewedMentions::Finder.new(context)
      result = finder.find

      renderer = Jekyll::DisplayUnreviewedMentions::Renderer.new(result[:mentions])
      html_output = renderer.render

      result[:logs] + html_output
    end
  end
end

Liquid::Template.register_tag('display_unreviewed_mentions', Jekyll::DisplayUnreviewedMentionsTag)
