# frozen_string_literal: true

require_relative '../../infrastructure/url_utils'
require_relative '../../infrastructure/front_matter_image'
require_relative '../../infrastructure/plugin_logger_utils'

module Jekyll
  module UI
    module Cards
      # Extracts the document fields shared by book and article cards.
      module CardDataExtractorUtils
        # Returns the common data and an HTML diagnostic. On failure the
        # data is nil, even if logging is disabled and the diagnostic is empty.
        def self.extract_base_data(item, context, default_title: 'Untitled Item', log_tag_type: 'CARD_DATA_EXTRACTION')
          site = context.registers[:site] if context
          unless site
            return nil, log_failure(
              context,
              log_tag_type,
              'Context or Site object unavailable for card data extraction.',
              { item_type: item.class.name },
            )
          end

          source = data_source(item)
          unless source
            return nil, log_failure(
              context,
              log_tag_type,
              'Invalid item_object: Expected a Jekyll Document/Page or Drop with .url and data access capabilities.',
              { item_class: item.class.name, item_inspect: item.inspect.slice(0, 100) },
            )
          end

          image = Jekyll::Infrastructure::FrontMatterImage
          url = absolute_url(item.url.to_s, site)
          image_url = image.absolute_url(source['image'], site, source: image.source_name(item))
          title = source['title'].to_s
          title = default_title if title.strip.empty?
          [{ source: source, title: title, url: url, image_url: image_url }, +'']
        end

        # Articles prefer a front-matter description. Book cards use the review excerpt.
        def self.extract_description_html(source, type: :article)
          source ||= {}
          case type
          when :article
            description = source['description'].to_s.strip
            description.empty? ? extract_excerpt(source) : description
          when :book
            extract_excerpt(source)
          else
            ''
          end
        end

        def self.extract_excerpt(source)
          excerpt = source['excerpt']
          if excerpt.respond_to?(:output)
            excerpt.output.to_s.strip
          else
            excerpt ? excerpt.to_s.strip : ''
          end
        end

        def self.data_source(item)
          if (item.is_a?(Jekyll::Document) || item.is_a?(Jekyll::Page)) &&
             item.respond_to?(:url) && item.respond_to?(:data) && item.data.is_a?(Hash)
            item.data
          elsif item.is_a?(Jekyll::Drops::Drop) &&
                item.respond_to?(:url) && item.respond_to?(:[]) && item.respond_to?(:key?)
            item
          end
        end

        def self.absolute_url(url, site)
          url.empty? ? '#' : Jekyll::Infrastructure::UrlUtils.absolute_url(url, site)
        end

        def self.log_failure(context, tag, reason, identifiers)
          +Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
            context: context, tag_type: tag, reason: reason, identifiers: identifiers,
          )
        end

        private_class_method :extract_excerpt, :data_source, :absolute_url, :log_failure
      end
    end
  end
end
