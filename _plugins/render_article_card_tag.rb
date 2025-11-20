# frozen_string_literal: true

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
      validate_markup
    end

    def render(context)
      post_object = TagArgumentUtils.resolve_value(@post_object_markup, context)
      return log_nil_object(context) unless post_object

      ArticleCardUtils.render(post_object, context)
    rescue StandardError => e
      log_render_error(context, e)
    end

    private

    def validate_markup
      return unless @post_object_markup.empty?

      raise Liquid::SyntaxError, "Syntax Error in 'render_article_card': A post object variable must be provided."
    end

    def log_nil_object(context)
      PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: 'RENDER_ARTICLE_CARD_TAG',
        reason: "Post object variable '#{@post_object_markup}' resolved to nil.",
        identifiers: { markup: @post_object_markup },
        level: :error
      )
    end

    def log_render_error(context, error)
      PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: 'RENDER_ARTICLE_CARD_TAG',
        reason: "Error rendering article card via ArticleCardUtils: #{error.message}",
        identifiers: build_error_identifiers(error),
        level: :error
      )
    end

    def build_error_identifiers(error)
      {
        post_markup: @post_object_markup,
        error_class: error.class.name,
        error_message: error.message.lines.first.chomp.slice(0, 100)
      }
    end
  end
  Liquid::Template.register_tag('render_article_card', RenderArticleCardTag)
end
