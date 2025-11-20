# frozen_string_literal: true

# _plugins/article_card_lookup_tag.rb
require 'jekyll'
require 'liquid'
require 'uri'
require 'cgi'
require 'strscan'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/article_card_utils'
require_relative 'utils/tag_argument_utils'

module Jekyll
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
      Renderer.new(context, @url_markup, @raw_markup).render
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

    # Helper class to handle rendering logic and state
    class Renderer
      def initialize(context, url_markup, raw_markup)
        @context = context
        @url_markup = url_markup
        @raw_markup = raw_markup
        @site = context.registers[:site]
      end

      def render
        target_url = resolve_target_url
        return log_url_error unless target_url

        posts = validate_posts_collection
        return log_collection_error(target_url) unless posts

        post = posts.find { |post| post.url == target_url }
        return log_post_not_found(target_url) unless post

        render_card(post, target_url)
      end

      private

      def resolve_target_url
        raw = TagArgumentUtils.resolve_value(@url_markup, @context).to_s.strip
        return nil if raw.empty?

        raw.start_with?('/') ? raw : "/#{raw}"
      end

      def validate_posts_collection
        proxy = @site.posts

        # Check validity of posts collection. nil.respond_to? is valid (returns false), so &. is not needed.
        return proxy.docs if proxy.respond_to?(:docs) && proxy.docs.is_a?(Array)

        capture_collection_error(proxy)
        nil
      end

      def capture_collection_error(proxy)
        @collection_error_type = if proxy.respond_to?(:docs)
                                   proxy.docs.class.name
                                 elsif proxy
                                   proxy.class.name
                                 else
                                   'nil'
                                 end
      end

      def render_card(post, target_url)
        ArticleCardUtils.render(post, @context)
      rescue StandardError => e
        log_render_error(target_url, e)
      end

      def log_url_error
        PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'ARTICLE_CARD_LOOKUP',
          reason: 'URL markup resolved to empty or nil.',
          identifiers: { Markup: @url_markup || @raw_markup },
          level: :error
        )
      end

      def log_collection_error(target_url)
        PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'ARTICLE_CARD_LOOKUP',
          reason: 'Cannot iterate site.posts.docs. It is missing, not an Array, or site.posts is invalid.',
          identifiers: { URL: target_url, PostsDocsType: @collection_error_type },
          level: :error
        )
      end

      def log_post_not_found(target_url)
        PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'ARTICLE_CARD_LOOKUP',
          reason: 'Could not find post.',
          identifiers: { URL: target_url },
          level: :warn
        )
      end

      def log_render_error(target_url, error)
        PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'ARTICLE_CARD_LOOKUP',
          reason: "Error calling ArticleCardUtils.render utility: #{error.message}",
          identifiers: { URL: target_url,
                         ErrorClass: error.class.name,
                         ErrorMessage: error.message.lines.first.chomp.slice(0, 100) },
          level: :error
        )
      end
    end
  end
end

Liquid::Template.register_tag('article_card_lookup', Jekyll::ArticleCardLookupTag)
