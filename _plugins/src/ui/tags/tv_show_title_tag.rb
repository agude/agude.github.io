# frozen_string_literal: true

require_relative 'cite_title_tag'

module Jekyll
  module UI
    module Tags
      # Formats a TV show title as <cite class="tv-show-title"> or _italic_.
      #
      # Usage:
      #   {% tv_show_title "Breaking Bad" %}
      class TvShowTitleTag < CiteTitleTag
        def self.css_class
          'tv-show-title'
        end
      end
    end
  end
end

Liquid::Template.register_tag('tv_show_title', Jekyll::UI::Tags::TvShowTitleTag)
