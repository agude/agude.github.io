# frozen_string_literal: true

# _plugins/utils/card_renderer_utils.rb
require 'cgi' # For escaping image alt text if not already escaped

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
    # site = context.registers[:site] # Not strictly needed if URLs in card_data are absolute
    # baseurl = site.config['baseurl'] || '' # Ditto

    # Basic validation of card_data structure (optional, but good for robustness)
    unless card_data.is_a?(Hash) && card_data[:base_class] && card_data[:url] && card_data[:title_html]
      # In a real scenario, might log this failure using PluginLoggerUtils or raise error
      puts '[CardRendererUtils ERROR] Invalid or incomplete card_data provided.'
      return ''
    end

    html = "<div class=\"#{card_data[:base_class]}\">\n"

    # Image Section
    if card_data[:image_url] && !card_data[:image_url].empty?
      html << "  <div class=\"card-element #{card_data[:image_div_class]}\">\n"
      html << "    <a href=\"#{card_data[:url]}\">\n"
      # Assuming image_alt is already appropriately escaped by the caller if needed,
      # but a final CGI.escapeHTML here is a safety net for direct attribute injection.
      html << "      <img src=\"#{card_data[:image_url]}\" alt=\"#{CGI.escapeHTML(card_data[:image_alt] || '')}\" />\n"
      html << "    </a>\n"
      html << "  </div>\n"
    end

    # Text Section
    html << "  <div class=\"card-element card-text\">\n"
    html << "    <a href=\"#{card_data[:url]}\">\n"
    html << "      #{card_data[:title_html]}\n"
    html << "    </a>\n"

    # Extra elements (e.g., for book card: author, rating)
    if card_data[:extra_elements_html]&.any?
      card_data[:extra_elements_html].each do |element_html|
        # These are expected to be complete HTML strings including necessary spacing/newlines
        html << element_html # Append directly, assuming it includes leading/trailing newlines or spaces as needed
      end
    end

    # Description Section
    if card_data[:description_html] && !card_data[:description_html].strip.empty?
      html << (card_data[:description_wrapper_html_open] || '')
      html << card_data[:description_html]
      html << (card_data[:description_wrapper_html_close] || '')
    end

    html << "  </div>\n" # Close card-text
    html << '</div>' # Close base_class
    html
  end
end
