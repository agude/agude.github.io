# frozen_string_literal: true

require_relative 'cite_title_tag'

module Jekyll
  module UI
    module Tags
      # Formats a game title as <cite class="game-title"> or _italic_.
      #
      # Usage:
      #   {% game_title "Elden Ring" %}
      class GameTitleTag < CiteTitleTag
        def self.css_class
          'game-title'
        end
      end
    end
  end
end

Liquid::Template.register_tag('game_title', Jekyll::UI::Tags::GameTitleTag)
