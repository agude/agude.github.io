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
        # Return the HTML comment (or empty string if logging is off)
        return PluginLoggerUtils.log_liquid_failure(context: context, tag_type: "ARTICLE_CARD_LOOKUP", reason: "URL markup resolved to empty", identifiers: { Markup: @url_markup || @raw_markup })
      end
      # Ensure URL starts with a slash for consistent lookup
      target_url = target_url_raw.start_with?('/') ? target_url_raw : "/#{target_url_raw}"

      # --- Post Lookup (Using defensive access) ---
      posts_iterable = site.posts
      found_post = nil
      if posts_iterable.respond_to?(:docs)
        # Standard Jekyll 4+ lookup
        found_post = posts_iterable.docs.find { |post| post.url == target_url }
      elsif posts_iterable.is_a?(Array)
        # Fallback for potential older structures or custom setups
        found_post = posts_iterable.find { |post| post.respond_to?(:url) && post.url == target_url }
      else
        return PluginLoggerUtils.log_liquid_failure(context: context, tag_type: "ARTICLE_CARD_LOOKUP", reason: "Cannot iterate site.posts", identifiers: { URL: target_url, Type: posts_iterable.class.name })
      end
      # --- End Post Lookup ---

      unless found_post
        return PluginLoggerUtils.log_liquid_failure(context: context, tag_type: "ARTICLE_CARD_LOOKUP", reason: "Could not find post", identifiers: { URL: target_url })
      end

      # --- Call Utility to Render Card ---
      # The render_article_card utility handles extracting data and generating HTML
      begin
        ArticleCardUtils.render(found_post, context)
      rescue => e
        PluginLoggerUtils.log_liquid_failure( # Return the log from this error too
                                             context: context,
                                             tag_type: "ARTICLE_CARD_LOOKUP",
                                             reason: "Error calling ArticleCardUtils.render utility",
                                             identifiers: { URL: target_url, Error: e.message }
                                            )
        # The above call to PluginLoggerUtils returns the string, so we don't need an explicit "" here
        # unless we want to guarantee "" on an exception *within* PluginLoggerUtils itself (which is unlikely).
        # For clarity and consistency, let the return of PluginLoggerUtils be the return of this block.
      end
      # --- End Render Card ---

    end # End render
  end # End class
end # End module

Liquid::Template.register_tag('article_card_lookup', Jekyll::ArticleCardLookupTag)
