# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../../infrastructure/tag_argument_utils'

module Jekyll
  module UI
    module Tags
      # Liquid tag for rendering a subtitle.
      #
      # Usage:
      #   {% subtitle "Staff Machine Learning Engineer" %}
      #   {% subtitle page.subtitle %}
      #
      # HTML mode:  <div class="subtitle">text</div>
      # Markdown:   **text**
      class SubtitleTag < Liquid::Tag
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        private_constant :TagArgs

        def initialize(tag_name, markup, tokens)
          super
          @raw_markup = markup.strip

          return unless @raw_markup.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in 'subtitle': A text argument is required."
        end

        def render(context)
          text = TagArgs.resolve_value(@raw_markup, context)
          return '' if text.nil? || text.to_s.empty?

          if context.registers[:render_mode] == :markdown
            "**#{text}**"
          else
            "<div class=\"subtitle\">#{text}</div>"
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('subtitle', Jekyll::UI::Tags::SubtitleTag)
