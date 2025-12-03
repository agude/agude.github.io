# frozen_string_literal: true

# _plugins/related_posts_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'

require_relative '../related/finder'
require_relative '../related/renderer'

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
      finder = Jekyll::CustomRelatedPosts::Finder.new(context, @max_posts)
      result = finder.find

      return result[:logs] if result[:posts].empty?

      renderer = Jekyll::CustomRelatedPosts::Renderer.new(context, result[:posts], result[:found_by_category])
      html_output = renderer.render

      result[:logs] + html_output
    end
  end
end

Liquid::Template.register_tag('related_posts', Jekyll::RelatedPostsTag)
