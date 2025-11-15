# _plugins/render_article_card_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'utils/article_card_utils'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/tag_argument_utils'

module Jekyll
  class RenderArticleCardTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @post_object_markup = markup.strip
      return unless @post_object_markup.empty?

      raise Liquid::SyntaxError, "Syntax Error in 'render_article_card': A post object variable must be provided."
    end

    def render(context)
      post_object = TagArgumentUtils.resolve_value(@post_object_markup, context)

      unless post_object
        # Log if the resolved object is nil (variable not found or was nil)
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'RENDER_ARTICLE_CARD_TAG',
          reason: "Post object variable '#{@post_object_markup}' resolved to nil.",
          identifiers: { markup: @post_object_markup },
          level: :error
        )
      end

      # ArticleCardUtils.render handles more specific validation of the post_object
      ArticleCardUtils.render(post_object, context)
    rescue StandardError => e
      # Catching StandardError is broad; consider if more specific errors from ArticleCardUtils are expected.
      # For now, any error from the utility is treated as an error for the tag.
      PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: 'RENDER_ARTICLE_CARD_TAG',
        reason: "Error rendering article card via ArticleCardUtils: #{e.message}",
        identifiers: { post_markup: @post_object_markup, error_class: e.class.name,
                       error_message: e.message.lines.first.chomp.slice(0, 100) },
        level: :error
      )
      # Return value of log_liquid_failure (HTML comment or empty string)
    end
  end
  Liquid::Template.register_tag('render_article_card', RenderArticleCardTag)
end
