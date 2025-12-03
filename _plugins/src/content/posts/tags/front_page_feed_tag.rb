# frozen_string_literal: true

# _plugins/front_page_feed_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative '../feed_utils'
require_relative '../../../infrastructure/tag_argument_utils'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../feed/renderer'

module Jekyll
  # Renders a feed combining recent posts and book reviews.
  #
  # Displays a card grid of the most recent content from both the posts
  # and books collections, sorted by date.
  #
  # Usage in Liquid templates:
  #   {% front_page_feed %}
  #   {% front_page_feed limit=10 %}
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

      log_output = log_empty_feed(context, limit) if feed_items.empty?

      renderer = Jekyll::FrontPageFeed::Renderer.new(context, feed_items)
      html_output = renderer.render

      (log_output || '') + html_output
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
  end
end

Liquid::Template.register_tag('front_page_feed', Jekyll::FrontPageFeedTag)
