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
      # No arguments to parse for this tag currently.
      # @max_posts could be made configurable via markup if needed in the future.
      @max_posts = DEFAULT_MAX_POSTS
    end

    def render(context)
      site = context.registers[:site]
      page = context.registers[:page]
      now_unix = Time.now.to_i

      # --- Prerequisite Validation ---
      # Ensure essential objects (site, page, site.posts.docs, page.url) are available and valid.
      prereq_missing = false
      missing_parts = []

      unless site
        prereq_missing = true
        missing_parts << 'site object'
      end
      unless page
        prereq_missing = true
        missing_parts << 'page object'
      end

      if site && page
        # Check if site.posts.docs is a valid, iterable array
        site_posts_valid = site.respond_to?(:posts) &&                            site.posts&.respond_to?(:docs) && site.posts.docs.is_a?(Array)
        unless site_posts_valid
          prereq_missing = true
          detail = if site.respond_to?(:posts) && site.posts&.respond_to?(:docs)
                     "site.posts.docs is #{site.posts.docs.class.name}, not Array"
                   elsif site.respond_to?(:posts) && site.posts
                     'site.posts does not have .docs'
                   else
                     'site.posts object itself is problematic or nil'
                   end
          missing_parts << "site.posts.docs (#{detail})"
        end

        # Check if page['url'] is present and not empty
        page_url_valid = page['url'] && !page['url'].to_s.strip.empty?
        unless page_url_valid
          prereq_missing = true
          missing_parts << "page['url'] (present and not empty)"
        end
      else
        # If site or page is missing, page['url'] cannot be reliably checked or used.
        # This specific message is added if the more specific check for page['url'] within 'if site && page' was not performed.
        unless page && page['url'] && !page['url'].to_s.strip.empty?
          missing_parts << "page['url'] (cannot check, site or page missing)"
        end
      end

      if prereq_missing
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'RELATED_POSTS',
          reason: "Missing prerequisites: #{missing_parts.join(', ')}.",
          identifiers: { PageURL: page ? (page['url'] || 'N/A') : 'N/A' }, # Safely access page['url']
          level: :error
        )
      end

      current_url = page['url']
      current_categories = Set.new(page['categories'] || [])

      # --- Prepare Filtered and Sorted List of All Potential Posts ---
      # Selects posts that are published, not the current page, and not future-dated.
      # Sorted by date descending (most recent first).
      all_site_posts_docs = site.posts.docs
      all_site_posts_filtered_and_sorted = all_site_posts_docs.select do |p|
        # Basic check for valid post structure
        next false unless p.respond_to?(:data) && p.respond_to?(:url) && p.respond_to?(:date)

        is_published = p.data['published'] != false
        is_not_current = p.url != current_url
        # Ensure post.date is valid and in the past or present
        is_not_future = p.date ? (p.date.to_time.to_i <= now_unix) : false

        is_published && is_not_current && is_not_future
      end.sort_by(&:date).reverse

      # --- Collect Candidate Posts ---
      # Priority:
      # 1. Posts sharing categories with the current page.
      # 2. Posts listed in site.config['related_posts'] (manual override).
      # 3. Most recent posts from the filtered list.
      candidate_posts = []
      found_by_category = false

      # 1. Posts sharing a category (if current page has categories)
      unless current_categories.empty?
        category_matches = all_site_posts_filtered_and_sorted.select do |p|
          post_categories = Set.new(p.data['categories'] || [])
          post_categories.intersect?(current_categories)
        end
        candidate_posts.concat(category_matches)
        found_by_category = !candidate_posts.empty?
      end

      # 2. Fallback: Use posts from site.config['related_posts'] if available and not enough posts yet.
      # These are manually specified related posts. They are also filtered for validity.
      if candidate_posts.length < @max_posts && site.config['related_posts'].is_a?(Array)
        related_posts_from_config = site.config['related_posts'].select do |p_obj|
          next false unless p_obj.respond_to?(:url) && p_obj.respond_to?(:data) && p_obj.respond_to?(:date)

          is_pub = p_obj.data['published'] != false
          is_not_curr = p_obj.url != current_url
          is_not_fut = p_obj.date ? (p_obj.date.to_time.to_i <= now_unix) : false
          is_pub && is_not_curr && is_not_fut
        end.sort_by(&:date).reverse # Sort them by date as well
        candidate_posts.concat(related_posts_from_config)
      end

      # 3. Absolute fallback: Use most recent posts if still not enough.
      candidate_posts.concat(all_site_posts_filtered_and_sorted) if candidate_posts.length < @max_posts

      # --- Deduplicate and Limit ---
      # Ensure uniqueness by URL and limit to @max_posts.
      # .uniq preserves the order of first appearance, respecting the prioritization above.
      final_posts = candidate_posts.uniq(&:url).slice(0, @max_posts)

      # --- Render Output ---
      return '' if final_posts.empty? # Expected empty state, no log needed here.

      header_text = found_by_category ? 'Related Posts' : 'Recent Posts'
      output = "<aside class=\"related\">\n"
      output << "  <h2>#{header_text}</h2>\n"
      output << "  <div class=\"card-grid\">\n"
      final_posts.each do |post|
        # Delegate rendering of individual post cards to ArticleCardUtils
        output << ArticleCardUtils.render(post, context) << "\n"
      end
      output << "  </div>\n"
      output << '</aside>'
      output
    end
  end
end
Liquid::Template.register_tag('related_posts', Jekyll::RelatedPostsTag)
