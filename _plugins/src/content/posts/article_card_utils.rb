# frozen_string_literal: true

# _plugins/utils/article_card_utils.rb
require_relative 'article_card_renderer'

# Utility module for rendering article/post cards in HTML.
#
# Provides methods to generate card HTML for blog posts with title,
# description, image, and metadata.
module ArticleCardUtils
  def self.render(post_object, context)
    ArticleCardRenderer.new(post_object, context).render
  end
end
