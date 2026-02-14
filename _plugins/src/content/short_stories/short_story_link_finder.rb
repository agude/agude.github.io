# frozen_string_literal: true

# _plugins/src/content/short_stories/short_story_link_finder.rb
require 'jekyll'
require_relative '../../infrastructure/plugin_logger_utils'
require_relative '../../infrastructure/text_processing_utils'

module Jekyll
  module ShortStories
    # Finds short story data without any formatting.
    #
    # This class separates data fetching from formatting concerns.
    # It returns a data hash that can be passed to LinkFormatter.
    #
    # @example
    #   finder = ShortStoryLinkFinder.new(context)
    #   data = finder.find('The Last Question')
    #   # => { found: true, display_name: 'The Last Question', url: '/books/...#slug', ... }
    #
    #   # Then format with:
    #   LinkFormatter.html(data[:display_name], data[:url], wrapper: :cite, css_class: 'short-story-title')
    class ShortStoryLinkFinder
      Logger = Jekyll::Infrastructure::PluginLoggerUtils
      Text = Jekyll::Infrastructure::TextProcessingUtils
      private_constant :Logger, :Text

      def initialize(context)
        @context = context
        @site = context&.registers&.[](:site)
        @log_output = ''
      end

      # Finds short story data by title.
      #
      # @param title_raw [String] The story title to search for.
      # @param from_book [String, nil] Optional book title to disambiguate.
      # @return [Hash] Story data with keys:
      #   - :found [Boolean] Whether story was found in cache
      #   - :display_name [String] Text to display
      #   - :url [String, nil] URL to story (book URL + anchor)
      #   - :log_output [String] Any log messages generated
      def find(title_raw, from_book: nil)
        return empty_result(title_raw) unless @site

        @title_input = title_raw.to_s.strip
        @book_filter = from_book.to_s.strip if from_book
        @norm_title = Text.normalize_title(@title_input)

        return empty_result_with_log(@title_input, log_empty_title) if @norm_title.empty?

        target = find_target_location
        build_result_from_target(target)
      end

      private

      def empty_result(title_input)
        {
          found: false,
          display_name: title_input.to_s,
          url: nil,
          log_output: ''
        }
      end

      def empty_result_with_log(title_input, log_msg)
        {
          found: false,
          display_name: title_input.to_s,
          url: nil,
          log_output: log_msg
        }
      end

      def build_result_from_target(target)
        if target
          {
            found: true,
            display_name: target['title'],
            url: "#{target['url']}##{target['slug']}",
            log_output: @log_output
          }
        else
          {
            found: false,
            display_name: @title_input,
            url: nil,
            log_output: @log_output
          }
        end
      end

      def find_target_location
        cache = @site.data['link_cache'] || {}
        locations = (cache['short_stories'] || {})[@norm_title]

        return log_not_found if locations.nil? || locations.empty?

        resolve_ambiguity(locations, cache['url_to_canonical_map'] || {})
      end

      def resolve_ambiguity(locations, canonical_map)
        # 1. Use book filter if provided (takes priority)
        book_filter_result = try_book_filter(locations)
        return book_filter_result unless book_filter_result == :skip

        # 2. Prefer canonical locations
        canonical_result = try_canonical_locations(locations, canonical_map)
        return canonical_result if canonical_result

        # 3. Check if all locations point to the same book
        return locations.first if all_same_book?(locations)

        # 4. Ambiguous
        log_ambiguous(locations)
        nil
      end

      def try_canonical_locations(locations, canonical_map)
        canon_locs = locations.select { |loc| canonical_map[loc['url']] == loc['url'] }
        canon_locs.length == 1 ? canon_locs.first : nil
      end

      def all_same_book?(locations)
        locations.map { |l| l['url'] }.uniq.length == 1
      end

      def try_book_filter(locations)
        return :skip unless @book_filter && !@book_filter.empty?

        match = locations.find { |loc| loc['parent_book_title'].casecmp(@book_filter).zero? }
        return log_not_found_in_book unless match

        match
      end

      def log_empty_title
        Logger.log_liquid_failure(
          context: @context, tag_type: 'RENDER_SHORT_STORY_LINK',
          reason: 'Input story title resolved to an empty string.',
          identifiers: { TitleInput: @title_input || 'nil' }, level: :warn
        )
      end

      def log_not_found
        @log_output = Logger.log_liquid_failure(
          context: @context, tag_type: 'RENDER_SHORT_STORY_LINK',
          reason: 'Could not find short story in cache.',
          identifiers: { StoryTitle: @title_input }, level: :info
        )
        nil
      end

      def log_not_found_in_book
        @log_output = Logger.log_liquid_failure(
          context: @context, tag_type: 'RENDER_SHORT_STORY_LINK',
          reason: 'Story found in cache but not in the specified book.',
          identifiers: { StoryTitle: @title_input, FromBook: @book_filter }, level: :warn
        )
        nil
      end

      def log_ambiguous(locations)
        books = locations.map { |loc| "'#{loc['parent_book_title']}'" }.join(', ')
        @log_output = Logger.log_liquid_failure(
          context: @context, tag_type: 'RENDER_SHORT_STORY_LINK',
          reason: "Ambiguous story title. Use 'from_book' to specify which book.",
          identifiers: { StoryTitle: @title_input, FoundIn: books }, level: :error
        )
      end
    end
  end
end
