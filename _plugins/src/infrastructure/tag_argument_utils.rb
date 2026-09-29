# frozen_string_literal: true

require 'liquid'
require 'strscan'

module Jekyll
  module Infrastructure
    # Utility module for parsing and resolving Liquid tag arguments.
    module TagArgumentUtils
      NAMED_ARGUMENT = /([\w-]+)\s*=\s*(#{Liquid::QuotedFragment}|\S+)/o

      # Parses a named-only argument tail and rejects malformed, unknown,
      # duplicate, and missing required keys before a tag resolves values.
      def self.parse_named_arguments(markup, tag_name:, allowed:, required: [], downcase_keys: false)
        scanner = markup.is_a?(StringScanner) ? markup : StringScanner.new(markup)
        arguments = {}

        until scanner.eos?
          scanner.skip(/\s*/)
          break if scanner.eos?

          unless scanner.scan(NAMED_ARGUMENT)
            raise Liquid::SyntaxError,
                  "Syntax Error in '#{tag_name}': Invalid argument syntax near '#{scanner.rest}'."
          end

          key = downcase_keys ? scanner[1].downcase : scanner[1]
          unless allowed.include?(key)
            raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': Unknown argument '#{key}'."
          end
          if arguments.key?(key)
            raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': Duplicate argument '#{key}'."
          end

          arguments[key] = scanner[2]
        end

        required.each do |key|
          next if arguments.key?(key)

          raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': Required argument '#{key}' is missing."
        end
        arguments
      end

      # Resolves a Liquid markup string.
      # - If the markup is quoted (single or double), returns the literal string content.
      # - If the markup is NOT quoted, assumes it's a variable name (simple or dot notation)
      #   and attempts to look it up in the context using context[].
      # - Returns the variable's value if found (which can be any object, including nil or false).
      # - Returns nil if the unquoted variable name is not found in the context.
      #
      # @param markup [String] The markup string from the Liquid tag.
      # @param context [Liquid::Context] The current Liquid context.
      # @return [String, Object, nil] The resolved value.
      def self.resolve_value(markup, context)
        return nil if markup.nil? || markup.empty?

        stripped_markup = markup.strip
        return nil if stripped_markup.empty?

        if quoted?(stripped_markup)
          # It's a quoted literal. Return the content inside the quotes.
          stripped_markup[1..-2]
        else
          # Not quoted. Assume it's a variable name (simple or dot notation).
          # Look it up using context[]. This handles dot notation and returns nil
          # for failed lookups or if the variable's actual value is nil.
          context[stripped_markup]
        end
      end

      # True unless the resolved value is the string 'false' (case-insensitive).
      # Nil markup (option absent) returns +default+.
      def self.resolve_boolean(markup, context, default: true)
        return default unless markup

        resolve_value(markup, context).to_s.downcase != 'false'
      end

      def self.quoted?(markup)
        (markup.start_with?('"') && markup.end_with?('"')) ||
          (markup.start_with?("'") && markup.end_with?("'"))
      end
      private_class_method :quoted?
    end
  end
end
