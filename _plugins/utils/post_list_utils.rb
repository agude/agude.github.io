# _plugins/utils/post_list_utils.rb
require_relative 'plugin_logger_utils'
require_relative 'text_processing_utils' # Potentially for sorting by title if needed

module PostListUtils
  # Fetches posts for a specific category, optionally excluding a URL, sorted by date.
  #
  # @param site [Jekyll::Site] The Jekyll site object.
  # @param category_name [String] The name of the category.
  # @param context [Liquid::Context] The Liquid context for logging.
  # @param exclude_url [String, nil] A URL to exclude from the results.
  # @return [Hash] A hash containing :posts (Array of Jekyll::Document) and :log_messages (String).
  def self.get_posts_by_category(site:, category_name:, context:, exclude_url: nil)
    log_messages = ''

    unless category_name && !category_name.to_s.strip.empty?
      log_messages << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: 'POST_LIST_UTIL_CATEGORY',
        reason: 'Category name was nil or empty.',
        identifiers: { category_input: category_name || 'N/A' },
        level: :warn
      )
      return { posts: [], log_messages: log_messages }
    end

    # Jekyll stores categories as site.categories['Category Name']
    # Category names in Jekyll are case-sensitive as stored in the site.categories hash.
    # However, front matter categories might be mixed case.
    # We should probably find the canonical category name.
    # For now, assume category_name is the correct key.
    # A more robust approach would be to iterate site.categories.keys and find a case-insensitive match.
    # Let's try to find the canonical key:
    canonical_category_key = site.categories.keys.find { |key| key.casecmp(category_name.to_s.strip).zero? }

    unless canonical_category_key
      log_messages << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: 'POST_LIST_UTIL_CATEGORY',
        reason: 'Category not found.',
        identifiers: { category_name: category_name },
        level: :info # It's an expected case that a category might not exist or have posts
      )
      return { posts: [], log_messages: log_messages }
    end

    category_posts = site.categories[canonical_category_key]

    if category_posts.nil? || category_posts.empty?
      log_messages << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: 'POST_LIST_UTIL_CATEGORY',
        reason: 'No posts found in category.',
        identifiers: { category_name: canonical_category_key }, # Log with the canonical name
        level: :info
      )
      return { posts: [], log_messages: log_messages }
    end

    # Filter out unpublished posts and sort by date (most recent first)
    # site.categories already returns posts sorted by date descending.
    # We just need to ensure they are published and optionally filter by exclude_url.
    processed_posts = category_posts.reject { |post| post.data['published'] == false }

    processed_posts.reject! { |post| post.url == exclude_url } if exclude_url && !exclude_url.to_s.strip.empty?

    # If after filtering, the list is empty, we might want a specific log.
    if processed_posts.empty? && category_posts.any? # Original category had posts, but they were all filtered out
      log_messages << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: 'POST_LIST_UTIL_CATEGORY',
        reason: 'No posts found in category after filtering (e.g., excluded current page or unpublished).',
        identifiers: { category_name: canonical_category_key, excluded_url: exclude_url || 'N/A' },
        level: :info
      )
    end

    { posts: processed_posts, log_messages: log_messages }
  end
end
