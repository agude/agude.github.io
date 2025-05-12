# _plugins/utils/article_card_utils.rb
require 'cgi'
require_relative '../liquid_utils' # For _prepare_display_title
require_relative './plugin_logger_utils'
require_relative './card_data_extractor_utils'
require_relative './card_renderer_utils'
# UrlUtils is used by CardDataExtractorUtils

module ArticleCardUtils
  def self.render(post_object, context)
    # Extract common data using the new utility
    base_data = CardDataExtractorUtils.extract_base_data(
      post_object,
      context,
      default_title: "Untitled Post",
      log_tag_type: "ARTICLE_CARD_UTIL" # Specific log type for this util's errors
    )

    # If base_data extraction failed critically (e.g., no context/site), return the log message
    return base_data[:log_output] if base_data[:log_output] && !base_data[:log_output].empty? && base_data[:site].nil?
    # If item_object was invalid, but site was found, log_output will contain the message.
    # We might still want to return that log_output if data is nil.
    return base_data[:log_output] if base_data[:data].nil?


    # --- Prepare Article-Specific Data ---
    item_data_hash = base_data[:data] # This is post_object.data

    prepared_title = LiquidUtils._prepare_display_title(base_data[:raw_title])
    title_html = "<strong>#{prepared_title}</strong>"

    image_alt = item_data_hash['image_alt'] || "Article header image, used for decoration."

    description_html = CardDataExtractorUtils.extract_description_html(item_data_hash, type: :article)

    # --- Assemble card_data for the generic renderer ---
    card_data_hash = {
      base_class: "article-card",
      url: base_data[:absolute_url],
      image_url: base_data[:absolute_image_url],
      image_alt: image_alt, # CardRendererUtils will CGI.escapeHTML this
      image_div_class: "card-image",
      title_html: title_html,
      description_html: description_html,
      description_wrapper_html_open: "<br>\n", # Article card specific
      description_wrapper_html_close: "",      # Article card specific
      extra_elements_html: [] # No extra elements for a basic article card
    }

    # Combine any logs from base_data extraction with the rendered card
    # (though render_card itself doesn't log, the data prep might have)
    log_prefix = base_data[:log_output] || ""
    log_prefix + CardRendererUtils.render_card(context: context, card_data: card_data_hash)
  end
end
