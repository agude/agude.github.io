# frozen_string_literal: true

# _plugins/src/content/books/core/book_link_resolver.rb
require 'jekyll'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../../../infrastructure/text_processing_utils'
require_relative 'book_link_util'

module Jekyll
  module Books
    module Core
      # Helper class to handle the complexity of resolving a book link
      class BookLinkResolver
        # Aliases for readability
        Logger = Jekyll::Infrastructure::PluginLoggerUtils
        Text = Jekyll::Infrastructure::TextProcessingUtils
        private_constant :Logger, :Text

        def initialize(context)
          @context = context
          registers = context.respond_to?(:registers) ? context.registers : nil
          @site = registers&.[](:site)
        end

        def resolve(title_raw, text_override, author_filter)
          return fallback(title_raw) unless @site

          @title = title_raw.to_s
          @norm_title = Text.normalize_title(@title)
          return log_empty_title if @norm_title.empty?

          candidates = find_candidates
          display_text = determine_display_text(text_override)
          return log_not_found + fallback(display_text) if candidates.empty?

          result = filter_candidates(candidates, author_filter)
          return result + fallback(display_text) if result.is_a?(String)

          render_result(result, text_override)
        end

        # Public method for the module delegate to call
        def track_unreviewed_mention_explicit(title)
          @title = title.to_s
          @norm_title = Text.normalize_title(@title)
          track_unreviewed_mention
        end

        private

        def fallback(title)
          Jekyll::Books::Core::BookLinkUtils._build_book_cite_element(title.to_s)
        end

        def log_empty_title
          Logger.log_liquid_failure(
            context: @context, tag_type: 'RENDER_BOOK_LINK',
            reason: 'Input title resolved to empty after normalization.',
            identifiers: { TitleInput: @title || 'nil' }, level: :warn
          )
        end

        def determine_display_text(text_override)
          if text_override && !text_override.to_s.empty?
            text_override.to_s.strip
          else
            @title
          end
        end

        def find_candidates
          cache = @site.data['link_cache'] || {}
          (cache.dig('books', @norm_title) || []).reject { |b| b['canonical_url']&.start_with?('/') }
        end

        def log_not_found
          track_unreviewed_mention
          Logger.log_liquid_failure(
            context: @context, tag_type: 'RENDER_BOOK_LINK',
            reason: 'Could not find book page in cache.',
            identifiers: { Title: @title.strip }, level: :info
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
          if author_filter && !author_filter.to_s.strip.empty?
            filter_by_author(candidates, author_filter.to_s.strip)
          elsif candidates.length > 1
            raise_ambiguous_error(candidates)
          else
            candidates.first
          end
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
          Logger.log_liquid_failure(
            context: @context, tag_type: 'RENDER_BOOK_LINK',
            reason: 'Book title exists, but not by the specified author.',
            identifiers: { Title: @title, AuthorFilter: author_filter }, level: :warn
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

        def render_result(book_data, text_override)
          display = if text_override && !text_override.to_s.empty?
                      text_override.to_s.strip
                    else
                      book_data['title']
                    end
          Jekyll::Books::Core::BookLinkUtils.render_book_link_from_data(display, book_data['url'], @context)
        end
      end
    end
  end
end
