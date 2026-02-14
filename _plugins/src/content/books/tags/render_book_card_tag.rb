# frozen_string_literal: true

# _plugins/render_book_card_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative '../core/book_card_utils'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../../../infrastructure/tag_argument_utils'

# Jekyll namespace for custom plugins.
# Renders a book card from a book object variable.
#
# Supports optional display title and subtitle overrides.
#
# Usage in Liquid templates:
#   {% render_book_card book %}
#   {% render_book_card book display_title="Custom Title" %}
module Jekyll
  #   {% render_book_card book subtitle="Subtitle Text" %}
  module Books
    module Tags
      # Liquid tag for rendering a book card from a book object variable.
      # Supports optional display title and subtitle overrides.
      class RenderBookCardTag < Liquid::Tag
        # Aliases for readability
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        Logger = Jekyll::Infrastructure::PluginLoggerUtils
        CardUtils = Jekyll::Books::Core::BookCardUtils
        private_constant :TagArgs, :Logger, :CardUtils

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
          book_object = TagArgs.resolve_value(@book_object_markup, context)
          return log_nil_book_object(context) unless book_object

          display_title = resolve_optional(@display_title_markup, context)
          subtitle = resolve_optional(@subtitle_markup, context)

          render_card(book_object, context, display_title, subtitle)
        end

        private

        def log_nil_book_object(context)
          Logger.log_liquid_failure(
            context: context,
            tag_type: 'RENDER_BOOK_CARD_TAG',
            reason: "Book object variable '#{@book_object_markup}' resolved to nil.",
            identifiers: { markup: @book_object_markup },
          )
        end

        def resolve_optional(markup, context)
          return nil unless markup

          TagArgs.resolve_value(markup, context)
        end

        def render_card(book_object, context, display_title, subtitle)
          CardUtils.render(
            book_object, context, display_title_override: display_title, subtitle: subtitle,
          )
        rescue StandardError => e
          Logger.log_liquid_failure(
            context: context,
            tag_type: 'RENDER_BOOK_CARD_TAG',
            reason: "Error rendering book card: #{e.message}",
            identifiers: { book_markup: @book_object_markup, error_class: e.class.name },
          )
        end

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
      end
    end
  end
end

Liquid::Template.register_tag('render_book_card', Jekyll::Books::Tags::RenderBookCardTag)
