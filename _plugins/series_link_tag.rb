# frozen_string_literal: true

# _plugins/series_link_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi' # Keep for QuotedFragment, though CGI itself is now in LiquidUtils
require 'strscan'
require_relative 'utils/series_link_util'
require_relative 'utils/tag_argument_utils'

module Jekyll
  # Renders a link to a book series page.
  #
  # Creates an HTML link to the series page if one exists, otherwise
  # renders plain text.
  #
  # Usage in Liquid templates:
  #   {% series_link "The Lord of the Rings" %}
  #   {% series_link page.series link_text="the series" %}
  class SeriesLinkTag < Liquid::Tag
    QuotedFragment = Liquid::QuotedFragment

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup
      @title_markup = nil
      @link_text_markup = nil

      parse_arguments(markup)
    end

    # Renders the series link HTML by calling the utility function
    def render(context)
      series_title = TagArgumentUtils.resolve_value(@title_markup, context)
      link_text_override = resolve_link_text(context)

      SeriesLinkUtils.render_series_link(series_title, context, link_text_override)
    end

    private

    def parse_arguments(markup)
      scanner = StringScanner.new(markup.strip)
      parse_title(scanner)
      parse_optional_link_text(scanner)
      validate_title
    end

    def parse_title(scanner)
      if scanner.scan(QuotedFragment) || scanner.scan(/\S+/)
        @title_markup = scanner.matched
      else
        raise Liquid::SyntaxError,
              "Syntax Error in 'series_link': " \
              "Could not find series title in '#{@raw_markup}'"
      end
    end

    def parse_optional_link_text(scanner)
      until scanner.eos?
        scanner.skip(/\s+/)
        break if scanner.eos?

        parse_link_text_argument(scanner)
      end
    end

    def parse_link_text_argument(scanner)
      if scanner.scan(/link_text\s*=\s*(#{QuotedFragment})/)
        @link_text_markup ||= scanner[1]
      else
        unknown_arg = scanner.scan(/\S+/)
        raise Liquid::SyntaxError,
              "Syntax Error in 'series_link': " \
              "Unknown argument '#{unknown_arg}' in '#{@raw_markup}'"
      end
    end

    def validate_title
      return if @title_markup && !@title_markup.strip.empty?

      raise Liquid::SyntaxError,
            "Syntax Error in 'series_link': " \
            "Title value is missing or empty in '#{@raw_markup}'"
    end

    def resolve_link_text(context)
      return nil unless @link_text_markup

      TagArgumentUtils.resolve_value(@link_text_markup, context)
    end
  end
end

Liquid::Template.register_tag('series_link', Jekyll::SeriesLinkTag)
