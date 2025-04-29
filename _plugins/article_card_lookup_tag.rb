# _plugins/article_card_lookup_tag.rb
require 'jekyll'
require 'liquid'
require 'uri' # For joining URL parts
require_relative 'liquid_utils'

module Jekyll
  # Liquid Tag to look up an article by URL and render its card.
  # Usage: {% article_card_lookup url="/path/to/article/" %}
  #        {% article_card_lookup url=variable_with_url %}
  class ArticleCardLookupTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      # Simple parsing: expect 'url=/path/...' or 'url=variable'
      if markup.strip =~ /^url\s*=\s*(.*)$/i
        @url_markup = $1.strip
      else
        raise Liquid::SyntaxError, "Syntax Error in 'article_card_lookup': Expected {% article_card_lookup url=... %}"
      end
      @include_template_path = '_includes/article_card.html' # Path to the presentation include
    end

    # Helper to safely get data from post, providing defaults
    def get_post_data(post)
      {
        'url' => post.url,
        'image' => post.data['image'] || '', # Add default/placeholder?
        'image_alt' => post.data['image_alt'] || "Article header image, used for decoration.",
        'title' => post.data['title'] || 'Untitled Post',
        'description' => post.data['description'] || post.excerpt || '' # Fallback to excerpt
      }
    end

    def render(context)
      site = context.registers[:site]

      # Resolve the URL value
      target_url_raw = LiquidUtils.resolve_value(@url_markup, context).to_s.strip
      unless target_url_raw && !target_url_raw.empty?
        LiquidUtils.log_failure(context: context, tag_type: "ARTICLE_CARD_LOOKUP", reason: "URL markup resolved to empty", identifiers: { Markup: @url_markup })
        return ""
      end

      # Ensure the target URL starts with a slash and handles baseurl correctly for comparison
      target_url = target_url_raw.start_with?('/') ? target_url_raw : "/#{target_url_raw}"
      # Note: site.posts[].url usually includes baseurl if set, so direct comparison should work.

      # --- Post Lookup ---
      found_post = site.posts.docs.find { |post| post.url == target_url }
      # --- End Post Lookup ---

      unless found_post
        LiquidUtils.log_failure(context: context, tag_type: "ARTICLE_CARD_LOOKUP", reason: "Could not find post", identifiers: { URL: target_url })
        return "" # Or render a placeholder?
      end

      # --- Render the Include ---
      # Load the include file's content
      begin
        source = site.liquid_renderer.file("(include)") # Use dummy filename
                       .parse(File.read(site.in_source_dir(@include_template_path)))
      rescue => e
        LiquidUtils.log_failure(context: context, tag_type: "ARTICLE_CARD_LOOKUP", reason: "Failed to load include file '#{@include_template_path}'", identifiers: { Error: e.message })
        return ""
      end

      # Prepare the context for the include, passing post data under 'include' variable
      include_context = Liquid::Context.new(context.environments, context.registers, context.scopes)
      include_context['include'] = get_post_data(found_post)

      # Render the include content with the prepared context
      begin
        source.render!(include_context)
      rescue => e
        LiquidUtils.log_failure(context: context, tag_type: "ARTICLE_CARD_LOOKUP", reason: "Error rendering include '#{@include_template_path}'", identifiers: { URL: target_url, Error: e.message })
        "" # Return empty on rendering error
      end
      # --- End Render Include ---
    end
  end
end

Liquid::Template.register_tag('article_card_lookup', Jekyll::ArticleCardLookupTag)
