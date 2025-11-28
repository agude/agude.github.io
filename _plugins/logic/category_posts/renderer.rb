# frozen_string_literal: true

# _plugins/logic/category_posts/renderer.rb
require_relative '../../utils/article_card_utils'

module Jekyll
  module CategoryPosts
    # Renders a list of posts as HTML article cards.
    #
    # Takes an array of post documents and generates a card grid
    # with article cards for each post.
    class Renderer
      def initialize(context, posts)
        @context = context
        @posts = posts
      end

      def render
        return '' if @posts.empty?

        output = +"<div class=\"card-grid\">\n"
        @posts.each do |post|
          output << ArticleCardUtils.render(post, @context) << "\n"
        end
        output << "</div>\n"
      end
    end
  end
end
