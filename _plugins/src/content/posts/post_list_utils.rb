# frozen_string_literal: true

# _plugins/utils/post_list_utils.rb
require_relative '../../infrastructure/plugin_logger_utils'
require_relative '../../infrastructure/text_processing_utils' # Potentially for sorting by title if needed

# Utility module for fetching and filtering blog posts by category.
module PostListUtils
  # Fetches posts for a specific category, optionally excluding a URL, sorted by date.
  #
  # @param site [Jekyll::Site] The Jekyll site object.
  # @param category_name [String] The name of the category.
  # @param context [Liquid::Context] The Liquid context for logging.
  # @param exclude_url [String, nil] A URL to exclude from the results.
  # @return [Hash] A hash containing :posts (Array of Jekyll::Document) and :log_messages (String).
  def self.get_posts_by_category(site:, category_name:, context:, exclude_url: nil)
    CategoryFetcher.new(site, category_name, context, exclude_url).fetch
  end

  # Helper class to handle category post fetching logic
  class CategoryFetcher
    def initialize(site, category_name, context, exclude_url)
      @site = site
      @category_name = category_name
      @context = context
      @exclude_url = exclude_url
      @log_messages = +'' # Initialize as mutable string
    end

    def fetch
      return result([]) unless valid_category_name?

      canonical_key = find_canonical_key
      return result([]) unless canonical_key

      raw_posts = @site.categories[canonical_key]
      return handle_empty_category(canonical_key) if raw_posts.nil? || raw_posts.empty?

      filtered_posts = filter_posts(raw_posts)
      check_all_filtered(filtered_posts, raw_posts, canonical_key)

      result(filtered_posts)
    end

    private

    def result(posts)
      { posts: posts, log_messages: @log_messages }
    end

    def valid_category_name?
      if @category_name.nil? || @category_name.to_s.strip.empty?
        log('Category name was nil or empty.', { category_input: @category_name || 'N/A' }, :warn)
        return false
      end
      true
    end

    def find_canonical_key
      key = @site.categories.keys.find { |k| k.casecmp(@category_name.to_s.strip).zero? }
      log('Category not found.', { category_name: @category_name }, :info) unless key
      key
    end

    def handle_empty_category(key)
      log('No posts found in category.', { category_name: key }, :info)
      result([])
    end

    def filter_posts(posts)
      processed = posts.reject { |post| post.data['published'] == false }
      processed.reject! { |post| post.url == @exclude_url } if @exclude_url && !@exclude_url.to_s.strip.empty?
      processed
    end

    def check_all_filtered(filtered, raw, key)
      return unless filtered.empty? && raw.any?

      log(
        'No posts found in category after filtering (e.g., excluded current page or unpublished).',
        { category_name: key, excluded_url: @exclude_url || 'N/A' },
        :info
      )
    end

    def log(reason, identifiers, level)
      @log_messages << PluginLoggerUtils.log_liquid_failure(
        context: @context,
        tag_type: 'POST_LIST_UTIL_CATEGORY',
        reason: reason,
        identifiers: identifiers,
        level: level
      )
    end
  end
end
