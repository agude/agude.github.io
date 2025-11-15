# _plugins/utils/article_card_utils.rb
require 'cgi'
require_relative 'plugin_logger_utils'
require_relative 'card_data_extractor_utils'
require_relative 'card_renderer_utils'

require_relative 'typography_utils'
module ArticleCardUtils
  def self.render(post_object, context)
    # Extract common base data using the new utility
    base_data = CardDataExtractorUtils.extract_base_data(
      post_object,
      context,
      default_title: 'Untitled Post',
      log_tag_type: 'ARTICLE_CARD_UTIL' # Specific log type for this util's errors
    )

    # Initialize log_output from base_data extraction.
    # This ensures any logs from the extractor are preserved.
    log_output_accumulator = base_data[:log_output] || ''

    # If base_data extraction failed critically (e.g., no context/site), return the log message
    return log_output_accumulator if base_data[:site].nil?
    # If item_object was invalid, but site was found, log_output will contain the message.
    # We should return that log_output if data_source_for_keys is nil.
    return log_output_accumulator if base_data[:data_source_for_keys].nil?

    data_accessor = base_data[:data_source_for_keys] # This is the post_object (Drop or Document)

    prepared_title = TypographyUtils.prepare_display_title(base_data[:raw_title])
    title_html = "<strong>#{prepared_title}</strong>"

    # --- Image Alt Text Handling & Logging ---
    image_path_fm = data_accessor['image']
    image_alt_fm = data_accessor['image_alt']
    final_image_alt = ''

    if image_path_fm && !image_path_fm.to_s.strip.empty?
      # Image is present
      if image_alt_fm && !image_alt_fm.to_s.strip.empty?
        final_image_alt = image_alt_fm
      else
        # Image exists, but user did not provide alt text. This is a warning.
        final_image_alt = 'Article header image, used for decoration.' # Provide a default
        # Prepend the warning to the accumulator
        log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'ARTICLE_CARD_ALT_MISSING', # Specific tag type for this warning
          reason: "Missing 'image_alt' front matter for article image. Using default alt text.",
          identifiers: { article_title: base_data[:raw_title], image_path: image_path_fm },
          level: :warn
        )
      end
    else
      # No image path provided, so no alt text needed or expected from front matter.
      # If an image was desired but path is missing, extract_base_data would have image_url as nil.
      # CardRendererUtils will not render an <img> tag if image_url is nil.
      # We can set a generic alt here, but it won't be used if no image is rendered.
      final_image_alt = 'Article header image, used for decoration.' # Default, may not be used
    end

    # Pass the same data_accessor (which is the item_object/Drop) to extract_description_html
    description_html = CardDataExtractorUtils.extract_description_html(data_accessor, type: :article)

    # --- Assemble card_data for the generic renderer ---
    card_data_hash = {
      base_class: 'article-card',
      url: base_data[:absolute_url],
      image_url: base_data[:absolute_image_url], # This comes from extract_base_data
      image_alt: final_image_alt, # Use the determined final_image_alt
      image_div_class: 'card-image',
      title_html: title_html,
      description_html: description_html,
      description_wrapper_html_open: "<br>\n", # Article card specific
      description_wrapper_html_close: '',      # Article card specific
      extra_elements_html: [] # No extra elements for a basic article card
    }

    # Prepend accumulated log messages (from extractor and alt text check) to the rendered card
    log_output_accumulator + CardRendererUtils.render_card(context: context, card_data: card_data_hash)
  end
end
