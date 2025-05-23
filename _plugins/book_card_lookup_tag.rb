# _plugins/book_card_lookup_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/book_card_utils'
require_relative 'utils/tag_argument_utils'

module Jekyll
  class BookCardLookupTag < Liquid::Tag
    QuotedFragment = Liquid::QuotedFragment

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup

      @title_markup = nil
      scanner = StringScanner.new(markup.strip)
      # Try to match named argument first: title='...' or title=...
      if scanner.scan(/title\s*=\s*(#{QuotedFragment}|\S+)/)
          @title_markup = scanner[1] # Value part of title=value
      else
        # If not named, assume positional: '...' or ...
        # Reset scanner if it consumed part of a non-matching named arg pattern
        scanner.reset
        scanner.skip_until(/\A\s*/) # Go to start of content
        if scanner.scan(QuotedFragment) || scanner.scan(/\S+/)
          @title_markup = scanner.matched
        end
      end

      scanner.skip(/\s+/) # Skip trailing whitespace after the identified title markup
      unless scanner.eos?
        raise Liquid::SyntaxError, "Syntax Error in 'book_card_lookup': Unknown argument(s) '#{scanner.rest}' in '#{@raw_markup}'"
      end
      unless @title_markup && !@title_markup.strip.empty?
        raise Liquid::SyntaxError, "Syntax Error in 'book_card_lookup': Could not find title value in '#{@raw_markup}'"
      end
    end


    # Renders the book card by looking up the book and calling the utility
    def render(context)
      site = context.registers[:site]
      target_title_input = TagArgumentUtils.resolve_value(@title_markup, context)

      unless target_title_input && !target_title_input.to_s.strip.empty?
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "BOOK_CARD_LOOKUP",
          reason: "Title markup resolved to empty or nil.",
          identifiers: { Markup: @title_markup || @raw_markup },
          level: :error,
        )
      end
      target_title_normalized = target_title_input.to_s.gsub(/\s+/, ' ').strip.downcase

      # Check for 'books' collection existence
      unless site.collections.key?('books')
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "BOOK_CARD_LOOKUP",
          reason: "Required 'books' collection not found in site configuration.",
          identifiers: { Title: target_title_input.to_s }, # Log the title we were trying to find
          level: :error # Prerequisite missing
        )
      end

      found_book = site.collections['books'].docs.find do |book|
        next if book.data['published'] == false
        book.data['title']&.gsub(/\s+/, ' ')&.strip&.downcase == target_title_normalized
      end

      unless found_book
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "BOOK_CARD_LOOKUP",
          reason: "Could not find book.",
          identifiers: { Title: target_title_input.to_s }, # Use original input for clarity in log
          level: :warn,
        )
      end

      # --- Call Utility to Render Card ---
      begin
        BookCardUtils.render(found_book, context) # CHANGED: Call the new utility
      rescue => e
        # Return the log message from PluginLoggerUtils
        PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "BOOK_CARD_LOOKUP",
          reason: "Error calling BookCardUtils.render utility: #{e.message}",
          identifiers: { Title: target_title_input.to_s, ErrorClass: e.class.name, ErrorMessage: e.message.lines.first.chomp.slice(0,100) },
          level: :error,
        )
      end
      # --- End Render Card ---
    end # End render
  end # End class
end # End module

Liquid::Template.register_tag('book_card_lookup', Jekyll::BookCardLookupTag)
