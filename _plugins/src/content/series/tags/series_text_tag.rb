# frozen_string_literal: true

# _plugins/series_text_tag.rb
require 'jekyll'
require 'liquid'
# CGI and strscan are still used by the tag's initialize
require 'cgi'
require 'strscan'
require_relative '../series_link_util'
require_relative '../../../infrastructure/tag_argument_utils'
require_relative '../series_text_utils' # Require the new utility

# Renders series text with appropriate context and linking.
#
# Analyzes series names to extract and render them with proper formatting
# and linking to series pages.
#
# Usage in Liquid templates:
#   {% series_text "The Lord of the Rings" %}
module Jekyll
  #   {% series_text page.series %}
  module Series
    module Tags
      # Liquid tag for rendering series text with appropriate context and linking.
      # Analyzes series names and renders them with proper formatting and links.
      class SeriesTextTag < Liquid::Tag
        # Aliases for readability
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        Linker = Jekyll::Series::SeriesLinkUtils
        TextUtil = Jekyll::Series::SeriesTextUtils
        private_constant :TagArgs, :Linker, :TextUtil

        QuotedFragment = Liquid::QuotedFragment

        # SERIES_TYPE_WORDS is now in Jekyll::Series::SeriesTextUtils

        def initialize(tag_name, markup, tokens)
          super
          @raw_markup = markup
          @series_name_markup = nil

          parse_arguments(markup)
        end

        def render(context)
          raw_series_name_input = TagArgs.resolve_value(@series_name_markup, context)

          analysis = TextUtil.analyze_series_name(raw_series_name_input)
          return '' if analysis.nil?

          linked_series_html = Linker.render_series_link(analysis[:name], context)
          return '' if should_return_empty?(linked_series_html, analysis)

          build_output(analysis, linked_series_html)
        end

        private

        def parse_arguments(markup)
          scanner = StringScanner.new(markup.strip)
          parse_series_name(scanner)
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

        def validate_no_extra_arguments(scanner)
          scanner.skip(/\s+/)
          return if scanner.eos?

          raise Liquid::SyntaxError,
                "Syntax Error in 'series_text': " \
                "Unexpected arguments '#{scanner.rest}' in '#{@raw_markup}'"
        end

        def validate_series_name
          return if @series_name_markup && !@series_name_markup.strip.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in 'series_text': " \
                "Series name value is missing or empty in '#{@raw_markup}'"
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
