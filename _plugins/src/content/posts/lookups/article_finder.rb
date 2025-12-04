# frozen_string_literal: true

# _plugins/logic/card_lookups/article_finder.rb
require_relative '../../../infrastructure/tag_argument_utils'

module Jekyll
  module Posts
    module Lookups
      module CardLookups
        # Finds a post document by URL.
        #
        # Searches the posts collection for a post with a matching URL.
        # Returns a hash with :post (the found document or nil) and :error
        # (nil on success, or a hash with :type and :details on failure).
        class ArticleFinder
          def initialize(site:, url_markup:, context:)
            @site = site
            @url_markup = url_markup
            @context = context
          end

          def find
            target_url = resolve_target_url
            return error_result(:url_error, nil, target_url) unless target_url

            posts = validate_posts_collection
            return error_result(:collection_error, @collection_error_type, target_url) unless posts

            post = posts.find { |p| p.url == target_url }
            return error_result(:post_not_found, target_url, target_url) unless post

            { post: post, url: target_url, error: nil }
          end

          private

          def resolve_target_url
            raw = Jekyll::Infrastructure::TagArgumentUtils.resolve_value(@url_markup, @context).to_s.strip
            return nil if raw.empty?

            raw.start_with?('/') ? raw : "/#{raw}"
          end

          def validate_posts_collection
            proxy = @site.posts

            # Check validity of posts collection. nil.respond_to? is valid (returns false), so &. is not needed.
            return proxy.docs if proxy.respond_to?(:docs) && proxy.docs.is_a?(Array)

            capture_collection_error(proxy)
            nil
          end

          def capture_collection_error(proxy)
            @collection_error_type = if proxy.respond_to?(:docs)
                                       proxy.docs.class.name
                                     elsif proxy
                                       proxy.class.name
                                     else
                                       'nil'
                                     end
          end

          def error_result(type, details = nil, url = nil)
            { post: nil, url: url, error: { type: type, details: details } }
          end
        end
      end
    end
  end
end
