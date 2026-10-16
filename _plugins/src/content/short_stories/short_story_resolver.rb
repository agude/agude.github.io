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

      def initialize(context)
        super
        @ambiguous = false
      end

      def resolve(title_raw, book_title_raw)
        data = resolve_data(title_raw, book_title_raw)
        render_html_from_data(data)
      end

      def resolve_data(title_raw, book_title_raw)
        return { status: :no_site, url: nil, display_text: title_raw.to_s }.freeze unless @site

        @ambiguous = false
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
        if target
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
        elsif @ambiguous
          { status: :ambiguous, url: nil, display_text: @title_input }.freeze
        else
          { status: :not_found, url: nil, display_text: @title_input }.freeze
        end
      end

      def render_html_from_data(data)
        case data[:status]
        when :no_site
          build_story_cite_element(data[:display_text].to_s)
        when :empty_title
          @log_output
        when :found
          preview_html = build_preview_html(data)
          cite = build_story_cite_element(data[:display_text])
          html = wrap_with_link(cite, data[:url], preview_html)
          @log_output + html
        when :not_found, :ambiguous
          cite = build_story_cite_element(data[:display_text])
          @log_output + cite
        end
      end

      def find_target_location
        cache = @site.data['link_cache'] || {}
        locations = (cache['short_stories'] || {})[@norm_title]

        return log_not_found if locations.nil? || locations.empty?

        resolve_ambiguity(locations, cache['url_to_canonical_map'] || {})
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
        nil
      end

      def log_not_found_in_book
        @log_output = log_failure(
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
        @log_output = log_failure(
          tag_type: 'RENDER_SHORT_STORY_LINK',
          reason: "Ambiguous story title. Use 'from_book' to specify which book.",
          identifiers: { StoryTitle: @title_input, FoundIn: books },
          level: :error,
        )
        nil
      end

      def find_parent_book_data(target)
        cache = @site.data['link_cache'] || {}
        books = cache['books'] || {}
        norm_title = Text.normalize_title(target['parent_book_title'])
        candidates = books[norm_title] || []
        candidates.find { |b| b['url'] == target['url'] }
      end

      def build_preview_html(data)
        return nil unless data[:book_title]
        return nil if PreviewRenderer.building_lede?(@site)

        preview = PreviewRenderer.new(
          @context,
          data[:book_title],
          data[:authors],
          data[:rating],
          data[:image],
          series: data[:series],
          book_number: data[:book_number],
          lede_html: PreviewRenderer.extract_lede(@site, data[:url]),
        )
        html = preview.render
        @log_output = @log_output.to_s + preview.log_output.to_s
        html
      end

      def build_story_cite_element(display_text)
        prepared_display_text = Typography.prepare_display_title(display_text)
        "<cite class=\"short-story-title\">#{prepared_display_text}</cite>"
      end
    end
  end
end
