# frozen_string_literal: true

# _plugins/book_card_lookup_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../core/book_card_utils'
require_relative '../../../infrastructure/tag_argument_utils'
require_relative '../lookups/book_finder'

module Jekyll
  # Renders a book card by looking up a book by its title.
  #
  # Usage in Liquid templates:
  #   {% book_card_lookup "The Fellowship of the Ring" %}
  #   {% book_card_lookup title="The Fellowship of the Ring" %}
  class BookCardLookupTag < Liquid::Tag
    QuotedFragment = Liquid::QuotedFragment

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup
      @title_markup = parse_markup(markup)
    end

    # Renders the book card by looking up the book and calling the utility
    def render(context)
      target_title_input = TagArgumentUtils.resolve_value(@title_markup, context)

      return log_empty_title(context) if title_empty?(target_title_input)

      site = context.registers[:site]
      return log_missing_collection(context, target_title_input) unless site.collections.key?('books')

      finder = Jekyll::CardLookups::BookFinder.new(site: site, title: target_title_input)
      result = finder.find

      return log_book_not_found(context, target_title_input) if result[:error]

      render_book_card(result[:book], context, target_title_input)
    end

    private

    def parse_markup(markup)
      scanner = StringScanner.new(markup.strip)
      title = scan_title(scanner)
      scanner.skip(/\s+/)
      validate_scanner(scanner)
      validate_title(title)
      title
    end

    def validate_scanner(scanner)
      return if scanner.eos?

      raise Liquid::SyntaxError,
            "Syntax Error in 'book_card_lookup': Unknown argument(s) '#{scanner.rest}' in '#{@raw_markup}'"
    end

    def validate_title(title)
      return unless title.nil? || title.strip.empty?

      raise Liquid::SyntaxError, "Syntax Error in 'book_card_lookup': Could not find title value in '#{@raw_markup}'"
    end

    def scan_title(scanner)
      # Try to match named argument first: title='...' or title=...
      if scanner.scan(/title\s*=\s*(#{QuotedFragment}|\S+)/)
        scanner[1] # Value part of title=value
      else
        # If not named, assume positional: '...' or ...
        # Reset scanner if it consumed part of a non-matching named arg pattern
        scanner.reset
        scanner.skip_until(/\A\s*/) # Go to start of content
        scanner.matched if scanner.scan(QuotedFragment) || scanner.scan(/\S+/)
      end
    end

    def title_empty?(title)
      title.nil? || title.to_s.strip.empty?
    end

    def render_book_card(found_book, context, target_title_input)
      # --- Call Utility to Render Card ---
      BookCardUtils.render(found_book, context) # CHANGED: Call the new utility
    rescue StandardError => e
      # Return the log message from PluginLoggerUtils
      PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: 'BOOK_CARD_LOOKUP',
        reason: "Error calling BookCardUtils.render utility: #{e.message}",
        identifiers: { Title: target_title_input.to_s,
                       ErrorClass: e.class.name,
                       ErrorMessage: e.message.lines.first.chomp.slice(0, 100) },
        level: :error
      )
    end

    def log_empty_title(context)
      PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: 'BOOK_CARD_LOOKUP',
        reason: 'Title markup resolved to empty or nil.',
        identifiers: { Markup: @title_markup || @raw_markup },
        level: :error
      )
    end

    def log_missing_collection(context, target_title_input)
      PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: 'BOOK_CARD_LOOKUP',
        reason: "Required 'books' collection not found in site configuration.",
        identifiers: { Title: target_title_input.to_s }, # Log the title we were trying to find
        level: :error # Prerequisite missing
      )
    end

    def log_book_not_found(context, target_title_input)
      PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: 'BOOK_CARD_LOOKUP',
        reason: 'Could not find book.',
        identifiers: { Title: target_title_input.to_s }, # Use original input for clarity in log
        level: :warn
      )
    end
  end
end

Liquid::Template.register_tag('book_card_lookup', Jekyll::BookCardLookupTag)
