# frozen_string_literal: true

require_relative '../../../../infrastructure/plugin_logger_utils'

module Jekyll
  module Books
    module Ranking
      module UnreviewedMentions
        # Finder class - handles fetching and filtering unreviewed book mentions
        #
        # Accesses the mention tracker and link cache to build a ranked list of
        # books that have been mentioned but don't have review pages yet.
        class Finder
          def initialize(context)
            @context = context
            @site = context.registers[:site]
          end

          # Main entry point - returns a hash with logs and mention data
          #
          # @return [Hash] with keys:
          #   - :logs [String] - error/warning messages (empty if successful)
          #   - :mentions [Array<Hash>] - ranked list of unreviewed mentions
          def find
            log_output = handle_missing_prerequisites
            return { logs: log_output, mentions: [] } if log_output && !log_output.empty?

            tracker = @site.data['mention_tracker']
            books_cache = @site.data['link_cache']['books']
            existing_book_titles = Set.new(books_cache.keys)

            ranked_list = build_ranked_list(tracker, existing_book_titles)

            { logs: '', mentions: ranked_list }
          end

          private

          def valid_prerequisites?
            @site && @site.data['mention_tracker'] && @site.data.dig('link_cache', 'books')
          end

          def handle_missing_prerequisites
            return '' if valid_prerequisites?

            Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
              context: @context,
              tag_type: 'UNREVIEWED_MENTIONS',
              reason: "Prerequisites missing: mention_tracker or link_cache['books'] not found.",
              level: :error
            )
          end

          def build_ranked_list(tracker, existing_book_titles)
            items = tracker.map do |normalized_title, data|
              next if existing_book_titles.include?(normalized_title)

              display_title = find_display_title(data, normalized_title)

              {
                title: display_title,
                count: data[:sources].size
              }
            end
            items.compact.sort_by { |item| -item[:count] }
          end

          def find_display_title(data, normalized_title)
            data[:original_titles].max_by { |_, count| count }&.first || normalized_title
          end
        end
      end
    end
  end
end
