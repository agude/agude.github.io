# frozen_string_literal: true

require_relative '../article_card_renderer'

module Jekyll
  module Posts
    module Category
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

          output = +"<ul class=\"card-grid\">\n"
          @posts.each do |post|
            output << Jekyll::Posts::ArticleCardRenderer.render(post, @context) << "\n"
          end
          output << "</ul>\n"
        end
      end
    end
  end
end
