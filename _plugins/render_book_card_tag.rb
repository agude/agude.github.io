# frozen_string_literal: true

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

      parse_arguments
    end

    def render(context)
      BookCardRenderer.new(context, @book_object_markup, @display_title_markup, @subtitle_markup).render
    end

    private

    def parse_arguments
      scanner = StringScanner.new(@raw_markup)
      parse_book_object_argument(scanner)
      parse_optional_arguments(scanner)
    end

    def parse_book_object_argument(scanner)
      unless scanner.scan(/\S+/)
        raise Liquid::SyntaxError,
              "Syntax Error in 'render_book_card': " \
              'A book object variable must be provided as the first argument.'
      end
      @book_object_markup = scanner.matched
    end

    def parse_optional_arguments(scanner)
      parse_single_argument(scanner) while scanner.skip(/\s+/) && !scanner.eos?
    end

    def parse_single_argument(scanner)
      unless scanner.scan(SYNTAX)
        raise Liquid::SyntaxError,
              "Syntax Error in 'render_book_card': " \
              "Invalid arguments near '#{scanner.rest}' in '#{@raw_markup}'"
      end

      process_argument(scanner[1], scanner[2])
    end

    def process_argument(key, value_markup)
      case key
      when 'display_title'
        @display_title_markup = value_markup
      when 'subtitle'
        @subtitle_markup = value_markup
      else
        raise Liquid::SyntaxError,
              "Syntax Error in 'render_book_card': Unknown argument '#{key}' in '#{@raw_markup}'"
      end
    end

    # Helper class to handle rendering logic
    class BookCardRenderer
      def initialize(context, book_object_markup, display_title_markup, subtitle_markup)
        @context = context
        @book_object_markup = book_object_markup
        @display_title_markup = display_title_markup
        @subtitle_markup = subtitle_markup
      end

      def render
        book_object = resolve_book_object
        return handle_nil_book_object unless book_object

        display_title_override = resolve_display_title
        subtitle_text = resolve_subtitle

        BookCardUtils.render(book_object, @context,
                             display_title_override: display_title_override,
                             subtitle: subtitle_text)
      rescue StandardError => e
        handle_rendering_error(e)
      end

      private

      def resolve_book_object
        TagArgumentUtils.resolve_value(@book_object_markup, @context)
      end

      def resolve_display_title
        return nil unless @display_title_markup

        TagArgumentUtils.resolve_value(@display_title_markup, @context)
      end

      def resolve_subtitle
        return nil unless @subtitle_markup

        TagArgumentUtils.resolve_value(@subtitle_markup, @context)
      end

      def handle_nil_book_object
        PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'RENDER_BOOK_CARD_TAG',
          reason: "Book object variable '#{@book_object_markup}' resolved to nil.",
          identifiers: { markup: @book_object_markup }
        )
      end

      def handle_rendering_error(error)
        PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'RENDER_BOOK_CARD_TAG',
          reason: "Error rendering book card: #{error.message}",
          identifiers: { book_markup: @book_object_markup, error_class: error.class.name }
        )
      end
    end
  end
  Liquid::Template.register_tag('render_book_card', RenderBookCardTag)
end
