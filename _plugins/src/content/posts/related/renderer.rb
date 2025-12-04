# frozen_string_literal: true

require_relative '../article_card_utils'

module Jekyll
  module Posts
    module Related
      module CustomRelatedPosts
        # Renders HTML output for related or recent posts.
        #
        # Takes structured post data and generates the final HTML
        # including the appropriate header based on how posts were found.
        class Renderer
          def initialize(context, posts, found_by_category)
            @context = context
            @posts = posts
            @found_by_category = found_by_category
          end

          def render
            return '' if @posts.empty?

            header = @found_by_category ? 'Related Posts' : 'Recent Posts'
            out = "<aside class=\"related\">\n  <h2>#{header}</h2>\n  <div class=\"card-grid\">\n"
            @posts.each { |p| out << Jekyll::Posts::ArticleCardUtils.render(p, @context) << "\n" }
            out << "  </div>\n</aside>"
          end
        end
      end
    end
  end
end
