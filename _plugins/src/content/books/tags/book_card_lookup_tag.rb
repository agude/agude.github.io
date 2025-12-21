# frozen_string_literal: true

# _plugins/book_card_lookup_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../core/book_card_utils'
require_relative '../../../infrastructure/tag_argument_utils'
require_relative '../lookups/book_finder'

# Renders a book card by looking up a book by its title and optional date.
#
# Usage in Liquid templates:
#   {% book_card_lookup "The Fellowship of the Ring" %}
#   {% book_card_lookup title="The Fellowship of the Ring" %}
#   {% book_card_lookup title="Hyperion" date="2023-10-17" %}
#   {% book_card_lookup date="2023-10-17" title="Hyperion" %}
module Jekyll
  module Books
    module Tags
      # Liquid tag for rendering a book card by looking up a book by its title.
      # Supports both positional and named arguments in flexible order.
      # Optional date parameter filters to a specific review date.
      class BookCardLookupTag < Liquid::Tag
        QuotedFragment = Liquid::QuotedFragment
        # Aliases for readability
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        Logger = Jekyll::Infrastructure::PluginLoggerUtils
        CardUtils = Jekyll::Books::Core::BookCardUtils
        Finder = Jekyll::Books::Lookups::BookFinder
        private_constant :TagArgs, :Logger, :CardUtils, :Finder

        def initialize(tag_name, markup, tokens)
          super
          @raw_markup = markup
          @title_markup, @date_markup = parse_markup(markup)
        end

        # Renders the book card by looking up the book and calling the utility
        def render(context)
          target_title_input = TagArgs.resolve_value(@title_markup, context)
          target_date_input = @date_markup ? TagArgs.resolve_value(@date_markup, context) : nil

          return log_empty_title(context) if title_empty?(target_title_input)

          site = context.registers[:site]
          return log_missing_collection(context, target_title_input) unless site.collections.key?('books')

          finder = Finder.new(site: site, title: target_title_input, date: target_date_input)
          result = finder.find

          return handle_finder_error(result, target_title_input, target_date_input, context) if result[:error]

          render_book_card(result[:book], context, target_title_input)
        end

        private

        def parse_markup(markup)
          scanner = StringScanner.new(markup.strip)
          title = nil
          date = nil

          until scanner.eos?
            scanner.skip(/\s+/)
            break if scanner.eos?

            if (val = scan_key_value(scanner, 'title')) || (val = scan_positional(scanner))
              raise_duplicate_error('title') if title
              title = val
            elsif (val = scan_key_value(scanner, 'date'))
              raise_duplicate_error('date') if date
              date = val
            else
              handle_unknown_argument(scanner)
            end
          end

          validate_title(title)
          [title, date]
        end

        def scan_key_value(scanner, key)
          return nil unless scanner.scan(/#{key}\s*=\s*(#{QuotedFragment}|\S+)/)

          scanner[1]
        end

        # Match quoted strings or variable names (without =) as positional arguments
        QUOTED_STRING = /"[^"]*"|'[^']*'/
        VARIABLE_NAME = /[a-zA-Z_][\w.]*/
        private_constant :QUOTED_STRING, :VARIABLE_NAME

        def scan_positional(scanner)
          # First try quoted string
          return scanner.matched if scanner.scan(QUOTED_STRING)

          # Then try variable name, but only if not followed by =
          pos = scanner.pos
          return nil unless scanner.scan(VARIABLE_NAME)

          # Save matched before match? potentially changes it
          matched = scanner.matched

          # Check if this looks like a key=value pair (followed by optional whitespace then =)
          if scanner.match?(/\s*=/)
            # It's a key=value, rewind and return nil
            scanner.pos = pos
            return nil
          end

          matched
        end

        def raise_duplicate_error(key)
          raise Liquid::SyntaxError,
                "Syntax Error in 'book_card_lookup': Duplicate '#{key}' argument in '#{@raw_markup}'"
        end

        def handle_unknown_argument(scanner)
          unknown = scanner.scan(/\S+/)
          raise Liquid::SyntaxError,
                "Syntax Error in 'book_card_lookup': Unknown argument(s) '#{unknown}' in '#{@raw_markup}'"
        end

        def validate_title(title)
          return unless title.nil? || title.strip.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in 'book_card_lookup': Could not find title value in '#{@raw_markup}'"
        end

        def title_empty?(title)
          title.nil? || title.to_s.strip.empty?
        end

        def handle_finder_error(result, target_title_input, target_date_input, context)
          error_type = result[:error][:type]

          case error_type
          when :date_not_found
            raise Liquid::SyntaxError,
                  "Error in 'book_card_lookup': No book found with title '#{target_title_input}' " \
                  "on date '#{target_date_input}'"
          when :invalid_date
            raise Liquid::SyntaxError,
                  "Error in 'book_card_lookup': Invalid date format '#{target_date_input}'. " \
                  'Expected YYYY-MM-DD format.'
          else
            log_book_not_found(context, target_title_input)
          end
        end

        def render_book_card(found_book, context, target_title_input)
          # --- Call Utility to Render Card ---
          CardUtils.render(found_book, context)
        rescue StandardError => e
          # Return the log message from Jekyll::Infrastructure::PluginLoggerUtils
          Logger.log_liquid_failure(
            context: context,
            tag_type: 'BOOK_CARD_LOOKUP',
            reason: "Error calling CardUtils.render utility: #{e.message}",
            identifiers: { Title: target_title_input.to_s,
                           ErrorClass: e.class.name,
                           ErrorMessage: e.message.lines.first.chomp.slice(0, 100) },
            level: :error
          )
        end

        def log_empty_title(context)
          Logger.log_liquid_failure(
            context: context,
            tag_type: 'BOOK_CARD_LOOKUP',
            reason: 'Title markup resolved to empty or nil.',
            identifiers: { Markup: @title_markup || @raw_markup },
            level: :error
          )
        end

        def log_missing_collection(context, target_title_input)
          Logger.log_liquid_failure(
            context: context,
            tag_type: 'BOOK_CARD_LOOKUP',
            reason: "Required 'books' collection not found in site configuration.",
            identifiers: { Title: target_title_input.to_s }, # Log the title we were trying to find
            level: :error # Prerequisite missing
          )
        end

        def log_book_not_found(context, target_title_input)
          Logger.log_liquid_failure(
            context: context,
            tag_type: 'BOOK_CARD_LOOKUP',
            reason: 'Could not find book.',
            identifiers: { Title: target_title_input.to_s }, # Use original input for clarity in log
            level: :warn
          )
        end
      end
    end
  end
end

Liquid::Template.register_tag('book_card_lookup', Jekyll::Books::Tags::BookCardLookupTag)
