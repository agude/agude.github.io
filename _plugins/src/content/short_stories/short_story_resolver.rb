# frozen_string_literal: true

require_relative '../../infrastructure/links/link_resolver_support'
require_relative '../../infrastructure/link_cache/short_story_location_selector'
require_relative '../../infrastructure/typography_utils'
require_relative '../books/core/book_preview_renderer'

module Jekyll
  module ShortStories
    # Helper class to handle resolution logic.
    class ShortStoryResolver
      include Jekyll::Infrastructure::Links::LinkResolverSupport

      Typography = Jekyll::Infrastructure::TypographyUtils
      PreviewRenderer = Jekyll::Books::Core::BookPreviewRenderer
      LocationSelector = Jekyll::Infrastructure::LinkCache::ShortStoryLocationSelector
      private_constant :Typography, :PreviewRenderer, :LocationSelector

      def resolve_data(title_raw, book_title_raw)
        return { status: :no_site, url: nil, display_text: title_raw.to_s }.freeze unless @site

        @title_input = title_raw.to_s.strip
        @book_filter = book_title_raw&.to_s&.strip
        @norm_title = Text.normalize_title(@title_input)
        @log_output = ''

        if @norm_title.empty?
          @log_output = log_failure(
            tag_type: 'RENDER_SHORT_STORY_LINK',
            reason: 'Input story title resolved to an empty string.',
            identifiers: { TitleInput: title_raw || 'nil' },
            level: :warn,
          )
          return { status: :empty_title, url: nil, display_text: nil }.freeze
        end

        target = find_target_location
        build_data_hash(target)
      end

      private

      def build_data_hash(target)
        case target
        when :ambiguous, :not_found
          { status: target, url: nil, display_text: @title_input }.freeze
        else
          url = "#{target['url']}##{target['slug']}"
          book = find_parent_book_data(target)
          {
            status: :found,
            url: url,
            display_text: target['title'],
            book_title: book&.[]('title'),
            authors: book&.[]('authors'),
            rating: book&.[]('rating'),
            image: book&.[]('image'),
            series: book&.[]('series'),
            book_number: book&.[]('book_number'),
          }.freeze
        end
      end

      def link_content(data)
        preview = build_preview_html(PreviewRenderer, data, data[:book_title]) if data[:book_title]
        [build_story_cite_element(data[:display_text]), preview]
      end

      def find_target_location
        locations = find_in_cache('short_stories', @norm_title)

        return log_not_found if locations.nil? || locations.empty?

        resolve_ambiguity(locations, @site.data.dig('link_cache', 'url_to_canonical_map'))
      end

      # The selection rules live in ShortStoryLocationSelector, which
      # BacklinkBuilder shares; this method only logs the failures.
      def resolve_ambiguity(locations, canonical_map)
        case (result = LocationSelector.select_location(locations, canonical_map, @book_filter))
        when :not_found_in_book then log_not_found_in_book
        when :ambiguous then log_ambiguous(locations)
        else result
        end
      end

      def log_not_found
        @log_output = log_failure(
          tag_type: 'RENDER_SHORT_STORY_LINK',
          reason: 'Could not find short story in cache.',
          identifiers: { StoryTitle: @title_input },
          level: :info,
        )
        :not_found
      end

      def log_not_found_in_book
        @log_output = log_failure(
          tag_type: 'RENDER_SHORT_STORY_LINK',
          reason: 'Story found in cache but not in the specified book.',
          identifiers: { StoryTitle: @title_input, FromBook: @book_filter },
          level: :warn,
        )
        :not_found
      end

      def log_ambiguous(locations)
        books = locations.map { |loc| "'#{loc['parent_book_title']}'" }.join(', ')
        @log_output = log_failure(
          tag_type: 'RENDER_SHORT_STORY_LINK',
          reason: "Ambiguous story title. Use 'from_book' to specify which book.",
          identifiers: { StoryTitle: @title_input, FoundIn: books },
          level: :error,
        )
        :ambiguous
      end

      def find_parent_book_data(target)
        norm_title = Text.normalize_title(target['parent_book_title'])
        candidates = find_in_cache('books', norm_title) || []
        candidates.find { |b| b['url'] == target['url'] }
      end

      def build_story_cite_element(display_text)
        prepared_display_text = Typography.prepare_display_title(display_text)
        "<cite class=\"short-story-title\">#{prepared_display_text}</cite>"
      end
    end
  end
end
