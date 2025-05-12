# _plugins/utils/book_card_utils.rb
require 'cgi'
require_relative '../liquid_utils' # For _prepare_display_title
require_relative './plugin_logger_utils'
require_relative './card_data_extractor_utils'
require_relative './card_renderer_utils'
require_relative './author_link_util'
require_relative './rating_utils'
# UrlUtils is used by CardDataExtractorUtils

module BookCardUtils
  def self.render(book_object, context)
    # Extract common data using the new utility
    base_data = CardDataExtractorUtils.extract_base_data(
      book_object,
      context,
      default_title: "Untitled Book",
      log_tag_type: "BOOK_CARD_UTIL" # Specific log type
    )

    return base_data[:log_output] if base_data[:log_output] && !base_data[:log_output].empty? && base_data[:site].nil?
    return base_data[:log_output] if base_data[:data].nil?

    # --- Prepare Book-Specific Data ---
    item_data_hash = base_data[:data] # This is book_object.data

    prepared_title = LiquidUtils._prepare_display_title(base_data[:raw_title])
    title_html = "<strong><cite class=\"book-title\">#{prepared_title}</cite></strong>"

    # Alt text for book covers is specific, using the raw (un-typographied) title
    image_alt = "Book cover of #{base_data[:raw_title]}."

    description_html = CardDataExtractorUtils.extract_description_html(item_data_hash, type: :book)

    # Extra elements for book card
    extra_elements = []
    if item_data_hash['book_author'] && !item_data_hash['book_author'].to_s.strip.empty?
      author_html = AuthorLinkUtils.render_author_link(item_data_hash['book_author'], context)
      # Ensure proper spacing and newlines for clean HTML output when joined by CardRendererUtils
      extra_elements << "    <span class=\"by-author\"> by #{author_html}</span>\n"
    end
    if item_data_hash['rating']
      # Assuming RatingUtils.render_rating_stars returns a self-contained HTML block
      rating_html = RatingUtils.render_rating_stars(item_data_hash['rating'], 'div')
      extra_elements << "    #{rating_html}\n"
    end

    # --- Assemble card_data for the generic renderer ---
    card_data_hash = {
      base_class: "book-card",
      url: base_data[:absolute_url],
      image_url: base_data[:absolute_image_url],
      image_alt: image_alt, # CardRendererUtils will CGI.escapeHTML this
      image_div_class: "card-book-cover",
      title_html: title_html,
      extra_elements_html: extra_elements,
      description_html: description_html,
      # Matching the nested div structure from the original _includes/book_card.html
      description_wrapper_html_open: "    <div class=\"card-element card-text\">\n      ",
      description_wrapper_html_close: "\n    </div>\n"
    }

    log_prefix = base_data[:log_output] || ""
    log_prefix + CardRendererUtils.render_card(context: context, card_data: card_data_hash)
  end
end
