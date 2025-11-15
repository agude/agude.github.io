# _plugins/log_failure_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/tag_argument_utils'

module Jekyll
  # Liquid Tag to call the centralized LiquidUtils.log_failure method.
  # Allows logging warnings or non-fatal errors from Liquid templates,
  # respecting the logging configuration (_config.yml).
  #
  # Syntax: {% log_failure type="TYPE_STRING" reason="Reason Text" [optional_key="value"] [another_key=variable] %}
  #
  # Arguments:
  #   type: (Required) A string identifying the type of log message (e.g., "INCLUDE_WARNING", "DATA_MISSING").
  #   reason: (Required) A string describing the reason for the log message.
  #   Other key-value pairs: Optional identifiers to include in the log message. Values can be literals or variables.
  #
  class LogFailureTag < Liquid::Tag
    SYNTAX = /([\w-]+)\s*=\s*(#{Liquid::QuotedFragment}|\S+)/o

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup
      @attributes = {}

      # Use StringScanner for robust key=value parsing
      scanner = StringScanner.new(markup.strip)
      while scanner.scan(SYNTAX)
        key = scanner[1]
        value_markup = scanner[2]
        @attributes[key] = value_markup
        scanner.skip(/\s*/)
      end

      # Check if there's any unparsed text left
      unless scanner.eos?
        raise Liquid::SyntaxError,
              "Syntax Error in 'log_failure': Invalid arguments near '#{scanner.rest}' in '#{@raw_markup}'"
      end

      # Validate required arguments
      unless @attributes['type']
        raise Liquid::SyntaxError,
              "Syntax Error in 'log_failure': Required argument 'type' is missing in '#{@raw_markup}'"
      end
      return if @attributes['reason']

      raise Liquid::SyntaxError,
            "Syntax Error in 'log_failure': Required argument 'reason' is missing in '#{@raw_markup}'"
    end

    def render(context)
      # Resolve required arguments
      log_type = TagArgumentUtils.resolve_value(@attributes['type'], context).to_s
      log_reason = TagArgumentUtils.resolve_value(@attributes['reason'], context).to_s

      # Resolve optional identifier arguments
      identifiers = {}
      @attributes.each do |key, value_markup|
        # Skip the required args we already handled
        next if %w[type reason].include?(key)

        # Use the key as-is (it's already a string from the scanner)
        identifiers[key] = TagArgumentUtils.resolve_value(value_markup, context)
      end

      PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: log_type,
        reason: log_reason,
        identifiers: identifiers
      )
    end
  end
end

Liquid::Template.register_tag('log_failure', Jekyll::LogFailureTag)
