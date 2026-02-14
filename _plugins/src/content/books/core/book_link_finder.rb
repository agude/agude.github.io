# frozen_string_literal: true

# _plugins/src/content/books/core/book_link_finder.rb
require 'jekyll'
require 'date'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../../../infrastructure/text_processing_utils'

module Jekyll
  module Books
    module Core
      # Finds book data without any formatting.
      #
      # This class separates data fetching from formatting concerns.
      # It returns a data hash that can be passed to LinkFormatter.
      #
      # @example
      #   finder = BookLinkFinder.new(context)
      #   data = finder.find('Hyperion')
      #   # => { found: true, display_name: 'Hyperion', url: '/books/...', cite: true, ... }
      #
      #   # Then format with:
      #   LinkFormatter.html(data[:display_name], data[:url], wrapper: :cite, css_class: 'book-title')
      class BookLinkFinder
        Logger = Jekyll::Infrastructure::PluginLoggerUtils
        Text = Jekyll::Infrastructure::TextProcessingUtils
        private_constant :Logger, :Text

        def initialize(context)
          @context = context
          registers = context.respond_to?(:registers) ? context.registers : nil
          @site = registers&.[](:site)
          @page = registers&.[](:page)
          @log_output = ''
        end

        # Finds book data by title.
        #
        # @param title_raw [String] The book title to search for.
        # @param override [String, nil] Optional display text override.
        # @param author_filter [String, nil] Optional author to disambiguate.
        # @param date_filter [String, nil] Optional date to filter by.
        # @param cite [Boolean] Whether to use cite styling (passed through).
        # @return [Hash] Book data with keys:
        #   - :found [Boolean] Whether book was found in cache
        #   - :display_name [String] Text to display
        #   - :url [String, nil] URL to book page
        #   - :cite [Boolean] Whether to use cite styling
        #   - :log_output [String] Any log messages generated
        def find(title_raw, override: nil, author_filter: nil, date_filter: nil, cite: true)
          return empty_result(title_raw, cite) unless @site

          @title = title_raw.to_s
          @norm_title = Text.normalize_title(@title)
          @date_filter = normalize_date_filter(date_filter)
          @cite = cite

          return empty_result_with_log(@title, cite, log_empty_title) if @norm_title.empty?

          candidates = find_candidates
          display_name = determine_display_name(override)

          return not_found_result(display_name, cite) if candidates.empty?

          book_data = filter_candidates(candidates, author_filter)
          return not_found_result(display_name, cite) if book_data.nil?

          build_result(
            found: true,
            display_name: override_or_canonical(override, book_data),
            url: book_data['url'],
            cite: cite
          )
        end

        private

        def empty_result(title_input, cite)
          {
            found: false,
            display_name: title_input.to_s,
            url: nil,
            cite: cite,
            log_output: ''
          }
        end

        def empty_result_with_log(title_input, cite, log_msg)
          {
            found: false,
            display_name: title_input.to_s,
            url: nil,
            cite: cite,
            log_output: log_msg
          }
        end

        def not_found_result(display_name, cite)
          track_unreviewed_mention
          {
            found: false,
            display_name: display_name,
            url: nil,
            cite: cite,
            log_output: @log_output
          }
        end

        def build_result(found:, display_name:, url:, cite:)
          {
            found: found,
            display_name: display_name,
            url: url,
            cite: cite,
            log_output: @log_output
          }
        end

        def find_candidates
          cache = @site.data['link_cache'] || {}
          (cache.dig('books', @norm_title) || []).reject { |b| b['canonical_url']&.start_with?('/') }
        end

        def determine_display_name(override)
          if override && !override.to_s.strip.empty?
            override.to_s.strip
          else
            @title
          end
        end

        def override_or_canonical(override, book_data)
          if override && !override.to_s.strip.empty?
            override.to_s.strip
          else
            book_data['title']
          end
        end

        def filter_candidates(candidates, author_filter)
          # Apply date filter first if provided
          candidates = filter_by_date(candidates) if @date_filter
          if candidates.empty? && @date_filter
            @log_output = log_date_mismatch
            return nil
          end

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

        def filter_by_author(candidates, author_filter)
          ac = @site.data.dig('link_cache', 'authors') || {}
          target = get_canonical_author(author_filter, ac)

          found = candidates.find do |book|
            book['authors'].any? do |auth|
              bc = get_canonical_author(auth, ac)
              bc && target && bc.casecmp(target).zero?
            end
          end

          @log_output = log_author_mismatch(author_filter) unless found
          found
        end

        def get_canonical_author(name, cache)
          return nil if name.to_s.strip.empty?

          norm = Text.normalize_title(name.to_s.strip)
          cache[norm] ? cache[norm]['title'] : name.to_s.strip
        end

        def track_unreviewed_mention
          return unless @page && @page['url'] && !@norm_title.empty?

          tracker = @site.data['mention_tracker']
          return unless tracker

          initialize_tracker_entry(tracker)
          update_tracker_entry(tracker)
        end

        def initialize_tracker_entry(tracker)
          tracker[@norm_title] ||= { original_titles: Hash.new(0), sources: Set.new }
        end

        def update_tracker_entry(tracker)
          tracker[@norm_title][:original_titles][@title.strip] += 1
          tracker[@norm_title][:sources] << @page['url']
        end

        def raise_ambiguous_error(candidates)
          names = candidates.map { |c| "'#{c['authors'].join(', ')}'" }.join('; ')
          raise Jekyll::Errors::FatalException, <<~MSG
            [FATAL] Ambiguous book title in `book_link` tag.
            Page: #{@page&.[]('path') || 'unknown'}
            Tag: {% book_link "#{@title}" %}
            Reason: The book title "#{@title}" is used by multiple authors: #{names}.
            Fix: Add an author parameter, e.g., {% book_link "#{@title}" author="Author Name" %}
          MSG
        end

        def log_empty_title
          Logger.log_liquid_failure(
            context: @context, tag_type: 'RENDER_BOOK_LINK',
            reason: 'Input title resolved to empty after normalization.',
            identifiers: { TitleInput: @title || 'nil' }, level: :warn
          )
        end

        def log_date_mismatch
          Logger.log_liquid_failure(
            context: @context, tag_type: 'RENDER_BOOK_LINK',
            reason: 'Book title exists, but not on the specified date.',
            identifiers: { Title: @title, DateFilter: @date_filter.to_s }, level: :warn
          )
        end

        def log_author_mismatch(author_filter)
          Logger.log_liquid_failure(
            context: @context, tag_type: 'RENDER_BOOK_LINK',
            reason: 'Book title exists, but not by the specified author.',
            identifiers: { Title: @title, AuthorFilter: author_filter }, level: :warn
          )
        end

        def log_not_found
          @log_output = Logger.log_liquid_failure(
            context: @context, tag_type: 'RENDER_BOOK_LINK',
            reason: 'Could not find book page in cache.',
            identifiers: { Title: @title.strip }, level: :info
          )
        end
      end
    end
  end
end
