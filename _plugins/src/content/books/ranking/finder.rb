# frozen_string_literal: true

# _plugins/logic/ranked_by_backlinks/finder.rb
require_relative '../../../infrastructure/plugin_logger_utils'

module Jekyll
  module Books
    module Ranking
      module RankedByBacklinks
        # Finds and ranks books by their backlink count.
        #
        # Returns a hash with:
        #   - logs: Error/warning messages (empty string if none)
        #   - ranked_list: Array of hashes with { title:, url:, count: } sorted by count descending
        class Finder
          def initialize(context)
            @context = context
            @site = context.registers[:site]
          end

          def find
            log_message = check_prerequisites
            return { logs: log_message, ranked_list: [] } if log_message

            url_to_book_map = build_url_to_book_map(@site.data['link_cache']['books'])
            ranked_list = build_ranked_list(@site.data['link_cache']['backlinks'], url_to_book_map)

            { logs: '', ranked_list: ranked_list }
          end

          private

          def check_prerequisites
            return nil if @site&.data&.dig('link_cache', 'backlinks') && @site.data.dig('link_cache', 'books')

            Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
              context: @context,
              tag_type: 'RANKED_BY_BACKLINKS',
              reason: 'Prerequisites missing: link_cache, backlinks, or books cache.',
              level: :error,
            )
          end

          def build_url_to_book_map(books_cache)
            url_to_book_map = {}
            books_cache.values.flatten.each do |book_data|
              url_to_book_map[book_data['url']] ||= book_data
            end
            url_to_book_map
          end

          def build_ranked_list(backlinks_cache, url_to_book_map)
            items = backlinks_cache.map do |url, sources|
              book_data = url_to_book_map[url]
              next unless book_data

              {
                title: book_data['title'],
                url: url,
                count: sources.length,
              }
            end
            items.compact.sort_by { |item| -item[:count] }
          end
        end
      end
    end
  end
end
