# frozen_string_literal: true

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
      @tag_name = tag_name
      @raw_markup = markup
      @attributes = {}

      parse_arguments
      validate_arguments
    end

    def render(context)
      log_type = TagArgumentUtils.resolve_value(@attributes['type'], context).to_s
      log_reason = TagArgumentUtils.resolve_value(@attributes['reason'], context).to_s
      identifiers = resolve_identifiers(context)

      PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: log_type,
        reason: log_reason,
        identifiers: identifiers
      )
    end

    private

    def parse_arguments
      scanner = StringScanner.new(@raw_markup.strip)
      while scanner.scan(SYNTAX)
        @attributes[scanner[1]] = scanner[2]
        scanner.skip(/\s*/)
      end

      return if scanner.eos?

      raise Liquid::SyntaxError,
            "Syntax Error in 'log_failure': Invalid arguments near '#{scanner.rest}' in '#{@raw_markup}'"
    end

    def validate_arguments
      validate_required_arg('type')
      validate_required_arg('reason')
    end

    def validate_required_arg(arg)
      return if @attributes[arg]

      raise Liquid::SyntaxError,
            "Syntax Error in 'log_failure': Required argument '#{arg}' is missing in '#{@raw_markup}'"
    end

    def resolve_identifiers(context)
      identifiers = {}
      @attributes.each do |key, value_markup|
        next if %w[type reason].include?(key)

        identifiers[key] = TagArgumentUtils.resolve_value(value_markup, context)
      end
      identifiers
    end
  end
end

Liquid::Template.register_tag('log_failure', Jekyll::LogFailureTag)
