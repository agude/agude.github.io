# _plugins/series_link_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi' # Keep for QuotedFragment, though CGI itself is now in LiquidUtils
require 'strscan'
require_relative 'utils/series_link_util'
require_relative 'utils/tag_argument_utils'

module Jekyll
  class SeriesLinkTag < Liquid::Tag
    QuotedFragment = Liquid::QuotedFragment

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup

      @title_markup = nil
      @link_text_markup = nil

      scanner = StringScanner.new(markup.strip)

      # 1. Extract the Title
      if scanner.scan(QuotedFragment)
        @title_markup = scanner.matched
      elsif scanner.scan(/\S+/)
        @title_markup = scanner.matched
      else
        raise Liquid::SyntaxError, "Syntax Error in 'series_link': Could not find series title in '#{@raw_markup}'"
      end

      # 2. Scan for optional link_text
      until scanner.eos?
        scanner.skip(/\s+/)
        break if scanner.eos?

        if scanner.scan(/link_text\s*=\s*(#{QuotedFragment})/)
          @link_text_markup ||= scanner[1]
        else
          unknown_arg = scanner.scan(/\S+/)
          raise Liquid::SyntaxError,
                "Syntax Error in 'series_link': Unknown argument '#{unknown_arg}' in '#{@raw_markup}'"
        end
      end

      # Ensure title markup was actually found
      return if @title_markup && !@title_markup.strip.empty?

      raise Liquid::SyntaxError, "Syntax Error in 'series_link': Title value is missing or empty in '#{@raw_markup}'"
    end # End initialize

    # Renders the series link HTML by calling the utility function
    def render(context)
      # Resolve the potentially variable markup into actual strings
      series_title = TagArgumentUtils.resolve_value(@title_markup, context)
      link_text_override = @link_text_markup ? TagArgumentUtils.resolve_value(@link_text_markup, context) : nil

      # Call the centralized utility function from SeriesLinkUtils
      SeriesLinkUtils.render_series_link(
        series_title,
        context,
        link_text_override
      )
    end # End render
  end # End class SeriesLinkTag
end # End module Jekyll

Liquid::Template.register_tag('series_link', Jekyll::SeriesLinkTag)
