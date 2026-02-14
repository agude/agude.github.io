# frozen_string_literal: true

# _plugins/src/content/posts/article_card_renderer.rb
require 'cgi'
require_relative '../../infrastructure/plugin_logger_utils'
require_relative '../../infrastructure/typography_utils'
require_relative '../../ui/cards/card_data_extractor_utils'
require_relative '../../ui/cards/card_renderer_utils'

module Jekyll
  module Posts
    # Helper class to handle article card rendering logic.
    #
    # Provides two public interfaces:
    # - extract_data: returns a frozen hash of raw card data (no HTML)
    # - render: returns the full HTML card string
    class ArticleCardRenderer
      def initialize(post_object, context)
        @post_object = post_object
        @context = context
        @log_output = ''
      end

      def extract_data
        extract_base
        return nil if invalid_base_data?

        @data_accessor = @base_data[:data_source_for_keys]
        {
          title: @base_data[:raw_title],
          excerpt: resolve_excerpt,
          url: @base_data[:absolute_url],
          date: @data_accessor['date'],
          image_url: @base_data[:absolute_image_url],
          image_alt: resolve_image_alt,
        }.freeze
      end

      def render
        data = extract_data
        return @log_output unless data

        card_data = assemble_card_data(data)
        @log_output + Jekyll::UI::Cards::CardRendererUtils.render_card(context: @context, card_data: card_data)
      end

      private

      def extract_base
        @base_data = Jekyll::UI::Cards::CardDataExtractorUtils.extract_base_data(
          @post_object,
          @context,
          default_title: 'Untitled Post',
          log_tag_type: 'ARTICLE_CARD_UTIL',
        )
        @log_output = @base_data[:log_output] || ''
      end

      def invalid_base_data?
        @base_data[:site].nil? || @base_data[:data_source_for_keys].nil?
      end

      def resolve_excerpt
        Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(@data_accessor, type: :article)
      end

      def assemble_card_data(data)
        {
          base_class: 'article-card',
          url: data[:url],
          image_url: data[:image_url],
          image_alt: data[:image_alt],
          image_div_class: 'card-image',
          title_html: format_title_html(data[:title]),
          description_html: data[:excerpt],
          description_wrapper_html_open: "<br>\n",
          description_wrapper_html_close: '',
          extra_elements_html: [],
        }
      end

      def format_title_html(title)
        prepared = Jekyll::Infrastructure::TypographyUtils.prepare_display_title(title)
        "<strong>#{prepared}</strong>"
      end

      def resolve_image_alt
        path = @data_accessor['image']
        alt = @data_accessor['image_alt']
        default_alt = 'Article header image, used for decoration.'

        return default_alt unless present?(path)

        resolve_alt_with_path(path, alt, default_alt)
      end

      def resolve_alt_with_path(path, alt, default_alt)
        return alt if present?(alt)

        log_missing_alt(path)
        default_alt
      end

      def present?(value)
        value && !value.to_s.strip.empty?
      end

      def log_missing_alt(path)
        @log_output << Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'ARTICLE_CARD_ALT_MISSING',
          reason: "Missing 'image_alt' front matter for article image. Using default alt text.",
          identifiers: { article_title: @base_data[:raw_title], image_path: path },
          level: :warn,
        )
      end
    end
  end
end
