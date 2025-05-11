# _plugins/citation_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative 'utils/citation_utils'
# Assuming TagArgumentUtils will be the new home for resolve_value
# For now, let's use LiquidUtils directly if TagArgumentUtils isn't ready.
# If it is, change LiquidUtils.resolve_value to TagArgumentUtils.resolve_value
require_relative 'liquid_utils' # Or 'utils/tag_argument_utils'

module Jekyll
  class CitationTag < Liquid::Tag
    # Regex for parsing "key='value'" or "key=variable"
    # Allows single or double quotes for values, or unquoted for variables.
    ARG_SYNTAX = /([\w-]+)\s*=\s*((['"])(?:(?!\3).)*\3|\S+)/o

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup
      @attributes_markup = {} # Store markup for each attribute

      scanner = StringScanner.new(markup.strip)
      while scanner.scan(ARG_SYNTAX)
        key = scanner[1]
        value_markup = scanner[2] # This is the raw value markup (e.g., "'John Doe'" or "page.author")
        @attributes_markup[key.to_sym] = value_markup # Store as symbol keys
        scanner.skip(/\s*/) # Skip whitespace before next argument
      end

      # Check if there's any unparsed text left, indicating a syntax error
      unless scanner.eos?
        raise Liquid::SyntaxError, "Syntax Error in 'citation' tag: Invalid arguments near '#{scanner.rest}' in '#{@raw_markup}'"
      end
    end

    def render(context)
      site = context.registers[:site]
      resolved_params = {}

      @attributes_markup.each do |key, value_markup|
        # Replace LiquidUtils.resolve_value with TagArgumentUtils.resolve_value when available
        resolved_params[key] = LiquidUtils.resolve_value(value_markup, context)
      end

      # Call the utility function to format the citation
      CitationUtils.format_citation_html(resolved_params, site)
    end
  end
end

Liquid::Template.register_tag('citation', Jekyll::CitationTag)
