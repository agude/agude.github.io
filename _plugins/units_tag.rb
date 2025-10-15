# _plugins/units_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan' # For parsing arguments
require_relative 'utils/plugin_logger_utils' # For logging
require_relative 'utils/tag_argument_utils'

module Jekyll
  class UnitsTag < Liquid::Tag
    SYNTAX = /([\w-]+)\s*=\s*(#{Liquid::QuotedFragment}|\S+)/o.freeze
    THIN_NBSP = "&#x202F;" # U+202F NARROW NO-BREAK SPACE

    # Internal unit definitions (can be expanded)
    UNIT_DEFINITIONS = {
      'F'  => { symbol: "°F", name: "Degrees Fahrenheit" },
      'C'  => { symbol: "°C", name: "Degrees Celsius" },
      'g'  => { symbol: "g",  name: "Grams" },
      'kg' => { symbol: "kg", name: "Kilograms" },
      'm'  => { symbol: "m",  name: "Meters" },
      'cm' => { symbol: "cm", name: "Centimeters" },
      'mm' => { symbol: "mm", name: "Millimeters" },
      'in' => { symbol: "in", name: "Inches" },
      'ft' => { symbol: "ft", name: "Feet" },
      'kph' => { symbol: "kph", name: "Kilometres per hour" },
      'mph' => { symbol: "mph", name: "Miles per hour" },
      # Add other units here: 'ABBR' => { symbol: "SYMBOL", name: "Full Name" },
    }.freeze

    ALLOWED_KEYS = ['number', 'unit'].freeze

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup
      @attributes = {}

      scanner = StringScanner.new(markup.strip)
      while scanner.scan(SYNTAX)
        key = scanner[1]
        value_markup = scanner[2]
        @attributes[key] = value_markup
        scanner.skip(/\s*/)
      end

      # Check for unrecognized attribute keys that were successfully parsed
      @attributes.keys.each do |parsed_key|
        unless ALLOWED_KEYS.include?(parsed_key.to_s)
          raise Liquid::SyntaxError, "Syntax Error in 'units' tag: Unknown argument '#{parsed_key}' in '#{@raw_markup}'"
        end
      end

      # Check if there's any unparseable text left (trailing garbage)
      unless scanner.eos?
        raise Liquid::SyntaxError, "Syntax Error in 'units' tag: Invalid or unexpected trailing arguments near '#{scanner.rest}' in '#{@raw_markup}'"
      end

      # Check for required arguments (must be present among parsed attributes)
      unless @attributes['number']
        # Note: We can't use PluginLoggerUtils here as it's a syntax error, build should halt.
        raise Liquid::SyntaxError, "Syntax Error in 'units' tag: Required argument 'number' is missing in '#{@raw_markup}'"
      end
      unless @attributes['unit']
        raise Liquid::SyntaxError, "Syntax Error in 'units' tag: Required argument 'unit' is missing in '#{@raw_markup}'"
      end
    end

    def render(context)
      log_output = "" # Accumulator for any log messages

      # Resolve arguments
      number_input = TagArgumentUtils.resolve_value(@attributes['number'], context)
      unit_key_input = TagArgumentUtils.resolve_value(@attributes['unit'], context)

      # Validate resolved number
      if number_input.nil? || number_input.to_s.strip.empty?
        # Log with PluginLoggerUtils, as this is a runtime value resolution failure
        log_output << PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "UNITS_TAG_ERROR",
          reason: "Argument 'number' resolved to nil or empty.",
          identifiers: { number_markup: @attributes['number'] },
          level: :error,
        )
        # Return only the log comment, or an empty span if preferred
        return log_output
      end
      number_str = number_input.to_s # Ensure it's a string for output

      # Validate resolved unit_key
      if unit_key_input.nil? || unit_key_input.to_s.strip.empty?
        log_output << PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "UNITS_TAG_ERROR",
          reason: "Argument 'unit' resolved to nil or empty.",
          identifiers: { unit_markup: @attributes['unit'], number_val: number_str },
          level: :error,
        )
        return log_output
      end
      unit_key = unit_key_input.to_s.strip

      # Look up unit data
      unit_data = UNIT_DEFINITIONS[unit_key]
      unit_symbol = nil
      unit_name = nil

      if unit_data
        unit_symbol = unit_data[:symbol]
        unit_name = unit_data[:name]
      else
        # Fallback if unit key is not found
        unit_symbol = unit_key
        unit_name = unit_key
        log_output << PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "UNITS_TAG_WARNING", # Different tag_type for this specific warning
          reason: "Unit key not found in internal definitions. Using key as symbol/name.",
          identifiers: { UnitKey: unit_key, Number: number_str },
          level: :warn,
        )
      end

      # Escape for HTML attributes and content
      escaped_number = CGI.escapeHTML(number_str)
      escaped_unit_name = CGI.escapeHTML(unit_name)
      escaped_unit_symbol = CGI.escapeHTML(unit_symbol)

      # Output the formatted unit
      html_output = "<span class=\"nowrap unit\">"
      html_output << "#{escaped_number}"
      html_output << "#{THIN_NBSP}"
      html_output << "<abbr class=\"unit-abbr\" title=\"#{escaped_unit_name}\">#{escaped_unit_symbol}</abbr>"
      html_output << "</span>"

      log_output + html_output # Prepend any log messages
    end
  end
end

Liquid::Template.register_tag('units', Jekyll::UnitsTag)
