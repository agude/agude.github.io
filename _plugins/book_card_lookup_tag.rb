# _plugins/book_card_lookup_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative 'liquid_utils'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/book_card_utils'

module Jekyll
  class BookCardLookupTag < Liquid::Tag
    QuotedFragment = Liquid::QuotedFragment

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup

      @title_markup = nil
      scanner = StringScanner.new(markup.strip)
      if scanner.scan(/title\s*=\s*(#{QuotedFragment}|\S+)/)
          @title_markup = scanner[1]
      else
        if scanner.scan(QuotedFragment) || scanner.scan(/\S+/)
          @title_markup = scanner.matched
        end
      end
      scanner.skip(/\s+/)
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
      target_title = LiquidUtils.resolve_value(@title_markup, context).to_s.gsub(/\s+/, ' ').strip
      unless target_title && !target_title.empty?
        # Return the HTML comment (or empty string if logging is off)
        return PluginLoggerUtils.log_liquid_failure(context: context, tag_type: "BOOK_CARD_LOOKUP", reason: "Title markup resolved to empty", identifiers: { Markup: @title_markup || @raw_markup })
      end
      target_title_downcased = target_title.downcase

      found_book = nil
      if site.collections.key?('books')
        found_book = site.collections['books'].docs.find do |book|
          next if book.data['published'] == false
          book.data['title']&.gsub(/\s+/, ' ')&.strip&.downcase == target_title_downcased
        end
      end

      unless found_book
        return PluginLoggerUtils.log_liquid_failure(context: context, tag_type: "BOOK_CARD_LOOKUP", reason: "Could not find book", identifiers: { Title: target_title })
      end

      # --- Call Utility to Render Card ---
      begin
        BookCardUtils.render(found_book, context) # CHANGED: Call the new utility
      rescue => e
        # Return the log message from PluginLoggerUtils
        PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "BOOK_CARD_LOOKUP",
          reason: "Error calling BookCardUtils.render utility", # Updated reason
          identifiers: { Title: target_title, Error: e.message }
        )
      end
      # --- End Render Card ---
    end # End render
  end # End class
end # End module

Liquid::Template.register_tag('book_card_lookup', Jekyll::BookCardLookupTag)
