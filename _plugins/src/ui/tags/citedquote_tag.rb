# frozen_string_literal: true

require 'jekyll'
require 'liquid'
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
      # Accepts the named parameters in CitationUtils::PARAMETER_NAMES, and
      # at least one is required. An unknown or repeated key raises
      # Liquid::SyntaxError at parse time.
      # Content between tags is required (cannot be empty or whitespace-only).
      class CitedQuoteTag < Liquid::Block
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        QuoteUtils = Jekyll::UI::Quotes::CitedQuoteUtils
        CitationUtil = Jekyll::UI::Citations::CitationUtils
        private_constant :TagArgs, :QuoteUtils, :CitationUtil

        def initialize(tag_name, markup, tokens)
          super
          @attributes_markup = TagArgs.parse_named_arguments(
            markup.strip, tag_name: 'citedquote', allowed: CitationUtil::PARAMETER_NAMES,
          ).transform_keys(&:to_sym)
          validate_has_citation_params
        end

        def render(context)
          raw_content = super.to_s
          validate_content_present(raw_content)

          # Strip common leading whitespace so content can be indented
          # to match surrounding context (e.g. inside footnotes)
          indent, content = dedent(raw_content)

          site = context.registers[:site]
          resolved_params = resolve_params(context)

          if context.registers[:render_mode] == :markdown
            render_markdown_quote(content, resolved_params, site, indent)
          else
            QuoteUtils.render(content, resolved_params, site)
          end
        end

        private

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

        def render_markdown_quote(content, params, site, indent)
          quoted_lines = content.strip.lines.map { |line| "> #{line.rstrip}" }
          citation_text = CitationUtil.format_citation_text(params, site)
          quoted_lines << '>'
          quoted_lines << "> --- #{citation_text}"

          # Re-indent lines 2+ so the output stays inside an indented
          # context (e.g. a Markdown footnote).  Line 1 inherits its
          # indent from the Liquid template literal preceding the tag.
          if indent.positive?
            prefix = ' ' * indent
            quoted_lines = quoted_lines.each_with_index.map do |line, i|
              i.zero? ? line : "#{prefix}#{line}"
            end
          end

          quoted_lines.join("\n")
        end

        # Detect and strip common leading whitespace from block content.
        # Returns [indent_size, dedented_content].
        #
        # When the content does not start with a newline, line 1 sits on the
        # tag line and inherits its indent from the template, so it is
        # excluded from both the minimum and the stripping. The minimum
        # covers every other non-blank line, including unindented ones.
        def dedent(content)
          lines = content.lines
          tag_line = content.start_with?("\n") ? [] : lines.shift(1)
          indents = lines.grep(/\S/).map { |line| line[/\A[ \t]*/].length }
          min_indent = indents.min || 0
          return [0, content] if min_indent.zero?

          strip = /\A[ \t]{0,#{min_indent}}/
          stripped = lines.map { |line| line =~ /\S/ ? line.sub(strip, '') : line }
          [min_indent, (tag_line + stripped).join]
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

Liquid::Template.register_tag('citedquote', Jekyll::UI::Tags::CitedQuoteTag)
