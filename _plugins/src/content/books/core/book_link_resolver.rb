# frozen_string_literal: true

# _plugins/src/content/books/core/book_link_resolver.rb
require 'date'
require_relative '../../../infrastructure/links/link_resolver_support'
require_relative '../../../infrastructure/typography_utils'

module Jekyll
  module Books
    module Core
      # Helper class to handle the complexity of resolving a book link
      class BookLinkResolver
        include Jekyll::Infrastructure::Links::LinkResolverSupport

        Typography = Jekyll::Infrastructure::TypographyUtils
        private_constant :Typography

        # Renders the book link/cite HTML directly from title and URL data.
        # Used when the book data is already known (e.g., from backlinks).
        #
        # @param title [String] The canonical title to display (will be processed).
        # @param url [String] The URL of the book page.
        # @param cite [Boolean] true (default) for <cite> wrapper, false for span.book-text.
        # @return [String] The generated HTML.
        def render_from_data(title, url, cite: true)
          inner_element = cite ? build_book_cite_element(title) : build_book_text_element(title)
          wrap_with_link(inner_element, url)
        end

        def resolve(title_raw, text_override, author_filter, date_filter = nil, cite: true)
          data = resolve_data(title_raw, text_override, author_filter, date_filter, cite: cite)
          render_html_from_data(data)
        end

        def resolve_data(title_raw, text_override, author_filter, date_filter = nil, cite: true)
          return no_site_result(title_raw) unless @site

          initialize_resolve_state(title_raw, date_filter, cite)
          return empty_title_result if @norm_title.empty?

          candidates = find_candidates
          display_text = determine_display_text(text_override)
          return not_found_result(display_text, cite) if candidates.empty?

          result = filter_candidates(candidates, author_filter)
          build_result_hash(result, display_text, text_override, cite)
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

        def initialize_resolve_state(title_raw, date_filter, cite)
          @title = title_raw.to_s
          @norm_title = Text.normalize_title(@title)
          @date_filter = normalize_date_filter(date_filter)
          @cite = cite
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
          @log_output = log_not_found
          {
            status: :not_found,
            url: nil,
            display_text: display_text,
            canonical_title: nil,
            cite: cite,
          }.freeze
        end

        def build_result_hash(result, display_text, text_override, cite)
          if result.is_a?(String)
            @log_output = result
            return {
              status: :not_found,
              url: nil,
              display_text: display_text,
              canonical_title: nil,
              cite: cite,
            }.freeze
          end

          found_display = text_override && !text_override.to_s.empty? ? text_override.to_s.strip : result['title']
          {
            status: :found,
            url: result['url'],
            display_text: found_display,
            canonical_title: result['title'],
            cite: cite,
          }.freeze
        end

        def render_html_from_data(data)
          case data[:status]
          when :no_site
            fallback(data[:display_text])
          when :empty_title
            @log_output
          when :not_found
            @log_output.to_s + fallback(data[:display_text])
          when :found
            render_from_data(data[:display_text], data[:url], cite: @cite)
          end
        end

        def fallback(title)
          if @cite == false
            build_book_text_element(title.to_s)
          else
            build_book_cite_element(title.to_s)
          end
        end

        def determine_display_text(text_override)
          if text_override && !text_override.to_s.empty?
            text_override.to_s.strip
          else
            @title
          end
        end

        # Filter out archived (non-canonical) reviews. Archived reviews have a
        # local canonical_url (starts with '/') pointing to the canonical page.
        # BookFamilyValidator guarantees canonical pages never have canonical_url.
        def find_candidates
          cache = @site.data['link_cache'] || {}
          (cache.dig('books', @norm_title) || []).reject { |b| b['canonical_url']&.start_with?('/') }
        end

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
          initialize_tracker_entry(tracker)
          update_tracker_entry(tracker, page)
        end

        def initialize_tracker_entry(tracker)
          tracker[@norm_title] ||= { original_titles: Hash.new(0), sources: Set.new }
        end

        def update_tracker_entry(tracker, page)
          tracker[@norm_title][:original_titles][@title.strip] += 1
          tracker[@norm_title][:sources] << page['url']
        end

        def filter_candidates(candidates, author_filter)
          # Apply date filter first if provided
          candidates = filter_by_date(candidates) if @date_filter
          return log_date_mismatch if candidates.empty? && @date_filter

          if author_filter && !author_filter.to_s.strip.empty?
            filter_by_author(candidates, author_filter.to_s.strip)
          elsif candidates.length > 1
            raise_ambiguous_error(candidates)
          else
            candidates.first
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

        def filter_by_author(candidates, author_filter)
          ac = @site.data.dig('link_cache', 'authors') || {}
          target = get_canonical_author(author_filter, ac)

          found = candidates.find do |book|
            book['authors'].any? do |auth|
              bc = get_canonical_author(auth, ac)
              bc && target && bc.casecmp(target).zero?
            end
          end

          return log_author_mismatch(author_filter) unless found

          found
        end

        def get_canonical_author(name, cache)
          return nil if name.to_s.strip.empty?

          norm = Text.normalize_title(name.to_s.strip)
          cache[norm] ? cache[norm]['title'] : name.to_s.strip
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

        def build_book_cite_element(display_text)
          prepared_display_text = Typography.prepare_display_title(display_text)
          "<cite class=\"book-title\">#{prepared_display_text}</cite>"
        end

        def build_book_text_element(display_text)
          prepared_display_text = Typography.prepare_display_title(display_text)
          "<span class=\"book-text\">#{prepared_display_text}</span>"
        end
      end
    end
  end
end
