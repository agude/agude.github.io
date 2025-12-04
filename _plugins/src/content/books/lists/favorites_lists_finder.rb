# frozen_string_literal: true

# _plugins/logic/book_lists/favorites_lists_finder.rb
require_relative 'shared'
require_relative '../../../infrastructure/text_processing_utils'

module Jekyll
  module Books
    module Lists
      module Renderers
        module BookLists
          # Finds and structures "favorites" lists from posts.
          #
          # Handles validation of prerequisites (site.posts and favorites cache),
          # fetching posts marked as favorites lists, and organizing books for each list.
          class FavoritesListsFinder
            include Jekyll::Books::Lists::Renderers::BookLists::Shared

            def initialize(site:, context:)
              @site = site
              @context = context
            end

            # Finds and structures favorites lists.
            # @return [Hash] Contains :favorites_lists (Array of Hashes), :log_messages (String).
            def find
              return favorites_error_response unless favorites_prerequisites_met?

              favorites_lists_data = build_favorites_lists
              log_msg = generate_favorites_log(favorites_lists_data)

              { favorites_lists: favorites_lists_data, log_messages: log_msg }
            end

            private

            def favorites_prerequisites_met?
              @site&.posts&.docs.is_a?(Array) && @site.data.dig('link_cache', 'favorites_posts_to_books')
            end

            def favorites_error_response
              return_error(
                'Prerequisites missing: site.posts or favorites_posts_to_books cache.',
                identifiers: {},
                key: :favorites_lists,
                tag_type: 'BOOK_LIST_FAVORITES'
              )
            end

            def build_favorites_lists
              cache = @site.data['link_cache']['favorites_posts_to_books']
              posts = sorted_favorites_posts

              posts.map { |post| create_favorites_list_entry(post, cache) }
            end

            def sorted_favorites_posts
              @site.posts.docs.select { |p| p.data.key?('is_favorites_list') }
                   .sort_by { |p| p.data['is_favorites_list'].to_i }
                   .reverse
            end

            def create_favorites_list_entry(post, cache)
              books = cache[post.url] || []
              sorted = books.sort_by do |b|
                Jekyll::Infrastructure::TextProcessingUtils.normalize_title(b.data['title'].to_s,
                                                                            strip_articles: true)
              end
              { post: post, books: sorted }
            end

            def generate_favorites_log(data)
              return String.new unless data.empty?

              Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
                context: @context,
                tag_type: 'BOOK_LIST_FAVORITES',
                reason: "No posts with 'is_favorites_list' front matter found.",
                identifiers: {},
                level: :info
              ).dup
            end
          end
        end
      end
    end
  end
end
