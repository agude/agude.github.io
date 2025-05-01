# _plugins/related_posts_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'liquid_utils'

module Jekyll
  class RelatedPostsTag < Liquid::Tag
    DEFAULT_MAX_POSTS = 3

    def initialize(tag_name, markup, tokens)
      super
      @max_posts = DEFAULT_MAX_POSTS
    end

    def render(context)
      site = context.registers[:site]
      page = context.registers[:page]

      # --- Basic Sanity Checks ---
      unless site && page && site.posts && page['url']
        return LiquidUtils.log_failure(
          context: context, tag_type: "RELATED_POSTS",
          reason: "Missing context, site.posts, or page URL",
          identifiers: { PageURL: page ? page['url'] : 'N/A' }
        )
      end

      current_url = page['url']
      current_categories = Set.new(page['categories']) # Use Set for efficient lookup
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
          post_categories = Set.new(post.data['categories'])
          !post_categories.intersection(current_categories).empty? # Check for overlap
        end
        # Sort category matches by date descending
        candidate_posts.concat(category_matches.sort_by { |post| post.date }.reverse)
        found_by_category = !candidate_posts.empty?
      end

      # 2. Fallback: Use site.related_posts (Jekyll's built-in, often recent or LSI)
      # Ensure these are also published and not future-dated (Jekyll might handle this, but double-check)
      if site.respond_to?(:related_posts) && site.related_posts
         related_posts_fallback = site.related_posts.select do |post|
            # Ensure it's not the current page (Jekyll usually does this)
            # and meets our publishing criteria
            post.url != current_url &&
            post.data['published'] != false &&
            post.date && post.date.to_time.to_i <= now_unix
         end
         candidate_posts.concat(related_posts_fallback)
      else
         # Absolute fallback: just use recent posts if site.related_posts isn't available/useful
         candidate_posts.concat(all_published_posts.sort_by { |post| post.date }.reverse)
      end


      # --- Deduplicate and Limit ---
      final_posts = candidate_posts.uniq { |post| post.url }.slice(0, @max_posts)

      # --- Render Output ---
      return "" if final_posts.empty?

      # Determine header based on whether category matches were found
      header_text = found_by_category ? "Related Posts" : "Recent Posts"

      output = "<aside class=\"related\">\n"
      output << "  <h2>#{header_text}</h2>\n"
      output << "  <div class=\"card-grid\">\n"

      final_posts.each do |post|
        # Use the new utility function to render the article card
        output << LiquidUtils.render_article_card(post, context) << "\n"
      end

      output << "  </div>\n"
      output << "</aside>"

      output
    end # End render
  end # End class
end # End module

Liquid::Template.register_tag('related_posts', Jekyll::RelatedPostsTag)
