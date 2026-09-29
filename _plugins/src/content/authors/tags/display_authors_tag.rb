# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require 'strscan'

require_relative '../display_authors_util'
require_relative '../../../infrastructure/tag_argument_utils'
require_relative '../../../infrastructure/plugin_logger_utils'

module Jekyll
  module Authors
    module Tags
      # Liquid tag for displaying a list of author names as a sentence.
      # Supports optional linking and "et al." truncation.
      # Usage in Liquid templates:
      #   {% display_authors page.book_authors %}
      #   {% display_authors page.book_authors linked=true %}
      #   {% display_authors page.book_authors etal_after=3 %}
      class DisplayAuthorsTag < Liquid::Tag
        ALLOWED_NAMED_KEYS = %w[linked etal_after].freeze
        # Aliases for readability
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        DisplayUtil = Jekyll::Authors::DisplayAuthorsUtil
        private_constant :TagArgs, :DisplayUtil

        def initialize(tag_name, markup, tokens)
          super
          @tag_name = tag_name
          @raw_markup = markup.strip
          @authors_list_markup = nil
          @options_markup = {}

          parse_markup
        end

        def render(context)
          authors_input = TagArgs.resolve_value(@authors_list_markup, context)
          linked_option = linked?(context)
          etal_option = resolve_etal_after_option(context)

          DisplayUtil.render_author_list(
            author_input: authors_input,
            context: context,
            linked: linked_option,
            etal_after: etal_option,
          )
        end

        private

        def parse_markup
          scanner = StringScanner.new(@raw_markup)
          scanner.skip(/\s*/)

          parse_authors_list(scanner)
          @options_markup = TagArgs.parse_named_arguments(
            scanner, tag_name: @tag_name, allowed: ALLOWED_NAMED_KEYS, downcase_keys: true,
          ).transform_keys(&:to_sym)
          validate_required_arguments
        end

        def parse_authors_list(scanner)
          # Peek at the first potential token to see if it's a named argument key
          is_key = scanner.match?(/(#{ALLOWED_NAMED_KEYS.join('|')})\s*=\s*/)

          return if is_key
          return unless scanner.scan(/(#{Liquid::QuotedFragment}|\S+)/)

          @authors_list_markup = scanner[1].strip
          scanner.skip(/\s*/)
        end

        def validate_required_arguments
          return unless @authors_list_markup.nil? || @authors_list_markup.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in '#{@tag_name}': Missing required authors list (e.g., page.book_authors) " \
                "as the first argument in '#{@raw_markup}'"
        end

        def linked?(context)
          TagArgs.resolve_boolean(@options_markup[:linked], context)
        end

        def resolve_etal_after_option(context)
          return nil unless @options_markup.key?(:etal_after)

          val = TagArgs.resolve_value(@options_markup[:etal_after], context)
          return nil unless val

          Integer(val.to_s)
        rescue ArgumentError
          nil
        end
      end
    end
  end
end

Liquid::Template.register_tag('display_authors', Jekyll::Authors::Tags::DisplayAuthorsTag)
