# frozen_string_literal: true

# _plugins/utils/short_story_link_util.rb
require 'jekyll'
require_relative 'link_helper_utils'
require_relative 'plugin_logger_utils'
require_relative 'text_processing_utils'
require_relative 'typography_utils'

module ShortStoryLinkUtils
  # Renders the HTML for a short story link.
  #
  # @param story_title_raw [String] The title of the story.
  # @param context [Liquid::Context] The current Liquid context.
  # @param from_book_title_raw [String, nil] The title of the book to disambiguate.
  # @return [String] The generated HTML link or span.
  def self.render_short_story_link(story_title_raw, context, from_book_title_raw = nil)
    ShortStoryResolver.new(context).resolve(story_title_raw, from_book_title_raw)
  end

  def self._build_story_cite_element(display_text)
    prepared_display_text = TypographyUtils.prepare_display_title(display_text)
    "<cite class=\"short-story-title\">#{prepared_display_text}</cite>"
  end

  # Helper class to handle resolution logic
  class ShortStoryResolver
    def initialize(context)
      @context = context
      @site = context&.registers&.[](:site)
      @log_output = ''
    end

    def resolve(title_raw, book_title_raw)
      return fallback(title_raw) unless @site

      @title_input = title_raw.to_s.strip
      @book_filter = book_title_raw.to_s.strip if book_title_raw
      @norm_title = TextProcessingUtils.normalize_title(@title_input)

      return log_empty_title(title_raw) if @norm_title.empty?

      target = find_target_location
      render_html(target)
    end

    private

    def fallback(title)
      ShortStoryLinkUtils._build_story_cite_element(title.to_s)
    end

    def log_empty_title(title_raw)
      PluginLoggerUtils.log_liquid_failure(
        context: @context, tag_type: 'RENDER_SHORT_STORY_LINK',
        reason: 'Input story title resolved to an empty string.',
        identifiers: { TitleInput: title_raw || 'nil' }, level: :warn
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
      canon_locs = locations.select { |loc| canonical_map[loc['url']] == loc['url'] }
      return canon_locs.first if canon_locs.length == 1

      # 2. Check if all locations point to the same book
      return locations.first if locations.map { |l| l['url'] }.uniq.length == 1

      # 3. Use book filter if provided
      if @book_filter && !@book_filter.empty?
        match = locations.find { |loc| loc['parent_book_title'].casecmp(@book_filter).zero? }
        return log_not_found_in_book unless match

        return match
      end

      # 4. Ambiguous
      log_ambiguous(locations)
      nil
    end

    def render_html(target)
      display = target ? target['title'] : @title_input
      cite = ShortStoryLinkUtils._build_story_cite_element(display)

      html = if target
               url = "#{target['url']}##{target['slug']}"
               LinkHelperUtils._generate_link_html(@context, url, cite)
             else
               cite
             end

      @log_output + html
    end

    def log_not_found
      @log_output = PluginLoggerUtils.log_liquid_failure(
        context: @context, tag_type: 'RENDER_SHORT_STORY_LINK',
        reason: 'Could not find short story in cache.',
        identifiers: { StoryTitle: @title_input }, level: :info
      )
      nil
    end

    def log_not_found_in_book
      @log_output = PluginLoggerUtils.log_liquid_failure(
        context: @context, tag_type: 'RENDER_SHORT_STORY_LINK',
        reason: 'Story found in cache but not in the specified book.',
        identifiers: { StoryTitle: @title_input, FromBook: @book_filter }, level: :warn
      )
      nil
    end

    def log_ambiguous(locations)
      books = locations.map { |loc| "'#{loc['parent_book_title']}'" }.join(', ')
      @log_output = PluginLoggerUtils.log_liquid_failure(
        context: @context, tag_type: 'RENDER_SHORT_STORY_LINK',
        reason: "Ambiguous story title. Use 'from_book' to specify which book.",
        identifiers: { StoryTitle: @title_input, FoundIn: books }, level: :error
      )
      nil
    end
  end
end
