# frozen_string_literal: true

# _plugins/utils/card_data_extractor_utils.rb
require_relative '../../infrastructure/url_utils'
require_relative '../../infrastructure/plugin_logger_utils'

# Utility module for extracting data from Jekyll documents for card rendering.
#
# Handles validation and extraction of common data elements (titles, URLs,
module Jekyll
  # images, descriptions) needed to render article and book cards.
  module UI
    module Cards
      # Utility module for extracting and validating card data from Jekyll documents.
      # Provides methods for extracting titles, URLs, images, and descriptions.
      module CardDataExtractorUtils
        # Extracts common base data required for rendering any card.
        # Handles initial validation of the item_object and context.
        #
        # @param item_object [Jekyll::Document, Jekyll::Page, Drop] The Jekyll item or its Liquid Drop.
        # @param context [Liquid::Context] The current Liquid context.
        # @param default_title [String] Default title if item has no title.
        # @param log_tag_type [String] Tag type string for logging errors.
        # @return [Hash] A hash containing site, data sources, URLs, title, and logs.
        def self.extract_base_data(item_object, context, default_title: 'Untitled Item',
                                   log_tag_type: 'CARD_DATA_EXTRACTION')
          BaseDataExtractor.new(item_object, context, default_title, log_tag_type).extract
        end

        # Extracts and prepares the description string for a card.
        # Handles different logic for article vs. book cards based on `type`.
        #
        # @param source_for_data [Hash, Drop] The object to query (item.data or the Drop).
        # @param type [Symbol] :article or :book, to determine description source priority.
        # @return [String] The processed HTML description string.
        def self.extract_description_html(source_for_data, type: :article)
          source = source_for_data || {}
          content = nil

          if type == :article
            content = source['description']
            content = _extract_excerpt(source) if content.nil? || content.to_s.strip.empty?
          elsif type == :book
            content = _extract_excerpt(source)
          end

          content.to_s.strip
        end

        def self._extract_excerpt(source)
          excerpt = source['excerpt']
          if excerpt.respond_to?(:output)
            excerpt.output
          elsif excerpt
            excerpt.to_s
          end
        end

        # Helper class to handle base data extraction logic
        class BaseDataExtractor
          def initialize(item, context, default_title, log_tag)
            @item = item
            @context = context
            @default_title = default_title
            @log_tag = log_tag
            @log_out = +'' # Initialize as mutable string
          end

          def extract
            return failure_result unless validate_context?
            return failure_result unless validate_item?

            success_result
          end

          private

          def validate_context?
            return true if @context && (@site = @context.registers[:site])

            log_failure('Context or Site object unavailable for card data extraction.', { item_type: @item.class.name })
            false
          end

          def validate_item?
            if valid_jekyll_object?
              @data_source = @item.data
              return true
            end

            if valid_drop?
              @data_source = @item
              return true
            end

            log_invalid_item
            false
          end

          def valid_jekyll_object?
            (@item.is_a?(Jekyll::Document) || @item.is_a?(Jekyll::Page)) &&
              @item.respond_to?(:url) && @item.respond_to?(:data) && @item.data.is_a?(Hash)
          end

          def valid_drop?
            @item.is_a?(Jekyll::Drops::Drop) &&
              @item.respond_to?(:url) && @item.respond_to?(:[]) && @item.respond_to?(:key?)
          end

          def log_invalid_item
            log_failure(
              'Invalid item_object: Expected a Jekyll Document/Page or Drop with .url and data access capabilities.',
              { item_class: @item.class.name, item_inspect: @item.inspect.slice(0, 100) }
            )
          end

          def success_result
            {
              site: @site,
              data_source_for_keys: @data_source,
              data_for_description: @data_source,
              absolute_url: absolute_url,
              absolute_image_url: absolute_image_url,
              raw_title: raw_title,
              log_output: @log_out
            }
          end

          def failure_result
            { log_output: @log_out, site: @site, data_source_for_keys: nil, data_for_description: nil,
              absolute_url: nil, absolute_image_url: nil, raw_title: nil }
          end

          def absolute_url
            url = @item.url.to_s
            url.empty? ? '#' : Jekyll::Infrastructure::UrlUtils.absolute_url(url, @site)
          end

          def absolute_image_url
            path = @data_source['image']
            return nil unless path && !path.to_s.strip.empty?

            Jekyll::Infrastructure::UrlUtils.absolute_url(path.to_s, @site)
          end

          def raw_title
            t = @data_source['title']
            t.nil? || t.to_s.strip.empty? ? @default_title : t.to_s
          end

          def log_failure(reason, identifiers)
            @log_out << Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
              context: @context, tag_type: @log_tag, reason: reason, identifiers: identifiers
            )
          end
        end
      end
    end
  end
end
