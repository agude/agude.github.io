# _plugins/front_page_feed_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative 'utils/feed_utils'
require_relative 'utils/article_card_utils'
require_relative 'utils/book_card_utils'
require_relative 'utils/tag_argument_utils'
require_relative 'utils/plugin_logger_utils'

module Jekyll
  class FrontPageFeedTag < Liquid::Tag
    DEFAULT_LIMIT = 5
    SYNTAX_NAMED_ARG = /([\w-]+)\s*=\s*(#{Liquid::QuotedFragment}|\S+)/o

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup.strip
      @limit_markup = nil

      # Simple parser for an optional 'limit=N' argument
      if @raw_markup.match?(SYNTAX_NAMED_ARG)
        scanner = StringScanner.new(@raw_markup)
        unless scanner.scan(SYNTAX_NAMED_ARG)
          raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': Malformed arguments '#{@raw_markup}'."
        end

        key = scanner[1].to_s.strip
        value_markup = scanner[2].to_s.strip
        if key == 'limit'
          @limit_markup = value_markup
        else
          raise Liquid::SyntaxError,
                "Syntax Error in '#{tag_name}': Unknown argument '#{key}'. Only 'limit' is allowed."
        end
        scanner.skip(/\s*/)
        unless scanner.eos?
          raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': Unexpected arguments after 'limit'."
        end

      # This case implies a malformed named argument if match? was true but scan failed.

      elsif !@raw_markup.empty?
        # If markup is not empty but doesn't match the named arg syntax (e.g., positional)
        raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': Invalid arguments. Use 'limit=N' or no arguments."
      end
    end

    def render(context)
      site = context.registers[:site]
      context.registers[:page] # For PluginLoggerUtils context
      output = '' # Initialize output string

      limit = DEFAULT_LIMIT
      if @limit_markup
        resolved_limit = TagArgumentUtils.resolve_value(@limit_markup, context)
        begin
          limit_int = Integer(resolved_limit.to_s) if resolved_limit # Ensure resolved_limit is not nil
          limit = limit_int if limit_int&.positive?
        rescue ArgumentError, TypeError
          # Silently use default limit if conversion fails or value is invalid
        end
      end

      feed_items = FeedUtils.get_combined_feed_items(site: site, limit: limit)

      if feed_items.empty?
        # Append log message to output if feed is empty
        output << PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'FRONT_PAGE_FEED',
          reason: 'No items found for the front page feed.',
          identifiers: { limit: limit },
          level: :info
        )
        return output # Return the log message (or empty string if logging is off)
      end

      output << "<div class=\"card-grid\">\n"
      feed_items.each do |item|
        # Determine item type. Jekyll::Document objects have a `collection` attribute.
        if item.respond_to?(:collection) && item.collection&.label == 'books'
          output << BookCardUtils.render(item, context) << "\n"
        elsif item.respond_to?(:collection) && item.collection&.label == 'posts'
          output << ArticleCardUtils.render(item, context) << "\n"
        else
          # Append log message for unknown item type to output
          output << PluginLoggerUtils.log_liquid_failure(
            context: context,
            tag_type: 'FRONT_PAGE_FEED',
            reason: 'Unknown item type in feed.',
            identifiers: { item_title: item.data['title'] || 'N/A', item_url: item.url || 'N/A',
                           item_collection: item.collection&.label || 'N/A' },
            level: :warn
          )
          output << "\n" # Add a newline after the comment
        end
      end
      output << "</div>\n"

      output
    end
  end
end

Liquid::Template.register_tag('front_page_feed', Jekyll::FrontPageFeedTag)
