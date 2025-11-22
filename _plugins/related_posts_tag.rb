# frozen_string_literal: true

# _plugins/related_posts_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/article_card_utils'

module Jekyll
  # Displays related or recent blog posts based on category matching.
  #
  # Shows posts that share categories with the current page, falling back
  # to recent posts if no category matches are found.
  #
  # Usage in Liquid templates:
  #   {% related_posts %}
  class RelatedPostsTag < Liquid::Tag
    DEFAULT_MAX_POSTS = 3

    def initialize(tag_name, markup, tokens)
      super
      @max_posts = DEFAULT_MAX_POSTS
    end

    def render(context)
      RelatedPostsRenderer.new(context, @max_posts).render
    end
  end

  # Helper class to handle related posts logic
  class RelatedPostsRenderer
    def initialize(context, max_posts)
      @context = context
      @max_posts = max_posts
      @site = context.registers[:site]
      @page = context.registers[:page]
      @now_unix = Time.now.to_i
    end

    def render
      return log_missing_prerequisites unless prerequisites_met?

      final_posts = gather_posts
      return '' if final_posts.empty?

      render_html(final_posts)
    end

    private

    def prerequisites_met?
      @site && @page && site_posts_valid? && page_url_valid?
    end

    def site_posts_valid?
      @site.respond_to?(:posts) && @site.posts.respond_to?(:docs) && @site.posts.docs.is_a?(Array)
    end

    def page_url_valid?
      @page['url'] && !@page['url'].to_s.strip.empty?
    end

    def log_missing_prerequisites
      missing = collect_missing_items
      PluginLoggerUtils.log_liquid_failure(
        context: @context,
        tag_type: 'RELATED_POSTS',
        reason: "Missing prerequisites: #{missing.join(', ')}.",
        identifiers: { PageURL: @page ? (@page['url'] || 'N/A') : 'N/A' },
        level: :error
      )
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
      @current_url = @page['url']
      @all_posts = filter_and_sort_posts(@site.posts.docs)
      @found_by_category = false

      candidates = []
      candidates.concat(find_by_category)
      candidates.concat(find_from_config) if candidates.length < @max_posts
      candidates.concat(@all_posts) if candidates.length < @max_posts

      candidates.uniq(&:url).slice(0, @max_posts)
    end

    def filter_and_sort_posts(posts)
      posts.select { |p| valid_post?(p) }
           .sort_by(&:date)
           .reverse
    end

    def valid_post?(post)
      return false unless post.respond_to?(:data) && post.respond_to?(:url) && post.respond_to?(:date)
      return false if post.data['published'] == false
      return false if post.url == @current_url
      return false unless post.date

      post.date.to_time.to_i <= @now_unix
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

    def render_html(posts)
      header = @found_by_category ? 'Related Posts' : 'Recent Posts'
      out = "<aside class=\"related\">\n  <h2>#{header}</h2>\n  <div class=\"card-grid\">\n"
      posts.each { |p| out << ArticleCardUtils.render(p, @context) << "\n" }
      out << "  </div>\n</aside>"
    end
  end
end

Liquid::Template.register_tag('related_posts', Jekyll::RelatedPostsTag)
