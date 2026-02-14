# frozen_string_literal: true

# _plugins/render_article_card_tag.rb
require 'jekyll'
require 'liquid'
require_relative '../article_card_utils'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../../../infrastructure/tag_argument_utils'
require_relative '../../markdown_output/markdown_card_utils'

module Jekyll
  module Posts
    # Liquid tags related to posts.
    module Tags
      # Liquid tag for rendering an article card from a post object variable.
      # Accepts a variable referencing a post object.
      #
      # Usage in Liquid templates:
      #   {% render_article_card post %}
      #   {% render_article_card my_post_variable %}
      class RenderArticleCardTag < Liquid::Tag
        # Aliases for readability
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        Logger = Jekyll::Infrastructure::PluginLoggerUtils
        CardUtils = Jekyll::Posts::ArticleCardUtils
        private_constant :TagArgs, :Logger, :CardUtils

        def initialize(tag_name, markup, tokens)
          super
          @post_object_markup = markup.strip
          validate_markup
        end

        MdCards = Jekyll::MarkdownOutput::MarkdownCardUtils
        private_constant :MdCards

        def render(context)
          post_object = TagArgs.resolve_value(@post_object_markup, context)
          return log_nil_object(context) unless post_object

          if context.registers[:render_mode] == :markdown
            MdCards.render_article_card_md({ title: post_object['title'], url: post_object['url'] })
          else
            CardUtils.render(post_object, context)
          end
        rescue StandardError => e
          log_render_error(context, e)
        end

        private

        def validate_markup
          return unless @post_object_markup.empty?

          raise Liquid::SyntaxError, "Syntax Error in 'render_article_card': A post object variable must be provided."
        end

        def log_nil_object(context)
          Logger.log_liquid_failure(
            context: context,
            tag_type: 'RENDER_ARTICLE_CARD_TAG',
            reason: "Post object variable '#{@post_object_markup}' resolved to nil.",
            identifiers: { markup: @post_object_markup },
            level: :error,
          )
        end

        def log_render_error(context, error)
          Logger.log_liquid_failure(
            context: context,
            tag_type: 'RENDER_ARTICLE_CARD_TAG',
            reason: "Error rendering article card via Jekyll::Posts::ArticleCardUtils: #{error.message}",
            identifiers: build_error_identifiers(error),
            level: :error,
          )
        end

        def build_error_identifiers(error)
          {
            post_markup: @post_object_markup,
            error_class: error.class.name,
            error_message: error.message.lines.first.chomp.slice(0, 100),
          }
        end
      end
      Liquid::Template.register_tag('render_article_card', Jekyll::Posts::Tags::RenderArticleCardTag)
    end
  end
end
