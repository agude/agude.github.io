# _plugins/render_article_card_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'liquid_utils' # For resolve_value
require_relative 'utils/article_card_utils'
require_relative 'utils/plugin_logger_utils'

module Jekyll
  class RenderArticleCardTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @post_object_markup = markup.strip
      if @post_object_markup.empty?
        raise Liquid::SyntaxError, "Syntax Error in 'render_article_card': A post object variable must be provided."
      end
    end

    def render(context)
      post_object = LiquidUtils.resolve_value(@post_object_markup, context)

      unless post_object
        # Log if the resolved object is nil (variable not found or was nil)
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "RENDER_ARTICLE_CARD_TAG",
          reason: "Post object variable '#{@post_object_markup}' resolved to nil.",
          identifiers: { markup: @post_object_markup }
        )
      end

      # ArticleCardUtils.render handles more specific validation of the post_object
      ArticleCardUtils.render(post_object, context)
    rescue StandardError => e
      PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "RENDER_ARTICLE_CARD_TAG",
        reason: "Error rendering article card: #{e.message}",
        identifiers: { post_markup: @post_object_markup, error_class: e.class.name }
      )
      # Return value of log_liquid_failure (HTML comment or empty string)
    end
  end
  Liquid::Template.register_tag('render_article_card', RenderArticleCardTag)
end