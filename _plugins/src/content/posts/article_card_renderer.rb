# frozen_string_literal: true

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
      # The card image's width, measured in Chromium (November 2026) and held
      # by `make check-images`: half the column on narrow screens, a third
      # of the content width beside the text on wide ones, 266px once the
      # content stops growing. ImageDimensionsInjector keeps this instead of
      # the configured post-image `sizes`, which describes the lead image.
      # Lazy cards prefix `auto, ` (CardRendererUtils).
      IMAGE_SIZES = '(min-width: 82.5em) 266px, (min-width: 64em) calc((100vw - 524px) / 3), ' \
                    '(min-width: 48em) calc(50vw - 218px), (min-width: 38em) calc(50vw - 28px), ' \
                    'calc(50vw - 22px)'

      def self.render(post_object, context)
        new(post_object, context).render
      end

      def initialize(post_object, context)
        @post_object = post_object
        @context = context
        @log_output = ''
      end

      def extract_data
        @base, @log_output = Jekyll::UI::Cards::CardDataExtractorUtils.extract_base_data(
          @post_object, @context, default_title: 'Untitled Post', log_tag_type: 'ARTICLE_CARD_UTIL',
        )
        return unless @base

        @data = @base[:source]
        @base.except(:source).merge(
          excerpt: Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(@data),
          date: @data['date'],
          image_alt: resolve_image_alt,
        ).freeze
      end

      def render
        data = extract_data
        return @log_output unless data

        card_data = data.merge(
          base_class: 'article-card',
          image_div_class: 'card-image',
          image_sizes: IMAGE_SIZES,
          title_html: format_title_html(data[:title]),
          description_wrapper_html_open: "<br>\n",
        )
        @log_output + Jekyll::UI::Cards::CardRendererUtils.render_card(card_data: card_data)
      end

      private

      def format_title_html(title)
        prepared = Jekyll::Infrastructure::TypographyUtils.prepare_display_title(title)
        "<strong>#{prepared}</strong>"
      end

      def resolve_image_alt
        path = @data['image']
        alt = @data['image_alt']
        default_alt = 'Article header image, used for decoration.'
        return default_alt if path.to_s.strip.empty?
        return alt if alt && !alt.to_s.strip.empty?

        log_missing_alt(path)
        default_alt
      end

      def log_missing_alt(path)
        @log_output << Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'ARTICLE_CARD_ALT_MISSING',
          reason: "Missing 'image_alt' front matter for article image. Using default alt text.",
          identifiers: { article_title: @base[:title], image_path: path },
          level: :warn,
        )
      end
    end
  end
end
