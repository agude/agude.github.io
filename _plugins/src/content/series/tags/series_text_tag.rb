# frozen_string_literal: true

# _plugins/series_text_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative '../series_link_resolver'
require_relative '../../../infrastructure/tag_argument_utils'
require_relative '../series_text_utils'
require_relative '../../markdown_output/markdown_link_formatter'
require_relative '../../../infrastructure/links/link_helper_utils'

# Renders series text with appropriate context and linking.
#
# Analyzes series names to extract and render them with proper formatting
# and linking to series pages.
#
# Usage in Liquid templates:
#   {% series_text "The Lord of the Rings" %}
module Jekyll
  #   {% series_text page.series %}
  #   {% series_text page.series link=false %}
  module Series
    module Tags
      # Liquid tag for rendering series text with appropriate context and linking.
      # Analyzes series names and renders them with proper formatting and links.
      # Supports link=false to emit a styled span without an <a> wrapper.
      class SeriesTextTag < Liquid::Tag
        # Aliases for readability
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        Resolver = Jekyll::Series::SeriesLinkResolver
        TextUtil = Jekyll::Series::SeriesTextUtils
        MdLink = Jekyll::MarkdownOutput::MarkdownLinkFormatter
        LinkHelper = Jekyll::Infrastructure::Links::LinkHelperUtils
        private_constant :TagArgs, :Resolver, :TextUtil, :MdLink, :LinkHelper

        QuotedFragment = Liquid::QuotedFragment

        # SERIES_TYPE_WORDS is now in Jekyll::Series::SeriesTextUtils

        def initialize(tag_name, markup, tokens)
          super
          @raw_markup = markup
          @series_name_markup = nil
          @link_markup = nil

          parse_arguments(markup)
        end

        def render(context)
          raw_series_name_input = TagArgs.resolve_value(@series_name_markup, context)

          analysis = TextUtil.analyze_series_name(raw_series_name_input)
          return '' if analysis.nil?

          link = link_enabled?(context)
          resolver = Resolver.new(context)

          return render_markdown(analysis, resolver, context, link) if context.registers[:render_mode] == :markdown

          linked_series_html = resolver.resolve(analysis[:name], nil, link: link)
          return '' if should_return_empty?(linked_series_html, analysis)

          build_output(analysis, linked_series_html)
        end

        private

        def parse_arguments(markup)
          scanner = StringScanner.new(markup.strip)
          parse_series_name(scanner)
          parse_options(scanner)
          validate_no_extra_arguments(scanner)
          validate_series_name
        end

        def parse_series_name(scanner)
          if scanner.scan(QuotedFragment) || scanner.scan(/\S+/)
            @series_name_markup = scanner.matched
          else
            raise Liquid::SyntaxError,
                  "Syntax Error in 'series_text': " \
                  "Could not find series name in '#{@raw_markup}'"
          end
        end

        def parse_options(scanner)
          scanner.skip(/\s+/)
          return if scanner.eos?

          return unless scanner.scan(/link\s*=\s*(#{QuotedFragment})/)

          @link_markup = scanner[1]
        end

        # Returns true unless link= is explicitly set to 'false'.
        def link_enabled?(context)
          return true unless @link_markup

          value = TagArgs.resolve_value(@link_markup, context)
          value.to_s.downcase != 'false'
        end

        def validate_no_extra_arguments(scanner)
          scanner.skip(/\s+/)
          return if scanner.eos?

          raise Liquid::SyntaxError,
                "Syntax Error in 'series_text': " \
                "Unexpected arguments '#{scanner.rest}' in '#{@raw_markup}'"
        end

        def validate_series_name
          raise_empty_name if @series_name_markup.nil? || @series_name_markup.strip.empty?

          m = @series_name_markup.match(/\A(['"])(.*)\1\z/m)
          return unless m

          raise_empty_name if m[2].strip.empty?
        end

        def raise_empty_name
          raise Liquid::SyntaxError,
                "Syntax Error in 'series_text': " \
                "Series name value is missing or empty in '#{@raw_markup}'"
        end

        def render_markdown(analysis, resolver, context, link)
          data = resolver.resolve_data(analysis[:name], nil, link: link)
          self_link = LinkHelper.self_link?(context, data[:url])
          text = MdLink.format_link(data, italic: true, self_link: self_link)
          "#{analysis[:prefix]}#{text}#{analysis[:suffix]}".strip
        end

        def should_return_empty?(linked_series_html, analysis)
          linked_series_html.strip.empty? &&
            analysis[:prefix].empty? &&
            analysis[:suffix].empty?
        end

        def build_output(analysis, linked_series_html)
          output = "#{analysis[:prefix]}#{linked_series_html}#{analysis[:suffix]}"
          output.strip
        end
      end
    end
  end
end

Liquid::Template.register_tag('series_text', Jekyll::Series::Tags::SeriesTextTag)
