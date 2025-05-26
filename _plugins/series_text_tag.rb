# _plugins/series_text_tag.rb
require 'jekyll'
require 'liquid'
# CGI and strscan are still used by the tag's initialize
require 'cgi'
require 'strscan'
require_relative 'utils/series_link_util'
require_relative 'utils/tag_argument_utils'
require_relative 'utils/series_text_utils' # Require the new utility

module Jekyll
  class SeriesTextTag < Liquid::Tag
    QuotedFragment = Liquid::QuotedFragment

    # SERIES_TYPE_WORDS is now in SeriesTextUtils

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup
      @series_name_markup = nil
      scanner = StringScanner.new(markup.strip)

      if scanner.scan(QuotedFragment)
        @series_name_markup = scanner.matched
      elsif scanner.scan(/\S+/)
        @series_name_markup = scanner.matched
      else
        raise Liquid::SyntaxError, "Syntax Error in 'series_text': Could not find series name in '#{@raw_markup}'"
      end

      scanner.skip(/\s+/)
      unless scanner.eos?
        raise Liquid::SyntaxError, "Syntax Error in 'series_text': Unexpected arguments '#{scanner.rest}' in '#{@raw_markup}'"
      end
      unless @series_name_markup && !@series_name_markup.strip.empty?
        raise Liquid::SyntaxError, "Syntax Error in 'series_text': Series name value is missing or empty in '#{@raw_markup}'"
      end
    end

    def render(context)
      raw_series_name_input = TagArgumentUtils.resolve_value(@series_name_markup, context)

      analysis = SeriesTextUtils.analyze_series_name(raw_series_name_input)
      return "" if analysis.nil? # Handles nil/empty input via the utility

      # Generate Linked Series Name using the original stripped name from analysis
      linked_series_html = SeriesLinkUtils.render_series_link(analysis[:name], context)
      return "" if linked_series_html.strip.empty? && analysis[:prefix].empty? && analysis[:suffix].empty?


      # Combine and Output
      output = "#{analysis[:prefix]}#{linked_series_html}#{analysis[:suffix]}"
      output.strip
    end
  end
end

Liquid::Template.register_tag('series_text', Jekyll::SeriesTextTag)
