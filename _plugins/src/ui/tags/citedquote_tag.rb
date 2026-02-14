# frozen_string_literal: true

# _plugins/src/ui/tags/citedquote_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative '../quotes/citedquote_utils'
require_relative '../citations/citation_utils'
require_relative '../../infrastructure/tag_argument_utils'

module Jekyll
  module UI
    module Tags
      # Liquid block tag for rendering attributed quotes with semantic HTML.
      #
      # Syntax:
      # {% citedquote author_last="Doe" author_first="John" work_title="Article" url="..." %}
      # Quote content here (processed as Markdown)
      # {% endcitedquote %}
      #
      # All citation parameters from the citation tag are supported.
      # At least one citation parameter is required.
      # Content between tags is required (cannot be empty or whitespace-only).
      class CitedQuoteTag < Liquid::Block
        # Aliases for readability
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        QuoteUtils = Jekyll::UI::Quotes::CitedQuoteUtils
        CitationUtil = Jekyll::UI::Citations::CitationUtils
        private_constant :TagArgs, :QuoteUtils, :CitationUtil

        # Regex for parsing "key='value'" or "key=variable" arguments.
        ARG_SYNTAX = /([\w-]+)\s*=\s*((['"])(?:(?!\3).)*\3|\S+)/o

        def initialize(tag_name, markup, tokens)
          super
          @raw_markup = markup.strip
          @attributes_markup = {}
          parse_markup(@raw_markup)
          validate_has_citation_params
        end

        def render(context)
          # Get block content by calling super
          content = super.to_s

          # Validate content is not empty
          validate_content_present(content)

          # Get the site object from the Liquid context registers
          site = context.registers[:site]

          # Resolve all attribute values
          resolved_params = resolve_params(context)

          if context.registers[:render_mode] == :markdown
            render_markdown_quote(content, resolved_params, site)
          else
            QuoteUtils.render(content, resolved_params, site)
          end
        end

        private

        def parse_markup(markup)
          scanner = StringScanner.new(markup)

          while scanner.scan(ARG_SYNTAX)
            key = scanner[1]
            value_markup = scanner[2]
            @attributes_markup[key.to_sym] = value_markup
            scanner.skip(/\s*/)
          end

          return if scanner.eos?

          raise Liquid::SyntaxError,
                "Syntax Error in 'citedquote' tag: Invalid arguments near '#{scanner.rest}' in '#{markup}'"
        end

        def validate_has_citation_params
          return unless @attributes_markup.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in 'citedquote' tag: At least one citation parameter is required. " \
                'Use markdown > for unattributed quotes.'
        end

        def validate_content_present(content)
          return unless content.strip.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in 'citedquote' tag: Content is required between " \
                '{% citedquote %} and {% endcitedquote %}.'
        end

        def render_markdown_quote(content, params, site)
          quoted_lines = content.strip.lines.map { |line| "> #{line.rstrip}" }
          citation_text = CitationUtil.format_citation_text(params, site)
          quoted_lines << '>'
          quoted_lines << "> --- #{citation_text}"
          quoted_lines.join("\n")
        end

        def resolve_params(context)
          resolved = {}
          @attributes_markup.each do |key, value_markup|
            resolved[key] = TagArgs.resolve_value(value_markup, context)
          end
          resolved
        end
      end
    end
  end
end

# Register the tag with Liquid
Liquid::Template.register_tag('citedquote', Jekyll::UI::Tags::CitedQuoteTag)
