# frozen_string_literal: true

require_relative 'cite_title_tag'

module Jekyll
  module UI
    module Tags
      # Formats a movie title as <cite class="movie-title"> or _italic_.
      #
      # Usage:
      #   {% movie_title "The Matrix" %}
      class MovieTitleTag < CiteTitleTag
        def self.css_class
          'movie-title'
        end
      end
    end
  end
end

Liquid::Template.register_tag('movie_title', Jekyll::UI::Tags::MovieTitleTag)
