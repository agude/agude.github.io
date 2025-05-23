# _plugins/utils/book_card_utils.rb
require 'cgi'
require_relative './plugin_logger_utils'
require_relative './card_data_extractor_utils'
require_relative './card_renderer_utils'
require_relative './author_link_util'
require_relative './rating_utils'

require_relative 'typography_utils'
module BookCardUtils
  DEFAULT_TITLE_FOR_BOOK_CARD = "Untitled Book".freeze

  def self.render(book_object, context)
    base_data = CardDataExtractorUtils.extract_base_data(
      book_object,
      context,
      default_title: DEFAULT_TITLE_FOR_BOOK_CARD,
      log_tag_type: "BOOK_CARD_UTIL", # Generic log type for extractor issues
    )

    log_output_accumulator = base_data[:log_output] || ""

    return log_output_accumulator if base_data[:site].nil?
    return log_output_accumulator if base_data[:data_source_for_keys].nil?

    data_accessor = base_data[:data_source_for_keys]

    # --- Title Check ---
    if base_data[:raw_title] == DEFAULT_TITLE_FOR_BOOK_CARD
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "BOOK_CARD_MISSING_TITLE",
        reason: "Book title is missing and defaulted.",
        identifiers: { book_url: base_data[:absolute_url] || data_accessor['url'] || 'N/A' },
        level: :error,
      )
    end
    prepared_title = TypographyUtils.prepare_display_title(base_data[:raw_title])
    title_html = "<strong><cite class=\"book-title\">#{prepared_title}</cite></strong>"

    # --- Image Path and Alt Text Handling ---
    image_path_fm = data_accessor['image']
    user_provided_alt_fm = data_accessor['image_alt'] # Check for user-provided alt
    final_image_alt = ""

    if image_path_fm && !image_path_fm.to_s.strip.empty?
      # Image path is provided
      if user_provided_alt_fm && !user_provided_alt_fm.to_s.strip.empty?
        final_image_alt = user_provided_alt_fm
      else
        # Image path provided, but no user alt text. Log at debug, then construct.
        log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "BOOK_CARD_USER_ALT_MISSING",
          reason: "User-provided 'image_alt' front matter missing for book image. Constructing default.",
          identifiers: { book_title: base_data[:raw_title], image_path: image_path_fm },
          level: :debug,
        )
        final_image_alt = "Book cover of #{base_data[:raw_title]}." # Construct default
      end
    else
      # Image path is NOT provided in front matter. This is an error for books.
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "BOOK_CARD_MISSING_IMAGE_PATH",
        reason: "Required 'image' front matter (path to cover image) is missing for book.",
        identifiers: { book_title: base_data[:raw_title] },
        level: :error,
      )
      final_image_alt = "Book cover of #{base_data[:raw_title]}." # Construct anyway, though image_url will be nil
    end

    # --- Excerpt Check ---
    description_html = CardDataExtractorUtils.extract_description_html(data_accessor, type: :book)
    if description_html.strip.empty?
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "BOOK_CARD_MISSING_EXCERPT",
        reason: "Book excerpt is missing or empty.",
        identifiers: { book_title: base_data[:raw_title] },
        level: :warn,
      )
    end

    # --- Extra Elements (Author, Rating) ---
    extra_elements = []
    if data_accessor['book_author'] && !data_accessor['book_author'].to_s.strip.empty?
      author_html = AuthorLinkUtils.render_author_link(data_accessor['book_author'], context)
      extra_elements << "    <span class=\"by-author\"> by #{author_html}</span>\n"
    end

    if data_accessor.key?('rating')
      rating_value = data_accessor['rating']
      begin
        rating_html = RatingUtils.render_rating_stars(rating_value, 'div')
        extra_elements << "    #{rating_html}\n" if rating_html && !rating_html.empty?
      rescue ArgumentError => e
        log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "BOOK_CARD_RATING_ERROR",
          reason: "Invalid or malformed 'rating' value for book: #{e.message}",
          identifiers: { title: base_data[:raw_title], rating_input: rating_value.inspect },
          level: :warn,
        )
      end
    end

    # --- Assemble card_data for the generic renderer ---
    card_data_hash = {
      base_class: "book-card",
      url: base_data[:absolute_url],
      image_url: base_data[:absolute_image_url], # From CardDataExtractorUtils
      image_alt: final_image_alt,
      image_div_class: "card-book-cover",
      title_html: title_html,
      extra_elements_html: extra_elements,
      description_html: description_html,
      description_wrapper_html_open: "    <div class=\"card-element card-text\">\n      ",
      description_wrapper_html_close: "\n    </div>\n",
    }

    log_output_accumulator + CardRendererUtils.render_card(context: context, card_data: card_data_hash)
  end
end
