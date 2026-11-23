# frozen_string_literal: true

require 'cgi'
require 'jekyll'

module Jekyll
  module UI
    module Cards
      # Renders the shared list item, image, and text markup for HTML cards.
      module CardRendererUtils
        # @pattern Render the extracted card fields with the caller's title
        # markup, image slot, and excerpt wrapper. Image alt text is escaped here.
        def self.render_card(card_data:)
          validate_data!(card_data)

          <<~HTML.chomp
            <li class="#{card_data[:base_class]}">
            #{render_image_section(card_data)}  <div class="card-element card-text">
                <a href="#{card_data[:url]}">
                  #{card_data[:title_html]}
                </a>
            #{card_data[:extra_elements_html]&.join}#{render_description(card_data)}  </div>
            </li>
          HTML
        end

        def self.validate_data!(data)
          required = %i[base_class url title_html]
          missing = required.select { |key| !data.is_a?(Hash) || data[key].to_s.strip.empty? }
          return if missing.empty?

          identity = if data.is_a?(Hash)
                       required.filter_map do |key|
                         value = data[key]
                         "#{key}=#{value.inspect}" unless value.to_s.strip.empty?
                       end.join(', ')
                     else
                       "card_data=#{data.class}"
                     end
          message = "Card data missing required fields: #{missing.join(', ')}"
          message += " (#{identity})" unless identity.empty?
          raise Jekyll::Errors::FatalException, message
        end

        def self.render_image_section(data)
          url = data[:image_url]
          return '' unless url && !url.empty?

          alt = CGI.escapeHTML(data[:image_alt] || '')
          # EagerCardImages makes the first images on a card-list page eager.
          # ImageDimensionsInjector removes sizes if the image has no srcset.
          sizes = data[:image_sizes] ? %( sizes="auto, #{data[:image_sizes]}") : ''
          "  <div class=\"card-element #{data[:image_div_class]}\">\n    " \
            "<a href=\"#{data[:url]}\">\n      " \
            "<img src=\"#{url}\" alt=\"#{alt}\" loading=\"lazy\" decoding=\"async\"#{sizes} />\n    " \
            "</a>\n  " \
            "</div>\n"
        end

        def self.render_description(data)
          excerpt = data[:excerpt]
          return '' if excerpt.to_s.strip.empty?

          "#{data[:description_wrapper_html_open]}#{excerpt}#{data[:description_wrapper_html_close]}"
        end

        private_class_method :validate_data!, :render_image_section, :render_description
      end
    end
  end
end
