# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../../infrastructure/tag_argument_utils'

module Jekyll
  module UI
    module Tags
      # Base class for simple title-formatting tags that wrap text in a
      # <cite> element (HTML) or italic underscores (Markdown).
      #
      # Subclasses must define `self.css_class` returning the CSS class name
      # (e.g. "movie-title").
      #
      # Usage (in a subclass registered as "movie_title"):
      #   {% movie_title "The Matrix" %}
      #   {% movie_title page.movie %}
      #
      # HTML mode:     <cite class="movie-title">The Matrix</cite>
      # Markdown mode: _The Matrix_
      class CiteTitleTag < Liquid::Tag
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        private_constant :TagArgs

        def initialize(tag_name, markup, tokens)
          super
          @raw_markup = markup.strip

          return unless @raw_markup.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in '#{tag_name}': A text argument is required."
        end

        def render(context)
          text = TagArgs.resolve_value(@raw_markup, context)
          return '' if text.nil? || text.to_s.empty?

          if context.registers[:render_mode] == :markdown
            "_#{text}_"
          else
            css = self.class.css_class
            "<cite class=\"#{css}\">#{text}</cite>"
          end
        end
      end
    end
  end
end
