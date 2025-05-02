# _plugins/article_card_lookup_tag.rb
require 'jekyll'
require 'liquid'
require 'uri'
require 'cgi'
require 'strscan'
require_relative 'liquid_utils'

module Jekyll
  class ArticleCardLookupTag < Liquid::Tag
    QuotedFragment = Liquid::QuotedFragment

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup
      @include_template_path = '_includes/article_card.html'

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

    # Helper to safely get data from post, providing defaults
    def get_post_data(post)
      return {} unless post && post.respond_to?(:url) && post.respond_to?(:data)
      description = post.data['description'] || ''
      if description.empty? && post.respond_to?(:data) && post.data['excerpt'] # Check data hash for excerpt
          description = post.data['excerpt'] || ''
      end
      {
        'url' => post.url || '',
        'image' => post.data['image'] || '',
        'image_alt' => post.data['image_alt'] || "Article header image, used for decoration.",
        'title' => post.data['title'] || 'Untitled Post',
        'description' => description
      }
    end

    # Renders the article card by looking up the post and including the template
    def render(context)
      site = context.registers[:site]
      target_url_raw = LiquidUtils.resolve_value(@url_markup, context).to_s.strip
      unless target_url_raw && !target_url_raw.empty?
        LiquidUtils.log_failure(context: context, tag_type: "ARTICLE_CARD_LOOKUP", reason: "URL markup resolved to empty", identifiers: { Markup: @url_markup || @raw_markup })
        return ""
      end
      target_url = target_url_raw.start_with?('/') ? target_url_raw : "/#{target_url_raw}"

      # --- Post Lookup (Using defensive access) ---
      posts_iterable = site.posts
      found_post = nil
      if posts_iterable.respond_to?(:docs)
        found_post = posts_iterable.docs.find { |post| post.url == target_url }
      elsif posts_iterable.is_a?(Array)
        found_post = posts_iterable.find { |post| post.respond_to?(:url) && post.url == target_url }
      else
        LiquidUtils.log_failure(context: context, tag_type: "ARTICLE_CARD_LOOKUP", reason: "Cannot iterate site.posts", identifiers: { URL: target_url, Type: posts_iterable.class.name })
        return ""
      end
      # --- End Post Lookup ---

      unless found_post
        LiquidUtils.log_failure(context: context, tag_type: "ARTICLE_CARD_LOOKUP", reason: "Could not find post", identifiers: { URL: target_url })
        return ""
      end

      # --- Render the Include (Context Fix) ---
      begin
        include_path = site.in_source_dir(@include_template_path)
        raise IOError, "Include file '#{@include_template_path}' not found" unless File.exist?(include_path)
        source = site.liquid_renderer.file("(include)").parse(File.read(include_path))

        # Use context.stack for rendering includes from tags
        context.stack do
          context['include'] = get_post_data(found_post)
          source.render!(context)
        end # context.stack automatically pops the scope

      rescue => e
        LiquidUtils.log_failure(
            context: context,
            tag_type: "ARTICLE_CARD_LOOKUP",
            reason: "Error loading or rendering include '#{@include_template_path}'",
            identifiers: { URL: target_url, Error: e.message }
        )
        "" # Return empty on error
      end
      # --- End Render Include ---
    end # End render
  end # End class
end # End module

Liquid::Template.register_tag('article_card_lookup', Jekyll::ArticleCardLookupTag)
