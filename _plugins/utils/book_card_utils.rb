# _plugins/utils/book_card_utils.rb
require 'cgi'
require_relative '../liquid_utils' # For _prepare_display_title
require_relative './plugin_logger_utils'
require_relative './card_data_extractor_utils'
require_relative './card_renderer_utils'
require_relative './author_link_util'
require_relative './rating_utils'

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
    return base_data[:log_output] if base_data[:data_source_for_keys].nil?

    data_accessor = base_data[:data_source_for_keys] # This is the book_object (Drop or Document)

    prepared_title = LiquidUtils._prepare_display_title(base_data[:raw_title])
    title_html = "<strong><cite class=\"book-title\">#{prepared_title}</cite></strong>"
    image_alt = "Book cover of #{base_data[:raw_title]}."

    # Pass the same data_accessor to extract_description_html
    description_html = CardDataExtractorUtils.extract_description_html(data_accessor, type: :book)

    extra_elements = []
    if data_accessor['book_author'] && !data_accessor['book_author'].to_s.strip.empty?
      author_html = AuthorLinkUtils.render_author_link(data_accessor['book_author'], context)
      extra_elements << "    <span class=\"by-author\"> by #{author_html}</span>\n"
    end
    if data_accessor['rating'] # rating can be nil, 0, or a valid number
      rating_value = data_accessor['rating']
      # RatingUtils.render_rating_stars handles nil and invalid ratings (throws error for invalid, returns "" for nil)
      # We should catch potential ArgumentError from render_rating_stars if rating is invalid format/range
      begin
        rating_html = RatingUtils.render_rating_stars(rating_value, 'div')
        extra_elements << "    #{rating_html}\n" if rating_html && !rating_html.empty?
      rescue ArgumentError => e
        # Log this specific error if rating is bad, but don't stop card rendering
        log_msg = PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "BOOK_CARD_RATING_ERROR",
          reason: "Invalid rating value for book: #{e.message}",
          identifiers: { title: base_data[:raw_title], rating_input: rating_value.inspect }
        )
        # How to best incorporate this log_msg? Prepend to output or add to extra_elements?
        # For now, let's assume it's logged to console/HTML comment by PluginLoggerUtils
        # and we don't add a broken rating to the card.
        # The `log_prefix` below will catch logs from extract_base_data.
        # This is a new log source.
        # Let's prepend it to the output if it occurs.
        (base_data[:log_output] ||= "") << log_msg
      end
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
