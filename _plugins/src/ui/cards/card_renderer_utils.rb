# frozen_string_literal: true

# _plugins/utils/card_renderer_utils.rb
require 'cgi' # For escaping image alt text if not already escaped

# Utility module for rendering HTML card components for books and articles.
module CardRendererUtils
  # Renders a generic card structure based on provided data.
  #
  # @param context [Liquid::Context] The current Liquid context (potentially for site/baseurl if needed).
  # @param card_data [Hash] A hash containing all necessary data to render the card. Expected keys:
  #   :base_class [String] e.g., "article-card", "book-card"
  #   :url [String] The primary URL for links in the card.
  #   :image_url [String, nil] URL for the card image.
  #   :image_alt [String] Alt text for the image (should be pre-escaped if containing special chars).
  #   :image_div_class [String] Class for the image container div, e.g., "card-image", "card-book-cover".
  #   :title_html [String] Pre-rendered HTML for the title (e.g., "<strong>Title</strong>").
  #   :description_html [String, nil] Pre-rendered HTML for the description.
  #   :description_wrapper_html_open [String, nil] HTML to prepend before description (e.g., "<br>", "<div>").
  #   :description_wrapper_html_close [String, nil] HTML to append after description (e.g., "", "</div>").
  #   :extra_elements_html [Array<String>, nil] Array of pre-rendered HTML strings for additional elements
  #                                            (e.g., author line, rating stars for book cards).
  # @return [String] The rendered HTML for the card.
  def self.render_card(context:, card_data:)
    # Context is currently unused but kept in signature for API compatibility.
    # Passing it to Renderer prevents Lint/UnusedMethodArgument if we use it there,
    # or we prefix with underscore if truly unused.
    Renderer.new(context, card_data).render
  end

  # Helper class to handle card rendering logic
  class Renderer
    def initialize(_context, card_data)
      @card_data = card_data
    end

    def render
      return '' unless valid_data?

      html = "<div class=\"#{@card_data[:base_class]}\">\n"
      html << render_image_section
      html << render_text_section
      html << '</div>'
    end

    private

    def valid_data?
      return true if @card_data.is_a?(Hash) && @card_data[:base_class] && @card_data[:url] && @card_data[:title_html]

      # In a real scenario, might log this failure using PluginLoggerUtils or raise error
      puts '[CardRendererUtils ERROR] Invalid or incomplete card_data provided.'
      false
    end

    def render_image_section
      url = @card_data[:image_url]
      return '' unless url && !url.empty?

      alt = CGI.escapeHTML(@card_data[:image_alt] || '')
      html = "  <div class=\"card-element #{@card_data[:image_div_class]}\">\n"
      html << "    <a href=\"#{@card_data[:url]}\">\n"
      html << "      <img src=\"#{url}\" alt=\"#{alt}\" />\n"
      html << "    </a>\n"
      html << "  </div>\n"
      html
    end

    def render_text_section
      html = +'' # Initialize as mutable string
      html << "  <div class=\"card-element card-text\">\n"
      html << render_title
      html << render_extras
      html << render_description
      html << "  </div>\n"
      html
    end

    def render_title
      "    <a href=\"#{@card_data[:url]}\">\n      " \
        "#{@card_data[:title_html]}\n    " \
        "</a>\n"
    end

    def render_extras
      return '' unless @card_data[:extra_elements_html]&.any?

      @card_data[:extra_elements_html].join
    end

    def render_description
      desc = @card_data[:description_html]
      return '' unless desc && !desc.strip.empty?

      open_tag = @card_data[:description_wrapper_html_open] || ''
      close_tag = @card_data[:description_wrapper_html_close] || ''
      "#{open_tag}#{desc}#{close_tag}"
    end
  end
end
