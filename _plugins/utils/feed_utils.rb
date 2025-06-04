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

    # Process posts
    if site.posts&.docs&.is_a?(Array)
      posts = site.posts.docs.select do |post|
        post.data['published'] != false && post.date.is_a?(Time)
      end
      all_items.concat(posts)
    end

    # Process books
    if site.collections['books']&.docs&.is_a?(Array)
      books = site.collections['books'].docs.select do |book|
        book.data['published'] != false && book.date.is_a?(Time)
      end
      all_items.concat(books)
    end

    # Sort all collected items by date, most recent first
    all_items.sort_by! { |item| item.date }.reverse!

    # Return the limited number of items
    all_items.slice(0, limit)
  end

end
