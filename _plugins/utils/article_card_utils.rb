# frozen_string_literal: true

# _plugins/utils/article_card_utils.rb
require 'cgi'
require_relative 'plugin_logger_utils'
require_relative 'card_data_extractor_utils'
require_relative 'card_renderer_utils'
require_relative 'typography_utils'

module ArticleCardUtils
  def self.render(post_object, context)
    Renderer.new(post_object, context).render
  end

  # Helper class to handle article card rendering logic
  class Renderer
    def initialize(post_object, context)
      @post_object = post_object
      @context = context
      @log_output = ''
    end

    def render
      @base_data = CardDataExtractorUtils.extract_base_data(
        @post_object,
        @context,
        default_title: 'Untitled Post',
        log_tag_type: 'ARTICLE_CARD_UTIL'
      )
      @log_output = @base_data[:log_output] || ''

      return @log_output if invalid_base_data?

      @data_accessor = @base_data[:data_source_for_keys]

      card_data = assemble_card_data
      @log_output + CardRendererUtils.render_card(context: @context, card_data: card_data)
    end

    private

    def invalid_base_data?
      @base_data[:site].nil? || @base_data[:data_source_for_keys].nil?
    end

    def assemble_card_data
      {
        base_class: 'article-card',
        url: @base_data[:absolute_url],
        image_url: @base_data[:absolute_image_url],
        image_alt: resolve_image_alt,
        image_div_class: 'card-image',
        title_html: generate_title_html,
        description_html: CardDataExtractorUtils.extract_description_html(@data_accessor, type: :article),
        description_wrapper_html_open: "<br>\n",
        description_wrapper_html_close: '',
        extra_elements_html: []
      }
    end

    def generate_title_html
      prepared = TypographyUtils.prepare_display_title(@base_data[:raw_title])
      "<strong>#{prepared}</strong>"
    end

    def resolve_image_alt
      path = @data_accessor['image']
      alt = @data_accessor['image_alt']
      default_alt = 'Article header image, used for decoration.'

      if present?(path)
        if present?(alt)
          alt
        else
          log_missing_alt(path)
          default_alt
        end
      else
        default_alt
      end
    end

    def present?(value)
      value && !value.to_s.strip.empty?
    end

    def log_missing_alt(path)
      @log_output << PluginLoggerUtils.log_liquid_failure(
        context: @context,
        tag_type: 'ARTICLE_CARD_ALT_MISSING',
        reason: "Missing 'image_alt' front matter for article image. Using default alt text.",
        identifiers: { article_title: @base_data[:raw_title], image_path: path },
        level: :warn
      )
    end
  end
end
