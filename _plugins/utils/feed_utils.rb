# frozen_string_literal: true

# _plugins/utils/feed_utils.rb
# No specific requires needed from other utils for this basic version,
# but PluginLoggerUtils could be added if logging within the util becomes necessary.

module FeedUtils
  # Combines posts and books, sorts them by date, and returns a limited number.
  #
  # @param site [Jekyll::Site] The Jekyll site object.
  # @param limit [Integer] The maximum number of items to return.
  # @return [Array<Jekyll::Document>] An array of Jekyll documents (posts or books).
  def self.get_combined_feed_items(site:, limit: 5)
    all_items = []
    all_items.concat(_collect_published_posts(site))
    all_items.concat(_collect_published_books(site))
    _sort_and_limit_items(all_items, limit)
  end

  # Collects published posts from the site.
  #
  # @param site [Jekyll::Site] The Jekyll site object.
  # @return [Array<Jekyll::Document>] An array of published posts.
  def self._collect_published_posts(site)
    return [] unless site.posts&.docs.is_a?(Array)

    site.posts.docs.select { |post| _is_published_item?(post) }
  end

  # Collects published books from the site.
  #
  # @param site [Jekyll::Site] The Jekyll site object.
  # @return [Array<Jekyll::Document>] An array of published books.
  def self._collect_published_books(site)
    return [] unless site.collections['books']&.docs.is_a?(Array)

    site.collections['books'].docs.select { |book| _is_published_item?(book) }
  end

  # Checks if an item is published and has a valid date.
  #
  # @param item [Jekyll::Document] The item to check.
  # @return [Boolean] True if the item is published and has a valid date.
  def self._is_published_item?(item)
    item.data['published'] != false && item.date.is_a?(Time)
  end

  # Sorts items by date (most recent first) and returns the limited number.
  #
  # @param items [Array<Jekyll::Document>] The items to sort and limit.
  # @param limit [Integer] The maximum number of items to return.
  # @return [Array<Jekyll::Document>] The sorted and limited items.
  def self._sort_and_limit_items(items, limit)
    items.sort_by!(&:date).reverse!
    items.slice(0, limit)
  end
end
