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
    # 1. Initial Setup & Validation
    unless context && (site = context.registers[:site])
      prepared_fallback_title = TypographyUtils.prepare_display_title(story_title_raw.to_s)
      return "<cite class=\"short-story-title\">#{prepared_fallback_title}</cite>"
    end

    story_title_input = story_title_raw.to_s.strip
    from_book_title = from_book_title_raw.to_s.strip if from_book_title_raw
    normalized_lookup_title = TextProcessingUtils.normalize_title(story_title_input)

    if normalized_lookup_title.empty?
      return PluginLoggerUtils.log_liquid_failure(
        context: context, tag_type: 'RENDER_SHORT_STORY_LINK',
        reason: 'Input story title resolved to an empty string.',
        identifiers: { TitleInput: story_title_raw || 'nil' },
        level: :warn
      )
    end

    # 2. Lookup from Cache
    log_output = ''
    link_cache = site.data['link_cache'] || {}
    story_cache = link_cache['short_stories'] || {}
    canonical_map = link_cache['url_to_canonical_map'] || {}
    found_locations = story_cache[normalized_lookup_title]

    target_location = nil

    if found_locations.nil? || found_locations.empty?
      log_output = _log_story_not_found(context, story_title_input)
    else
      # Filter for canonical locations first. A location is canonical if its parent book's URL
      # maps to itself in the canonical_map.
      canonical_locations = found_locations.select do |loc|
        canonical_map[loc['url']] == loc['url']
      end

      # If we found exactly one canonical location, that's our target.
      if canonical_locations.length == 1
        target_location = canonical_locations.first
        # If we found zero canonical locations (e.g., story only in archived reviews),
        # or more than one (genuinely ambiguous), we proceed to disambiguation.
      else
        # Check if all found locations are in the same book (covers multi-mention case).
        unique_book_urls = found_locations.map { |loc| loc['url'] }.uniq
        if unique_book_urls.length == 1
          target_location = found_locations.first
        elsif from_book_title && !from_book_title.empty?
          # Genuinely ambiguous: The same story title exists in multiple different books.
          target_location = found_locations.find { |loc| loc['parent_book_title'].casecmp(from_book_title).zero? }
          log_output = _log_story_not_found_in_book(context, story_title_input, from_book_title) if target_location.nil?
        else
          log_output = _log_story_ambiguous(context, story_title_input, found_locations)
        end
      end
    end

    # 3. Generate HTML
    display_text = target_location ? target_location['title'] : story_title_input
    cite_element = _build_story_cite_element(display_text)
    final_html = ''

    if target_location
      # Construct the full URL with fragment
      full_url = "#{target_location['url']}##{target_location['slug']}"
      # Use the generic link helper to create the <a> tag
      final_html = LinkHelperUtils._generate_link_html(context, full_url, cite_element)
    else
      # If no target was found for any reason, return the unlinked cite element
      final_html = cite_element
    end

    log_output + final_html
  end

  def self._build_story_cite_element(display_text)
    prepared_display_text = TypographyUtils.prepare_display_title(display_text)
    "<cite class=\"short-story-title\">#{prepared_display_text}</cite>"
  end

  def self._log_story_not_found(context, title)
    PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: 'RENDER_SHORT_STORY_LINK',
      reason: 'Could not find short story in cache.',
      identifiers: { StoryTitle: title },
      level: :info
    )
  end

  def self._log_story_not_found_in_book(context, title, book_title)
    PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: 'RENDER_SHORT_STORY_LINK',
      reason: 'Story found in cache but not in the specified book.',
      identifiers: { StoryTitle: title, FromBook: book_title },
      level: :warn
    )
  end

  def self._log_story_ambiguous(context, title, locations)
    book_titles = locations.map { |loc| "'#{loc['parent_book_title']}'" }.join(', ')
    PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: 'RENDER_SHORT_STORY_LINK',
      reason: "Ambiguous story title. Use 'from_book' to specify which book.",
      identifiers: { StoryTitle: title, FoundIn: book_titles },
      level: :error
    )
  end
end
