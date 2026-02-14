# frozen_string_literal: true

# _plugins/related_posts_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'

require_relative '../related/finder'
require_relative '../related/renderer'

# Displays related or recent blog posts based on category matching.
#
# Shows posts that share categories with the current page, falling back
# to recent posts if no category matches are found.
#
# Usage in Liquid templates:
module Jekyll
  #   {% related_posts %}
  module Posts
    module Tags
      # Liquid tag for displaying related or recent blog posts.
      # Shows posts that share categories, falling back to recent posts.
      class RelatedPostsTag < Liquid::Tag
        DEFAULT_MAX_POSTS = 3

        def initialize(tag_name, markup, tokens)
          super
          @max_posts = DEFAULT_MAX_POSTS
        end

        def render(context)
          site = context.registers[:site]
          page = context.registers[:page]
          finder = Jekyll::Posts::Related::Finder.new(site, page, @max_posts)
          result = finder.find

          return result[:logs] if result[:posts].empty?

          renderer = Jekyll::Posts::Related::Renderer.new(
            context,
            result[:posts],
            result[:found_by_category],
          )
          html_output = renderer.render

          result[:logs] + html_output
        end
      end
    end
  end
end

Liquid::Template.register_tag('related_posts', Jekyll::Posts::Tags::RelatedPostsTag)
