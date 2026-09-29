# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../../infrastructure/plugin_logger_utils' # For logging
require_relative '../../infrastructure/tag_argument_utils'

# Renders numbers with proper unit formatting and abbreviations.
#
# Generates HTML with properly formatted unit abbreviations using
# narrow non-breaking spaces and abbr elements.
#
# Usage in Liquid templates:
#   {% units number=100 unit="F" %}
module Jekyll
  #   {% units number=50 unit="km/h" %}
  module UI
    module Tags
      # Liquid tag for rendering numbers with proper unit formatting.
      # Generates HTML with unit abbreviations and narrow non-breaking spaces.
      class UnitsTag < Liquid::Tag
        # Aliases for readability
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        Logger = Jekyll::Infrastructure::PluginLoggerUtils
        private_constant :TagArgs, :Logger

        THIN_NBSP = '&#x202F;' # U+202F NARROW NO-BREAK SPACE

        # Internal unit definitions (can be expanded)
        # Optional `nospace: true` removes the separator between number and symbol.
        UNIT_DEFINITIONS = {
          'C' => { symbol: '°C', name: 'Degrees Celsius' },
          'F' => { symbol: '°F', name: 'Degrees Fahrenheit' },
          'cm' => { symbol: 'cm', name: 'Centimeters' },
          'deg' => { symbol: '°', name: 'Degrees', nospace: true },
          'ft' => { symbol: 'ft', name: 'Feet' },
          'g' => { symbol: 'g', name: 'Grams' },
          'in' => { symbol: 'in', name: 'Inches' },
          'kg' => { symbol: 'kg', name: 'Kilograms' },
          'kph' => { symbol: 'kph', name: 'Kilometres per hour' },
          'm' => { symbol: 'm', name: 'Meters' },
          'mm' => { symbol: 'mm', name: 'Millimeters' },
          'mph' => { symbol: 'mph', name: 'Miles per hour' },
          # Add other units here: 'ABBR' => { symbol: "SYMBOL", name: "Full Name" },
        }.freeze

        ALLOWED_KEYS = %w[number unit].freeze

        def initialize(tag_name, markup, tokens)
          super
          @attributes = TagArgs.parse_named_arguments(
            markup.strip, tag_name: 'units', allowed: ALLOWED_KEYS, required: %w[number unit],
          )
        end

        def render(context)
          number, unit_key, error_log = resolve_and_validate_args(context)
          return error_log if error_log

          unit_symbol, unit_name, nospace, warning_log = lookup_unit_data(unit_key, number, context)

          if context.registers[:render_mode] == :markdown
            nospace ? "#{number}#{unit_symbol}" : "#{number} #{unit_symbol}"
          else
            html_output = generate_html(number, unit_symbol, unit_name, nospace)
            warning_log + html_output
          end
        end

        private

        def resolve_and_validate_args(context)
          number_input = TagArgs.resolve_value(@attributes['number'], context)
          unit_key_input = TagArgs.resolve_value(@attributes['unit'], context)

          return validate_number_input(context, number_input) if value_blank?(number_input)

          number_str = number_input.to_s
          return validate_unit_input(context, unit_key_input, number_str) if value_blank?(unit_key_input)

          [number_str, unit_key_input.to_s.strip, nil]
        end

        def validate_number_input(context, _number_input)
          [
            nil,
            nil,
            log_error(
              context,
              "Argument 'number' resolved to nil or empty.",
              { number_markup: @attributes['number'] },
            ),
          ]
        end

        def validate_unit_input(context, _unit_key_input, number_str)
          [
            nil,
            nil,
            log_error(
              context,
              "Argument 'unit' resolved to nil or empty.",
              { unit_markup: @attributes['unit'], number_val: number_str },
            ),
          ]
        end

        def lookup_unit_data(unit_key, number, context)
          unit_data = UNIT_DEFINITIONS[unit_key]
          return [unit_data[:symbol], unit_data[:name], unit_data[:nospace] || false, ''] if unit_data

          log_unknown_unit(unit_key, number, context)
        end

        def log_unknown_unit(unit_key, number, context)
          log = Logger.log_liquid_failure(
            context: context,
            tag_type: 'UNITS_TAG_WARNING',
            reason: 'Unit key not found in internal definitions. Using key as symbol/name.',
            identifiers: { UnitKey: unit_key, Number: number },
            level: :warn,
          )
          [unit_key, unit_key, false, log]
        end

        def generate_html(number, symbol, name, nospace)
          escaped_number = CGI.escapeHTML(number)
          escaped_unit_name = CGI.escapeHTML(name)
          escaped_unit_symbol = CGI.escapeHTML(symbol)
          separator = nospace ? '' : THIN_NBSP

          "<span class=\"nowrap unit\">#{escaped_number}#{separator}" \
            "<abbr class=\"unit-abbr\" title=\"#{escaped_unit_name}\">#{escaped_unit_symbol}</abbr></span>"
        end

        def value_blank?(val)
          val.nil? || val.to_s.strip.empty?
        end

        def log_error(context, reason, identifiers)
          Logger.log_liquid_failure(
            context: context, tag_type: 'UNITS_TAG_ERROR', reason: reason, identifiers: identifiers, level: :error,
          )
        end
      end
    end
  end
end

Liquid::Template.register_tag('units', Jekyll::UI::Tags::UnitsTag)
