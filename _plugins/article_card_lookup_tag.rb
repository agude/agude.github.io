# _plugins/article_card_lookup_tag.rb
require 'jekyll'
require 'liquid'
require 'uri'
require 'cgi'
require 'strscan'
require_relative 'liquid_utils'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/article_card_utils'

module Jekyll
  class ArticleCardLookupTag < Liquid::Tag
    QuotedFragment = Liquid::QuotedFragment

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup

      @url_markup = nil
      scanner = StringScanner.new(markup.strip)
      if scanner.scan(/url\s*=\s*(#{QuotedFragment}|\S+)/)
          @url_markup = scanner[1]
      else
        # Positional argument attempt
        if scanner.scan(QuotedFragment) || scanner.scan(/\S+/)
          @url_markup = scanner.matched
        end
      end
      scanner.skip(/\s+/)
      unless scanner.eos?
        raise Liquid::SyntaxError, "Syntax Error in 'article_card_lookup': Unknown argument(s) '#{scanner.rest}' in '#{@raw_markup}'"
      end
      unless @url_markup && !@url_markup.strip.empty?
        raise Liquid::SyntaxError, "Syntax Error in 'article_card_lookup': Could not find URL value in '#{@raw_markup}'"
      end
    end

    # Renders the article card by looking up the post and calling the utility function
    def render(context)
      site = context.registers[:site]
      target_url_raw = LiquidUtils.resolve_value(@url_markup, context).to_s.strip

      unless target_url_raw && !target_url_raw.empty?
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "ARTICLE_CARD_LOOKUP",
          reason: "URL markup resolved to empty or nil.",
          identifiers: { Markup: @url_markup || @raw_markup },
          level: :error,
        )
      end
      # Ensure URL starts with a slash for consistent lookup
      target_url = target_url_raw.start_with?('/') ? target_url_raw : "/#{target_url_raw}"

      posts_collection_proxy = site.posts
      found_post = nil

      # Check the validity of posts_collection_proxy.docs
      can_iterate_posts_docs = false
      actual_docs_type = "unknown"

      if posts_collection_proxy && posts_collection_proxy.respond_to?(:docs)
        if posts_collection_proxy.docs.is_a?(Array)
          can_iterate_posts_docs = true
        else
          actual_docs_type = posts_collection_proxy.docs.class.name # Type of .docs
        end
      elsif posts_collection_proxy
        actual_docs_type = posts_collection_proxy.class.name # Type of the proxy itself
      else
        actual_docs_type = "nil" # site.posts was nil
      end

      unless can_iterate_posts_docs
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "ARTICLE_CARD_LOOKUP",
          reason: "Cannot iterate site.posts.docs. It is missing, not an Array, or site.posts is invalid.",
          identifiers: { URL: target_url, PostsDocsType: actual_docs_type },
          level: :error,
        )
      end

      # If we reach here, posts_collection_proxy.docs is an Array
      found_post = posts_collection_proxy.docs.find { |post| post.url == target_url }

      unless found_post
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "ARTICLE_CARD_LOOKUP",
          reason: "Could not find post.",
          identifiers: { URL: target_url },
          level: :warn,
        )
      end

      # --- Call Utility to Render Card ---
      begin
        ArticleCardUtils.render(found_post, context)
      rescue => e
        PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "ARTICLE_CARD_LOOKUP",
          reason: "Error calling ArticleCardUtils.render utility: #{e.message}",
          identifiers: { URL: target_url, ErrorClass: e.class.name, ErrorMessage: e.message.lines.first.chomp.slice(0, 100) },
          level: :error,
        )
      end
      # --- End Render Card ---
    end # End render
  end # End class
end # End module

Liquid::Template.register_tag('article_card_lookup', Jekyll::ArticleCardLookupTag)
