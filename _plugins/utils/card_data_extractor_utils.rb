# _plugins/utils/card_data_extractor_utils.rb
require_relative './url_utils'
require_relative './plugin_logger_utils'

module CardDataExtractorUtils

  # Extracts common base data required for rendering any card.
  # Handles initial validation of the item_object and context.
  #
  # @param item_object [Jekyll::Document, Jekyll::Page, MockDocument, Jekyll::Drops::Drop] The Jekyll item or its Liquid Drop.
  # @param context [Liquid::Context] The current Liquid context.
  # @param default_title [String] Default title if item has no title.
  # @param log_tag_type [String] Tag type string for logging errors.
  # @return [Hash] A hash containing:
  #   :site [Jekyll::Site, MockSite, nil] Site object, or nil if context/site missing.
  #   :data_source_for_keys [Hash, Jekyll::Drops::Drop, nil] The object to use for `['key']` access (item.data or the Drop itself).
  #   :data_for_description [Hash, Jekyll::Drops::Drop, nil] The object to pass to extract_description_html.
  #   :absolute_url [String, nil] Absolute URL of the item, or '#' if item_object.url is empty.
  #   :absolute_image_url [String, nil] Absolute URL of the item's image.
  #   :raw_title [String, nil] The raw title of the item.
  #   :log_output [String] HTML log comment if initial validation fails, else an empty string.
  def self.extract_base_data(item_object, context, default_title: "Untitled Item", log_tag_type: "CARD_DATA_EXTRACTION")
    log_output_accumulator = ""

    # 1. Validate Context and Site
    unless context && (site = context.registers[:site])
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: log_tag_type,
        reason: "Context or Site object unavailable for card data extraction.",
        identifiers: { item_type: item_object.class.name }
      )
      # Return immediately with log if site context is missing, as further operations depend on it.
      return { log_output: log_output_accumulator, site: nil, data_source_for_keys: nil, data_for_description: nil, absolute_url: nil, absolute_image_url: nil, raw_title: nil }
    end

    # 2. Validate item_object and determine data_source
    is_valid_item = false
    data_source = nil

    if item_object.is_a?(Jekyll::Document) || item_object.is_a?(Jekyll::Page)
      # For full Jekyll objects, they must have a .url and .data (which is a Hash)
      if item_object.respond_to?(:url) && item_object.respond_to?(:data) && item_object.data.is_a?(Hash)
        is_valid_item = true
        data_source = item_object.data # Use the .data hash for key access
      end
    elsif item_object.is_a?(Jekyll::Drops::Drop)
      # For Liquid Drops, they must have a .url and support ['key'] and key?
      if item_object.respond_to?(:url) && item_object.respond_to?(:[]) && item_object.respond_to?(:key?)
        is_valid_item = true
        data_source = item_object # The Drop itself handles ['key'] access
      end
    end

    unless item_object && is_valid_item
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: log_tag_type,
        reason: "Invalid item_object: Expected a Jekyll Document/Page or Drop with .url and data access capabilities.",
        identifiers: { item_class: item_object.class.name, item_inspect: item_object.inspect.slice(0,100) }
      )
      # Return with log if item_object is fundamentally unusable.
      return { log_output: log_output_accumulator, site: site, data_source_for_keys: nil, data_for_description: nil, absolute_url: nil, absolute_image_url: nil, raw_title: nil }
    end

    # 3. Extract common properties
    # .url should work for both Jekyll::Document/Page and Jekyll::Drops::Drop (usually delegated)
    item_url_val = item_object.url.to_s
    absolute_url = item_url_val.empty? ? '#' : UrlUtils.absolute_url(item_url_val, site)

    # Use the determined data_source (Hash or Drop) for key-based access
    image_path = data_source['image']
    absolute_image_url = nil
    if image_path && !image_path.to_s.strip.empty?
      absolute_image_url = UrlUtils.absolute_url(image_path.to_s, site)
    end

    current_title = data_source['title']
    if current_title.nil? || current_title.to_s.strip.empty?
      raw_title = default_title
    else
      raw_title = current_title.to_s # Use the title as a string
    end

    # 4. Return extracted data
    {
      site: site,
      data_source_for_keys: data_source, # This is item_object.data (Hash) or item_object (the Drop)
      data_for_description: data_source, # Pass this same source to extract_description_html
      absolute_url: absolute_url,
      absolute_image_url: absolute_image_url,
      raw_title: raw_title,
      log_output: log_output_accumulator # Will be empty if no errors from this stage
    }
  end

  # Extracts and prepares the description string for a card.
  # Handles different logic for article vs. book cards based on `type`.
  #
  # @param source_for_data [Hash, Jekyll::Drops::Drop] The object to query for description/excerpt (item.data or the Drop).
  # @param type [Symbol] :article or :book, to determine description source priority.
  # @return [String] The processed HTML description string (stripped of leading/trailing whitespace).
  #                  Returns an empty string if no suitable description content is found.
  def self.extract_description_html(source_for_data, type: :article)
    description_content = nil
    source_for_data ||= {} # Ensure it's not nil, default to empty hash-like behavior if it is

    # source_for_data is expected to be a Hash (like document.data) or a Drop.
    # Both respond to ['key_name'].

    if type == :article
      description_content = source_for_data['description'] # Check front matter 'description' first
      # Fallback to excerpt only if 'description' is nil or an empty string after stripping
      if description_content.nil? || description_content.to_s.strip.empty?
        # source_for_data['excerpt'] on a DocumentDrop returns an ExcerptDrop.
        # source_for_data['excerpt'] on a document.data Hash returns a Jekyll::Excerpt object.
        excerpt_obj_or_drop = source_for_data['excerpt']
        if excerpt_obj_or_drop&.respond_to?(:output) # True for Jekyll::Excerpt
          description_content = excerpt_obj_or_drop.output
        elsif excerpt_obj_or_drop # It might be an ExcerptDrop, whose to_s is the output
          description_content = excerpt_obj_or_drop.to_s
        end
      end
    elsif type == :book
      # Books primarily use the excerpt for the card description
      excerpt_obj_or_drop = source_for_data['excerpt']
      if excerpt_obj_or_drop&.respond_to?(:output) # True for Jekyll::Excerpt
        description_content = excerpt_obj_or_drop.output
      elsif excerpt_obj_or_drop # Jekyll::Drops::ExcerptDrop
        description_content = excerpt_obj_or_drop.to_s
      end
    end
    # Ensure we return a string, stripping whitespace. If description_content is nil, .to_s gives ""
    description_content.to_s.strip
  end

end
