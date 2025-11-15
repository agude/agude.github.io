# _plugins/render_book_card_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative 'utils/book_card_utils'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/tag_argument_utils'

module Jekyll
  class RenderBookCardTag < Liquid::Tag
    SYNTAX = /([\w-]+)\s*=\s*(#{Liquid::QuotedFragment}|\S+)/o

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup.strip
      @book_object_markup = nil
      @display_title_markup = nil
      @subtitle_markup = nil

      scanner = StringScanner.new(@raw_markup)

      # First argument must be the book object variable
      unless scanner.scan(/\S+/)
        raise Liquid::SyntaxError,
              "Syntax Error in 'render_book_card': A book object variable must be provided as the first argument."
      end

      @book_object_markup = scanner.matched

      # Scan for optional named arguments
      while scanner.skip(/\s+/) && !scanner.eos?
        if scanner.scan(SYNTAX)
          key = scanner[1]
          value_markup = scanner[2]
          case key
          when 'display_title'
            @display_title_markup = value_markup
          when 'subtitle'
            @subtitle_markup = value_markup
          else
            raise Liquid::SyntaxError,
                  "Syntax Error in 'render_book_card': Unknown argument '#{key}' in '#{@raw_markup}'"
          end
        else
          raise Liquid::SyntaxError,
                "Syntax Error in 'render_book_card': Invalid arguments near '#{scanner.rest}' in '#{@raw_markup}'"
        end
      end
    end

    def render(context)
      book_object = TagArgumentUtils.resolve_value(@book_object_markup, context)
      display_title_override = if @display_title_markup
                                 TagArgumentUtils.resolve_value(@display_title_markup,
                                                                context)
                               end
      subtitle_text = @subtitle_markup ? TagArgumentUtils.resolve_value(@subtitle_markup, context) : nil

      unless book_object
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'RENDER_BOOK_CARD_TAG',
          reason: "Book object variable '#{@book_object_markup}' resolved to nil.",
          identifiers: { markup: @book_object_markup }
        )
      end

      # BookCardUtils.render handles more specific validation of the book_object
      BookCardUtils.render(book_object, context, display_title_override: display_title_override,
                                                 subtitle: subtitle_text)
    rescue StandardError => e
      PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: 'RENDER_BOOK_CARD_TAG',
        reason: "Error rendering book card: #{e.message}",
        identifiers: { book_markup: @book_object_markup, error_class: e.class.name }
      )
    end
  end
  Liquid::Template.register_tag('render_book_card', RenderBookCardTag)
end
