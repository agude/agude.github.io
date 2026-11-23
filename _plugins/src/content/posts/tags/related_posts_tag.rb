# frozen_string_literal: true

require 'jekyll'
require 'liquid'

require_relative '../related/finder'
require_relative '../article_card_renderer'
require_relative '../../card_grid'

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
        def render(context)
          site = context.registers[:site]
          page = context.registers[:page]
          finder = Jekyll::Posts::Related::Finder.new(site, page)
          result = finder.find

          heading = result[:found_by_category] ? 'Related Posts' : 'Recent Posts'
          result[:logs] + Jekyll::Content::CardGrid.render(result[:posts], heading: "<h2>#{heading}</h2>") do |post|
            "#{Jekyll::Posts::ArticleCardRenderer.render(post, context)}\n"
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('related_posts', Jekyll::Posts::Tags::RelatedPostsTag)
