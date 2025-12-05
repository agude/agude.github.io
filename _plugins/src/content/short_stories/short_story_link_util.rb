# frozen_string_literal: true

# _plugins/utils/short_story_link_util.rb
require 'jekyll'
require_relative '../../infrastructure/typography_utils'
require_relative 'short_story_resolver'

module Jekyll
  module ShortStories
    # Utility module for generating links to short stories within anthology books.
    module ShortStoryLinkUtils
      # Renders the HTML for a short story link.
      #
      # @param story_title_raw [String] The title of the story.
      # @param context [Liquid::Context] The current Liquid context.
      # @param from_book_title_raw [String, nil] The title of the book to disambiguate.
      # @return [String] The generated HTML link or span.
      def self.render_short_story_link(story_title_raw, context, from_book_title_raw = nil)
        Jekyll::ShortStories::ShortStoryResolver.new(context).resolve(story_title_raw, from_book_title_raw)
      end

      def self._build_story_cite_element(display_text)
        prepared_display_text = Jekyll::Infrastructure::TypographyUtils.prepare_display_title(display_text)
        "<cite class=\"short-story-title\">#{prepared_display_text}</cite>"
      end
    end
  end
end
