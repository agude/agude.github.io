# frozen_string_literal: true

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
      @tag_name = tag_name
      @raw_markup = markup.strip
      @limit_markup = nil

      parse_arguments
    end

    def render(context)
      limit = resolve_limit(context)
      feed_items = FeedUtils.get_combined_feed_items(site: context.registers[:site], limit: limit)

      return log_empty_feed(context, limit) if feed_items.empty?

      generate_feed_html(feed_items, context)
    end

    private

    def parse_arguments
      return if @raw_markup.empty?

      unless @raw_markup.match?(SYNTAX_NAMED_ARG)
        raise Liquid::SyntaxError, "Syntax Error in '#{@tag_name}': Invalid arguments. Use 'limit=N' or no arguments."
      end

      scanner = StringScanner.new(@raw_markup)
      parse_named_argument(scanner)
      validate_no_trailing_chars(scanner)
    end

    def parse_named_argument(scanner)
      unless scanner.scan(SYNTAX_NAMED_ARG)
        raise Liquid::SyntaxError, "Syntax Error in '#{@tag_name}': Malformed arguments '#{@raw_markup}'."
      end

      key = scanner[1].to_s.strip
      value = scanner[2].to_s.strip
      validate_and_store_argument(key, value)
    end

    def validate_and_store_argument(key, value)
      if key == 'limit'
        @limit_markup = value
      else
        raise Liquid::SyntaxError,
              "Syntax Error in '#{@tag_name}': Unknown argument '#{key}'. Only 'limit' is allowed."
      end
    end

    def validate_no_trailing_chars(scanner)
      scanner.skip(/\s*/)
      return if scanner.eos?

      raise Liquid::SyntaxError, "Syntax Error in '#{@tag_name}': Unexpected arguments after 'limit'."
    end

    def resolve_limit(context)
      return DEFAULT_LIMIT unless @limit_markup

      resolved = TagArgumentUtils.resolve_value(@limit_markup, context)
      begin
        val = Integer(resolved.to_s)
        val.positive? ? val : DEFAULT_LIMIT
      rescue ArgumentError, TypeError
        DEFAULT_LIMIT
      end
    end

    def log_empty_feed(context, limit)
      PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: 'FRONT_PAGE_FEED',
        reason: 'No items found for the front page feed.',
        identifiers: { limit: limit },
        level: :info
      )
    end

    def generate_feed_html(items, context)
      output = +'<div class="card-grid">' # Initialize as mutable string
      output << "\n"
      items.each do |item|
        output << render_item(item, context)
      end
      output << "</div>\n"
    end

    def render_item(item, context)
      if book?(item)
        BookCardUtils.render(item, context) << "\n"
      elsif post?(item)
        ArticleCardUtils.render(item, context) << "\n"
      else
        log_unknown_item(item, context) << "\n"
      end
    end

    def book?(item)
      item.respond_to?(:collection) && item.collection&.label == 'books'
    end

    def post?(item)
      item.respond_to?(:collection) && item.collection&.label == 'posts'
    end

    def log_unknown_item(item, context)
      PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: 'FRONT_PAGE_FEED',
        reason: 'Unknown item type in feed.',
        identifiers: build_unknown_item_identifiers(item),
        level: :warn
      )
    end

    def build_unknown_item_identifiers(item)
      {
        item_title: item.data['title'] || 'N/A',
        item_url: item.url || 'N/A',
        item_collection: item.collection&.label || 'N/A'
      }
    end
  end
end

Liquid::Template.register_tag('front_page_feed', Jekyll::FrontPageFeedTag)
