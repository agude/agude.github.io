# frozen_string_literal: true

# _plugins/units_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan' # For parsing arguments
require_relative 'utils/plugin_logger_utils' # For logging
require_relative 'utils/tag_argument_utils'

module Jekyll
  class UnitsTag < Liquid::Tag
    SYNTAX = /([\w-]+)\s*=\s*(#{Liquid::QuotedFragment}|\S+)/o
    THIN_NBSP = '&#x202F;' # U+202F NARROW NO-BREAK SPACE

    # Internal unit definitions (can be expanded)
    UNIT_DEFINITIONS = {
      'F' => { symbol: '°F', name: 'Degrees Fahrenheit' },
      'C' => { symbol: '°C', name: 'Degrees Celsius' },
      'g' => { symbol: 'g',  name: 'Grams' },
      'kg' => { symbol: 'kg', name: 'Kilograms' },
      'm' => { symbol: 'm', name: 'Meters' },
      'cm' => { symbol: 'cm', name: 'Centimeters' },
      'mm' => { symbol: 'mm', name: 'Millimeters' },
      'in' => { symbol: 'in', name: 'Inches' },
      'ft' => { symbol: 'ft', name: 'Feet' },
      'kph' => { symbol: 'kph', name: 'Kilometres per hour' },
      'mph' => { symbol: 'mph', name: 'Miles per hour' }
      # Add other units here: 'ABBR' => { symbol: "SYMBOL", name: "Full Name" },
    }.freeze

    ALLOWED_KEYS = %w[number unit].freeze

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup
      @attributes = parse_attributes(markup)
      validate_attributes
    end

    def render(context)
      number, unit_key, error_log = resolve_and_validate_args(context)
      return error_log if error_log

      unit_symbol, unit_name, warning_log = lookup_unit_data(unit_key, number, context)

      html_output = generate_html(number, unit_symbol, unit_name)
      warning_log + html_output
    end

    private

    def parse_attributes(markup)
      attributes = {}
      scanner = StringScanner.new(markup.strip)
      while scanner.scan(SYNTAX)
        attributes[scanner[1]] = scanner[2]
        scanner.skip(/\s*/)
      end

      unless scanner.eos?
        raise Liquid::SyntaxError,
          "Syntax Error in 'units' tag: Invalid or unexpected trailing arguments near " \
          "'#{scanner.rest}' in '#{@raw_markup}'"
      end
      attributes
    end

    def validate_attributes
      @attributes.each_key do |key|
        unless ALLOWED_KEYS.include?(key)
          raise Liquid::SyntaxError, "Syntax Error in 'units' tag: Unknown argument '#{key}' in '#{@raw_markup}'"
        end
      end

      validate_required_arg('number')
      validate_required_arg('unit')
    end

    def validate_required_arg(arg)
      return if @attributes[arg]

      raise Liquid::SyntaxError,
        "Syntax Error in 'units' tag: Required argument '#{arg}' is missing in '#{@raw_markup}'"
    end

    def resolve_and_validate_args(context)
      number_input = TagArgumentUtils.resolve_value(@attributes['number'], context)
      unit_key_input = TagArgumentUtils.resolve_value(@attributes['unit'], context)

      if value_blank?(number_input)
        return [nil, nil, log_error(context, "Argument 'number' resolved to nil or empty.",
                                    { number_markup: @attributes['number'] })]
      end

      number_str = number_input.to_s

      if value_blank?(unit_key_input)
        return [nil, nil, log_error(context, "Argument 'unit' resolved to nil or empty.",
                                    { unit_markup: @attributes['unit'], number_val: number_str })]
      end

      [number_str, unit_key_input.to_s.strip, nil]
    end

    def lookup_unit_data(unit_key, number, context)
      unit_data = UNIT_DEFINITIONS[unit_key]
      if unit_data
        [unit_data[:symbol], unit_data[:name], '']
      else
        log = PluginLoggerUtils.log_liquid_failure(
          context: context, tag_type: 'UNITS_TAG_WARNING',
          reason: 'Unit key not found in internal definitions. Using key as symbol/name.',
          identifiers: { UnitKey: unit_key, Number: number }, level: :warn
        )
        [unit_key, unit_key, log]
      end
    end

    def generate_html(number, symbol, name)
      escaped_number = CGI.escapeHTML(number)
      escaped_unit_name = CGI.escapeHTML(name)
      escaped_unit_symbol = CGI.escapeHTML(symbol)

      "<span class=\"nowrap unit\">#{escaped_number}#{THIN_NBSP}" \
        "<abbr class=\"unit-abbr\" title=\"#{escaped_unit_name}\">#{escaped_unit_symbol}</abbr></span>"
    end

    def value_blank?(val)
      val.nil? || val.to_s.strip.empty?
    end

    def log_error(context, reason, identifiers)
      PluginLoggerUtils.log_liquid_failure(
        context: context, tag_type: 'UNITS_TAG_ERROR', reason: reason, identifiers: identifiers, level: :error
      )
    end
  end
end

Liquid::Template.register_tag('units', Jekyll::UnitsTag)
