# frozen_string_literal: true

# _plugins/src/content/short_stories/short_story_resolver.rb
require 'jekyll'
require_relative '../../infrastructure/links/link_helper_utils'
require_relative '../../infrastructure/plugin_logger_utils'
require_relative '../../infrastructure/text_processing_utils'
require_relative 'short_story_link_util'

module Jekyll
  module ShortStories
    # Helper class to handle resolution logic.
    class ShortStoryResolver
      # Aliases for readability
      LinkHelper = Jekyll::Infrastructure::Links::LinkHelperUtils
      Logger = Jekyll::Infrastructure::PluginLoggerUtils
      Text = Jekyll::Infrastructure::TextProcessingUtils
      private_constant :LinkHelper, :Logger, :Text

      def initialize(context)
        @context = context
        @site = context&.registers&.[](:site)
        @log_output = ''
        @ambiguous = false
      end

      def resolve(title_raw, book_title_raw)
        data = resolve_data(title_raw, book_title_raw)
        render_html_from_data(data)
      end

      def resolve_data(title_raw, book_title_raw)
        return { status: :no_site, url: nil, display_text: title_raw.to_s }.freeze unless @site

        @title_input = title_raw.to_s.strip
        @book_filter = book_title_raw.to_s.strip if book_title_raw
        @norm_title = Text.normalize_title(@title_input)

        if @norm_title.empty?
          @log_output = log_empty_title(title_raw)
          return { status: :empty_title, url: nil, display_text: nil }.freeze
        end

        target = find_target_location
        build_data_hash(target)
      end

      private

      def build_data_hash(target)
        if target
          url = "#{target['url']}##{target['slug']}"
          { status: :found, url: url, display_text: target['title'] }.freeze
        elsif @ambiguous
          { status: :ambiguous, url: nil, display_text: @title_input }.freeze
        else
          { status: :not_found, url: nil, display_text: @title_input }.freeze
        end
      end

      def render_html_from_data(data)
        case data[:status]
        when :no_site
          fallback(data[:display_text])
        when :empty_title
          @log_output
        when :found
          cite = Jekyll::ShortStories::ShortStoryLinkUtils._build_story_cite_element(data[:display_text])
          html = LinkHelper._generate_link_html(@context, data[:url], cite)
          @log_output + html
        when :not_found, :ambiguous
          cite = Jekyll::ShortStories::ShortStoryLinkUtils._build_story_cite_element(data[:display_text])
          @log_output + cite
        end
      end

      def fallback(title)
        Jekyll::ShortStories::ShortStoryLinkUtils._build_story_cite_element(title.to_s)
      end

      def log_empty_title(title_raw)
        Logger.log_liquid_failure(
          context: @context,
          tag_type: 'RENDER_SHORT_STORY_LINK',
          reason: 'Input story title resolved to an empty string.',
          identifiers: { TitleInput: title_raw || 'nil' },
          level: :warn,
        )
      end

      def find_target_location
        cache = @site.data['link_cache'] || {}
        locations = (cache['short_stories'] || {})[@norm_title]

        return log_not_found if locations.nil? || locations.empty?

        resolve_ambiguity(locations, cache['url_to_canonical_map'] || {})
      end

      def resolve_ambiguity(locations, canonical_map)
        # 1. Prefer canonical locations
        canonical_result = try_canonical_locations(locations, canonical_map)
        return canonical_result if canonical_result

        # 2. Check if all locations point to the same book
        return locations.first if all_same_book?(locations)

        # 3. Use book filter if provided
        book_filter_result = try_book_filter(locations)
        return book_filter_result unless book_filter_result == :skip

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

      def log_not_found
        @log_output = Logger.log_liquid_failure(
          context: @context,
          tag_type: 'RENDER_SHORT_STORY_LINK',
          reason: 'Could not find short story in cache.',
          identifiers: { StoryTitle: @title_input },
          level: :info,
        )
        nil
      end

      def log_not_found_in_book
        @log_output = Logger.log_liquid_failure(
          context: @context,
          tag_type: 'RENDER_SHORT_STORY_LINK',
          reason: 'Story found in cache but not in the specified book.',
          identifiers: { StoryTitle: @title_input, FromBook: @book_filter },
          level: :warn,
        )
        nil
      end

      def log_ambiguous(locations)
        @ambiguous = true
        books = locations.map { |loc| "'#{loc['parent_book_title']}'" }.join(', ')
        @log_output = Logger.log_liquid_failure(
          context: @context,
          tag_type: 'RENDER_SHORT_STORY_LINK',
          reason: "Ambiguous story title. Use 'from_book' to specify which book.",
          identifiers: { StoryTitle: @title_input, FoundIn: books },
          level: :error,
        )
        nil
      end
    end
  end
end
