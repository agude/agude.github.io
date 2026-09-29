# frozen_string_literal: true

require_relative '../lists/by_award_finder'
require_relative '../lists/favorites_lists_finder'

module Jekyll
  module Books
    module AwardsPage
      # Fetches the data shared by the HTML and Markdown awards pages.
      class Finder
        def initialize(context)
          @context = context
          @site = context.registers[:site]
        end

        def find
          awards = Jekyll::Books::Lists::ByAwardFinder.new(site: @site, context: @context).find
          favorites = Jekyll::Books::Lists::FavoritesListsFinder.new(site: @site, context: @context).find

          {
            awards_groups: awards[:awards_data] || [],
            favorites_lists: favorites[:favorites_lists] || [],
            log_messages: (awards[:log_messages] || '') + (favorites[:log_messages] || ''),
          }
        end
      end
    end
  end
end
