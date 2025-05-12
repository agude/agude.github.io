# _plugins/utils/card_data_extractor_utils.rb
require_relative './url_utils'
require_relative './plugin_logger_utils'

module CardDataExtractorUtils

  # Extracts common base data required for rendering any card.
  # Handles initial validation of the item_object and context.
  #
  # @param item_object [Jekyll::Document, Jekyll::Page, MockDocument] The Jekyll item.
  # @param context [Liquid::Context] The current Liquid context.
  # @param default_title [String] Default title if item has no title.
  # @param log_tag_type [String] Tag type string for logging errors.
  # @return [Hash] A hash containing:
  #   :site [Jekyll::Site, MockSite, nil] Site object, or nil if context/site missing.
  #   :data [Hash, nil] Item's data hash, or nil if item_object invalid.
  #   :absolute_url [String, nil] Absolute URL of the item, or '#' if item_object.url is empty.
  #   :absolute_image_url [String, nil] Absolute URL of the item's image.
  #   :raw_title [String, nil] The raw title of the item.
  #   :log_output [String] HTML log comment if initial validation fails, else an empty string.
  def self.extract_base_data(item_object, context, default_title: "Untitled Item", log_tag_type: "CARD_DATA_EXTRACTION")
    log_output_accumulator = ""

    unless context && (site = context.registers[:site])
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context, # Pass context even if it's nil, logger handles it
        tag_type: log_tag_type,
        reason: "Context or Site object unavailable for card data extraction.",
        identifiers: { item: item_object.is_a?(String) ? item_object : "Object" }
      )
      # Return immediately with log if site context is missing, as further operations depend on it.
      return { log_output: log_output_accumulator, site: nil, data: nil, absolute_url: nil, absolute_image_url: nil, raw_title: nil }
    end

    unless item_object && item_object.respond_to?(:data) && item_object.respond_to?(:url)
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: log_tag_type,
        reason: "Invalid item_object provided for card data extraction (must respond to :data and :url).",
        identifiers: { item_class: item_object.class.name, item_inspect: item_object.inspect.slice(0,100) }
      )
      # Return with log if item_object is fundamentally unusable.
      return { log_output: log_output_accumulator, site: site, data: nil, absolute_url: nil, absolute_image_url: nil, raw_title: nil }
    end

    data = item_object.data # item_object.data should be a hash or respond to []

    item_url_path = item_object.url.to_s # Ensure string
    absolute_url = item_url_path.empty? ? '#' : UrlUtils.absolute_url(item_url_path, site)

    image_path = data['image'] # data is a hash
    absolute_image_url = nil
    if image_path && !image_path.to_s.strip.empty?
      absolute_image_url = UrlUtils.absolute_url(image_path.to_s, site)
    end

    current_title = data['title']
    if current_title.nil? || current_title.to_s.strip.empty? # Check if nil OR empty after stripping
      raw_title = default_title
    else
      raw_title = current_title # Use the original (potentially with whitespace if that's intended for some reason, though unlikely)
                                # Or, if you always want it stripped if not default: raw_title = current_title.to_s.strip
                                # Let's assume if it's not nil and not empty-after-strip, we use it as is from data.
                                # The _prepare_display_title will handle final stripping for display.
      raw_title = current_title.to_s # Ensure it's a string
    end


    {
      site: site,
      data: data,
      absolute_url: absolute_url,
      absolute_image_url: absolute_image_url,
      raw_title: raw_title,
      log_output: log_output_accumulator # Will be empty if no errors above
    }
  end

  # Extracts and prepares the description string for a card.
  # Handles different logic for article vs. book cards based on `type`.
  #
  # @param item_data_hash [Hash] The data hash of the item (e.g., item_object.data).
  # @param type [Symbol] :article or :book, to determine description source priority.
  # @return [String] The processed HTML description string (stripped of leading/trailing whitespace).
  #                  Returns an empty string if no suitable description content is found.
  def self.extract_description_html(item_data_hash, type: :article)
    description_content = nil
    # Ensure item_data_hash is a hash to prevent errors if nil is passed
    item_data_hash ||= {}

    if type == :article
      description_content = item_data_hash['description'] # Check front matter 'description' first
      # Fallback to excerpt only if 'description' is nil or an empty string after stripping
      if description_content.nil? || description_content.to_s.strip.empty?
        excerpt_obj = item_data_hash['excerpt']
        if excerpt_obj&.respond_to?(:output)
          description_content = excerpt_obj.output # This is already HTML
        end
      end
    elsif type == :book
      # Books primarily use the excerpt for the card description
      excerpt_obj = item_data_hash['excerpt']
      if excerpt_obj&.respond_to?(:output)
        description_content = excerpt_obj.output # This is already HTML
      end
    end
    # Ensure we return a string, stripping whitespace. If description_content is nil, .to_s gives ""
    description_content.to_s.strip
  end

end
