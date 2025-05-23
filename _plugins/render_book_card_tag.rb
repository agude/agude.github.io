# _plugins/render_book_card_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'liquid_utils' # For resolve_value
require_relative 'utils/book_card_utils'
require_relative 'utils/plugin_logger_utils'

module Jekyll
  class RenderBookCardTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @book_object_markup = markup.strip
      if @book_object_markup.empty?
        raise Liquid::SyntaxError, "Syntax Error in 'render_book_card': A book object variable must be provided."
      end
    end

    def render(context)
      book_object = LiquidUtils.resolve_value(@book_object_markup, context)

      unless book_object
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "RENDER_BOOK_CARD_TAG",
          reason: "Book object variable '#{@book_object_markup}' resolved to nil.",
          identifiers: { markup: @book_object_markup }
        )
      end

      # BookCardUtils.render handles more specific validation of the book_object
      BookCardUtils.render(book_object, context)
    rescue StandardError => e
      PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "RENDER_BOOK_CARD_TAG",
        reason: "Error rendering book card: #{e.message}",
        identifiers: { book_markup: @book_object_markup, error_class: e.class.name }
      )
    end
  end
  Liquid::Template.register_tag('render_book_card', RenderBookCardTag)
end
