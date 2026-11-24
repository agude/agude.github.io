# frozen_string_literal: true

require_relative '../../../infrastructure/plugin_logger_utils'

module Jekyll
  module Books
    module Ranking
      # Ranks reviewed and unreviewed works using the site's recorded mentions.
      class Finder
        def initialize(context)
          @context = context
          @site = context.registers[:site]
        end

        def by_backlinks
          data = @site&.data
          backlinks = data&.dig('link_cache', 'backlinks')
          if backlinks && (books = data.dig('link_cache', 'books'))
            items = backlink_items(backlinks, books_by_url(books))
            return { logs: '', ranked_list: rank_by_count(items) }
          end

          logs = log_missing_data(
            'RANKED_BY_BACKLINKS', 'Prerequisites missing: link_cache, backlinks, or books cache.',
          )
          { logs: logs, ranked_list: [] }
        end

        def unreviewed_mentions
          data = @site&.data
          if data && data['mention_tracker'] && data.dig('link_cache', 'books')
            items = unreviewed_items(data['mention_tracker'], data['link_cache']['books'])
            return { logs: '', mentions: rank_by_count(items) }
          end

          logs = log_missing_data(
            'UNREVIEWED_MENTIONS', "Prerequisites missing: mention_tracker or link_cache['books'] not found.",
          )
          { logs: logs, mentions: [] }
        end

        private

        def log_missing_data(tag_type, reason)
          Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
            context: @context, tag_type: tag_type, reason: reason, level: :error,
          )
        end

        def books_by_url(books_cache)
          books_cache.values.flatten.each_with_object({}) do |book, by_url|
            by_url[book['url']] ||= book
          end
        end

        # @gotcha Counts cached sources per review URL. The review page's
        #   backlinks merge book families and series links before display.
        def backlink_items(backlinks, books)
          backlinks.filter_map do |url, sources|
            book = books[url]
            next unless book

            { title: book['title'], url: url, count: sources.length }
          end
        end

        def unreviewed_items(tracker, books)
          tracker.filter_map do |normalized_title, data|
            next if books.key?(normalized_title)

            { title: find_display_title(data, normalized_title), count: data[:sources].size }
          end
        end

        def find_display_title(data, normalized_title)
          data[:original_titles].max_by { |_, count| count }&.first || normalized_title
        end

        def rank_by_count(items)
          items.sort_by { |item| -item[:count] }
        end
      end
    end
  end
end
