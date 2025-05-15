# _plugins/related_posts_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/article_card_utils'

module Jekyll
  class RelatedPostsTag < Liquid::Tag
    DEFAULT_MAX_POSTS = 3

    def initialize(tag_name, markup, tokens)
      super
      # No arguments to parse for this tag, but could add max_posts from markup later if needed.
      @max_posts = DEFAULT_MAX_POSTS
    end

    def render(context)
      site = context.registers[:site]
      page = context.registers[:page]

      # --- Basic Sanity Checks ---
      # Check for site, page, site.posts (as a proxy for the posts collection), and page.url
      unless site && page && site.respond_to?(:posts) && site.posts && site.posts.respond_to?(:docs) && page['url']
        missing_parts = []
        missing_parts << "site object" unless site
        missing_parts << "page object" unless page
        missing_parts << "site.posts collection" unless site&.respond_to?(:posts) && site.posts && site.posts.respond_to?(:docs)
        missing_parts << "page['url']" unless page && page['url']

        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "RELATED_POSTS",
          reason: "Missing prerequisites: #{missing_parts.join(', ')}.",
          identifiers: { PageURL: page ? page['url'] : 'N/A' },
          level: :error,
        )
      end

      current_url = page['url']
      current_categories = Set.new(page['categories'] || []) # Ensure categories is an array, default to empty
      now_unix = Time.now.to_i

      # --- Prepare Post Data ---
      # Filter all posts once: published, not current page, not future-dated
      all_published_posts = site.posts.docs.select do |post|
        post.data['published'] != false &&
        post.url != current_url &&
        post.date && post.date.to_time.to_i <= now_unix
      end

      # --- Collect Candidates (Prioritized) ---
      candidate_posts = []
      found_by_category = false

      # 1. Posts sharing a category (if current page has categories)
      if !current_categories.empty?
        category_matches = all_published_posts.select do |post|
          post_categories = Set.new(post.data['categories'] || []) # Ensure post_categories is an array
          !post_categories.intersection(current_categories).empty?
        end
        # Sort category matches by date descending
        candidate_posts.concat(category_matches.sort_by { |post| post.date }.reverse)
        found_by_category = !candidate_posts.empty?
      end

      # 2. Fallback: Use site.related_posts (Jekyll's built-in) if available and categories didn't yield enough
      # Or if no categories were on the current page.
      # We only add from site.related_posts if we don't have enough yet.
      if candidate_posts.length < @max_posts && site.respond_to?(:related_posts) && site.related_posts
         related_posts_fallback = site.related_posts.select do |post|
            post.url != current_url &&
            post.data['published'] != false &&
            post.date && post.date.to_time.to_i <= now_unix
         end
         candidate_posts.concat(related_posts_fallback)
      end

      # 3. Absolute fallback: just use recent posts if still not enough
      if candidate_posts.length < @max_posts
         candidate_posts.concat(all_published_posts.sort_by { |post| post.date }.reverse)
      end


      # --- Deduplicate and Limit ---
      final_posts = candidate_posts.uniq { |post| post.url }.slice(0, @max_posts)

      # --- Render Output ---
      return "" if final_posts.empty? # Expected empty state, no log needed here

      # Determine header based on whether category matches were found
      header_text = found_by_category ? "Related Posts" : "Recent Posts"

      output = "<aside class=\"related\">\n"
      output << "  <h2>#{header_text}</h2>\n"
      output << "  <div class=\"card-grid\">\n"

      final_posts.each do |post|
        # Use the new utility function to render the article card
        output << ArticleCardUtils.render(post, context) << "\n"
      end

      output << "  </div>\n"
      output << "</aside>"

      output
    end # End render
  end # End class
end # End module

Liquid::Template.register_tag('related_posts', Jekyll::RelatedPostsTag)
