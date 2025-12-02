# frozen_string_literal: true

# _plugins/article_card_lookup_tag.rb
require 'jekyll'
require 'liquid'
require 'uri'
require 'cgi'
require 'strscan'
require_relative 'src/infrastructure/plugin_logger_utils'
require_relative 'utils/article_card_utils'
require_relative 'src/infrastructure/tag_argument_utils'
require_relative 'logic/card_lookups/article_finder'

module Jekyll
  # Renders an article card by looking up a post by URL.
  #
  # Usage in Liquid templates:
  #   {% article_card_lookup "/blog/my-post" %}
  #   {% article_card_lookup url="/blog/my-post" %}
  class ArticleCardLookupTag < Liquid::Tag
    QuotedFragment = Liquid::QuotedFragment

    def initialize(tag_name, markup, tokens)
      super
      @tag_name = tag_name
      @raw_markup = markup
      @url_markup = parse_markup(markup)
    end

    # Renders the article card by looking up the post and calling the utility function
    def render(context)
      site = context.registers[:site]
      finder = Jekyll::CardLookups::ArticleFinder.new(site: site, url_markup: @url_markup, context: context)
      result = finder.find

      return log_error(context, result[:error], result[:url]) if result[:error]

      render_card(result[:post], result[:url], context)
    end

    private

    def parse_markup(markup)
      scanner = StringScanner.new(markup.strip)
      url = nil

      if scanner.scan(/url\s*=\s*(#{QuotedFragment}|\S+)/)
        url = scanner[1]
      elsif scanner.scan(QuotedFragment) || scanner.scan(/\S+/)
        url = scanner.matched
      end

      scanner.skip(/\s+/)
      validate_scanner(scanner, markup)
      validate_url(url, markup)

      url
    end

    def validate_scanner(scanner, markup)
      return if scanner.eos?

      raise Liquid::SyntaxError,
            "Syntax Error in 'article_card_lookup': Unknown argument(s) '#{scanner.rest}' in '#{markup}'"
    end

    def validate_url(url, markup)
      return if url && !url.strip.empty?

      raise Liquid::SyntaxError, "Syntax Error in 'article_card_lookup': Could not find URL value in '#{markup}'"
    end

    def log_error(context, error, url)
      case error[:type]
      when :url_error
        PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'ARTICLE_CARD_LOOKUP',
          reason: 'URL markup resolved to empty or nil.',
          identifiers: { Markup: @url_markup || @raw_markup },
          level: :error
        )
      when :collection_error
        PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'ARTICLE_CARD_LOOKUP',
          reason: 'Cannot iterate site.posts.docs. It is missing, not an Array, or site.posts is invalid.',
          identifiers: { URL: url, PostsDocsType: error[:details] },
          level: :error
        )
      when :post_not_found
        PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'ARTICLE_CARD_LOOKUP',
          reason: 'Could not find post.',
          identifiers: { URL: error[:details] },
          level: :warn
        )
      end
    end

    def render_card(post, target_url, context)
      ArticleCardUtils.render(post, context)
    rescue StandardError => e
      PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: 'ARTICLE_CARD_LOOKUP',
        reason: "Error calling ArticleCardUtils.render utility: #{e.message}",
        identifiers: { URL: target_url,
                       ErrorClass: e.class.name,
                       ErrorMessage: e.message.lines.first.chomp.slice(0, 100) },
        level: :error
      )
    end
  end
end

Liquid::Template.register_tag('article_card_lookup', Jekyll::ArticleCardLookupTag)
