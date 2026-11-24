# frozen_string_literal: true

require 'date'
require_relative '../../../infrastructure/links/link_resolver_support'
require_relative '../../../infrastructure/typography_utils'
require_relative '../../../infrastructure/link_cache/book_candidate_selector'
require_relative 'book_preview_renderer'

module Jekyll
  module Books
    module Core
      # Helper class to handle the complexity of resolving a book link
      class BookLinkResolver
        include Jekyll::Infrastructure::Links::LinkResolverSupport

        LINK_STATUSES = [:empty_title].freeze

        Typography = Jekyll::Infrastructure::TypographyUtils
        BookSelector = Jekyll::Infrastructure::LinkCache::BookCandidateSelector
        ResolverSupport = Jekyll::Infrastructure::Links::LinkResolverSupport
        PreviewRenderer = Jekyll::Books::Core::BookPreviewRenderer
        private_constant :Typography, :BookSelector, :PreviewRenderer, :ResolverSupport

        # Renders the book link/cite HTML directly from title and URL data.
        # Used when the book data is already known (e.g., from backlinks).
        #
        # @param title [String] The canonical title to display (will be processed).
        # @param url [String] The URL of the book page.
        # @param cite [Boolean] true (default) for <cite> wrapper, false for span.book-text.
        # @param preview_html [String, nil] Optional hover-preview markup for cross-page links.
        # @return [String] The generated HTML.
        def render_from_data(title, url, cite: true, preview_html: nil)
          wrap_with_link(build_book_element(title, cite: cite), url, preview_html)
        end

        def resolve_data(title_raw, text_override, author_filter, date_filter = nil, cite: true)
          return no_site_result(title_raw) unless @site

          initialize_resolve_state(title_raw, date_filter)
          return empty_title_result if @norm_title.empty?

          override = text_override.to_s.strip if text_override && !text_override.to_s.empty?
          entries = find_in_cache('books', @norm_title) || []
          candidates = ResolverSupport.canonical_book_candidates(entries)
          result = candidates.empty? ? log_not_found : filter_candidates(candidates, author_filter)
          if result.is_a?(String)
            @log_output = result
            return not_found_result(override || @title, cite)
          end

          build_result_hash(result, override || result['title'], cite)
        end

        private

        def no_site_result(title_raw)
          {
            status: :no_site,
            url: nil,
            display_text: title_raw.to_s,
            canonical_title: nil,
            cite: nil,
          }.freeze
        end

        def initialize_resolve_state(title_raw, date_filter)
          @title = title_raw.to_s
          @norm_title = Text.normalize_title(@title)
          @date_filter = normalize_date_filter(date_filter)
          @log_output = ''
        end

        def empty_title_result
          @log_output = log_failure(
            tag_type: 'RENDER_BOOK_LINK',
            reason: 'Input title resolved to empty after normalization.',
            identifiers: { TitleInput: @title || 'nil' },
            level: :warn,
          )
          {
            status: :empty_title,
            url: nil,
            display_text: nil,
            canonical_title: nil,
            cite: nil,
          }.freeze
        end

        def not_found_result(display_text, cite)
          {
            status: :not_found,
            url: nil,
            display_text: display_text,
            canonical_title: nil,
            cite: cite,
          }.freeze
        end

        def build_result_hash(result, display_text, cite)
          {
            status: :found,
            url: result['url'],
            display_text: display_text,
            canonical_title: result['title'],
            cite: cite,
            rating: result['rating'],
            image: result['image'],
            authors: result['authors'],
            series: result['series'],
            book_number: result['book_number'],
          }.freeze
        end

        def link_content(data)
          if data[:status] == :found
            preview = build_preview_html(PreviewRenderer, data, data[:canonical_title])
            cite = data[:cite]
          else
            cite = data[:cite] != false
          end

          [build_book_element(data[:display_text], cite: cite), preview]
        end

        # @gotcha When a book_link resolves to "not found" in HTML mode, the
        #   resolver tracks it as an unreviewed mention. This does not happen
        #   in markdown mode (render_mode: :markdown), to avoid
        #   double-counting the same mention from both render passes.
        def log_not_found
          track_unreviewed_mention unless @context.registers[:render_mode] == :markdown
          log_failure(
            tag_type: 'RENDER_BOOK_LINK',
            reason: 'Could not find book page in cache.',
            identifiers: { Title: @title.strip },
            level: :info,
          )
        end

        def track_unreviewed_mention
          page = @context.registers[:page]
          return unless page && page['url'] && !@norm_title.empty?

          tracker = @site.data['mention_tracker']
          mention = tracker[@norm_title] ||= { original_titles: Hash.new(0), sources: Set.new }
          mention[:original_titles][@title.strip] += 1
          mention[:sources] << page['url']
        end

        # The author rule lives in BookCandidateSelector, which
        # BacklinkBuilder shares; this method only logs and raises.
        def filter_candidates(candidates, author_filter)
          # Apply date filter first if provided
          candidates = filter_by_date(candidates) if @date_filter
          return log_date_mismatch if candidates.empty? && @date_filter

          authors = @site.data.dig('link_cache', 'authors') || {}
          case (result = BookSelector.select_book(candidates, author_filter, authors))
          when :ambiguous then raise_ambiguous_error(candidates)
          when :author_mismatch then log_author_mismatch(author_filter.to_s.strip)
          else result
          end
        end

        def filter_by_date(candidates)
          candidates.select { |book| dates_match?(book['date'], @date_filter) }
        end

        def dates_match?(book_date, target_date)
          return false unless book_date

          normalize_date(book_date) == target_date
        rescue ArgumentError
          false
        end

        def normalize_date(date_input)
          case date_input
          when Date
            date_input
          when Time
            date_input.to_date
          else
            Date.parse(date_input.to_s)
          end
        end

        def normalize_date_filter(date_filter)
          return nil if date_filter.nil? || date_filter.to_s.strip.empty?

          Date.parse(date_filter.to_s)
        rescue ArgumentError
          nil
        end

        def log_date_mismatch
          log_failure(
            tag_type: 'RENDER_BOOK_LINK',
            reason: 'Book title exists, but not on the specified date.',
            identifiers: { Title: @title, DateFilter: @date_filter.to_s },
            level: :warn,
          )
        end

        def log_author_mismatch(author_filter)
          log_failure(
            tag_type: 'RENDER_BOOK_LINK',
            reason: 'Book title exists, but not by the specified author.',
            identifiers: { Title: @title, AuthorFilter: author_filter },
            level: :warn,
          )
        end

        def raise_ambiguous_error(candidates)
          names = candidates.map { |c| "'#{c['authors'].join(', ')}'" }.join('; ')
          raise Jekyll::Errors::FatalException, <<~MSG
            [FATAL] Ambiguous book title in `book_link` tag.
            Page: #{@context.registers[:page]['path']}
            Tag: {% book_link "#{@title}" %}
            Reason: The book title "#{@title}" is used by multiple authors: #{names}.
            Fix: Add an author parameter, e.g., {% book_link "#{@title}" author="Author Name" %}
          MSG
        end

        def build_book_element(display_text, cite:)
          prepared_display_text = Typography.prepare_display_title(display_text)
          if cite
            "<cite class=\"book-title\">#{prepared_display_text}</cite>"
          else
            "<span class=\"book-text\">#{prepared_display_text}</span>"
          end
        end
      end
    end
  end
end
