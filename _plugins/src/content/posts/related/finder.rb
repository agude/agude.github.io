# frozen_string_literal: true

require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../../../infrastructure/page_url'
require_relative '../../related_candidates'

module Jekyll
  module Posts
    module Related
      # Finds related or recent posts for a given page.
      #
      # Handles all logic for selecting posts based on category matching,
      # with fallback to recent posts. Returns structured data without HTML.
      class Finder
        DEFAULT_MAX_POSTS = 3

        def initialize(site, page = nil, max_posts = nil)
          @site = site
          @page = page
          @max_posts = max_posts || @site&.config&.dig('display_limits', 'related_posts') || DEFAULT_MAX_POSTS
          @now_unix = @site.time.to_i if @site
          @found_by_category = false
        end

        def find
          unless prerequisites_met?
            log_output = log_missing_prerequisites
            return { logs: log_output, posts: [], found_by_category: false }
          end

          final_posts = gather_posts

          { logs: '', posts: final_posts, found_by_category: @found_by_category }
        end

        private

        def page_url
          Jekyll::Infrastructure::PageUrl.fetch(@page)
        end

        def prerequisites_met?
          @site && @page && site_posts_valid? && page_url_valid?
        end

        def site_posts_valid?
          @site.respond_to?(:posts) && @site.posts.respond_to?(:docs) && @site.posts.docs.is_a?(Array)
        end

        def page_url_valid?
          page_url && !page_url.to_s.strip.empty?
        end

        def log_missing_prerequisites
          missing = collect_missing_items
          Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
            context: log_context,
            tag_type: 'RELATED_POSTS',
            reason: "Missing prerequisites: #{missing.join(', ')}.",
            identifiers: { PageURL: page_url || 'N/A' },
            level: :error,
          )
        end

        # Builds a minimal context-like object for PluginLoggerUtils.
        def log_context
          page = @page
          site = @site
          Object.new.tap do |ctx|
            ctx.define_singleton_method(:registers) { { site: site, page: page } }
          end
        end

        def collect_missing_items
          missing = []
          missing << 'site object' unless @site
          missing << 'page object' unless @page
          missing << "site.posts.docs (#{site_posts_detail})" unless site_posts_valid?
          add_page_url_errors(missing)
          missing
        end

        def add_page_url_errors(missing)
          if @site && @page && !page_url_valid?
            missing << "page['url'] (present and not empty)"
          elsif !@site || !@page
            missing << "page['url'] (cannot check, site or page missing)"
          end
        end

        def site_posts_detail
          if @site.respond_to?(:posts) && @site.posts.respond_to?(:docs)
            "site.posts.docs is #{@site.posts.docs.class.name}, not Array"
          elsif @site.respond_to?(:posts) && @site.posts
            'site.posts does not have .docs'
          else
            'site.posts object itself is problematic or nil'
          end
        end

        def gather_posts
          @excluded_urls = [page_url]
          @all_posts = filter_and_sort_posts(@site.posts.docs)

          # Waterfall priority: category matches > config posts > recent posts
          candidates = []
          candidates.concat(find_by_category)
          candidates.concat(find_from_config) if candidates.length < @max_posts
          candidates.concat(@all_posts) if candidates.length < @max_posts

          Jekyll::Content::RelatedCandidates.limit(candidates, @max_posts)
        end

        def filter_and_sort_posts(posts)
          eligible = Jekyll::Content::RelatedCandidates.select(posts, @excluded_urls, @now_unix) do |post|
            post.respond_to?(:data) && post.respond_to?(:url) && post.respond_to?(:date)
          end
          eligible.sort_by(&:date).reverse
        end

        def find_by_category
          cats = Set.new(@page['categories'] || [])
          return [] if cats.empty?

          matches = @all_posts.select do |p|
            Set.new(p.data['categories'] || []).intersect?(cats)
          end
          @found_by_category = !matches.empty?
          matches
        end

        def find_from_config
          config_posts = @site.config['related_posts']
          return [] unless config_posts.is_a?(Array)

          filter_and_sort_posts(config_posts)
        end
      end
    end
  end
end
