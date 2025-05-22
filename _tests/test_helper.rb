# _tests/test_helper.rb
require 'minitest/autorun'
require 'jekyll'
require 'time' # Needed for Time.parse if mocking dates

# Add the parent _plugins directory to the load path
$LOAD_PATH.unshift(File.expand_path('../_plugins', __dir__))

# Explicitly require utils files
require 'utils/article_card_utils'
require 'utils/author_link_util'
require 'utils/backlink_utils'
require 'utils/book_card_utils'
require 'utils/book_link_util'
require 'utils/book_list_utils'
require 'utils/card_data_extractor_utils'
require 'utils/card_renderer_utils'
require 'utils/citation_utils'
require 'utils/json_ld_generators/author_profile_generator'
require 'utils/json_ld_generators/blog_posting_generator'
require 'utils/json_ld_generators/book_review_generator'
require 'utils/json_ld_generators/generic_review_generator'
require 'utils/json_ld_utils'
require 'utils/link_helper_utils'
require 'utils/plugin_logger_utils'
require 'utils/rating_utils'
require 'utils/series_link_util'
require 'utils/text_processing_utils'
require 'utils/url_utils'


# --- Mock Objects ---

# Simple mock for Jekyll documents (Posts, Pages, Collection Items)
MockDocument = Struct.new(:data, :url, :content, :date, :site, :collection) do
  # Provides hash-like access to document attributes and front matter.
  def [](key)
    key_s = key.to_s
    if key_s == 'url' then url
    elsif key_s == 'content' then content # Direct attribute for post-conversion body
    elsif key_s == 'date' then data['date'] # Access the date from the data hash for consistency with real Jekyll behavior
    elsif key_s == 'title' then data['title'] || data[:title] rescue nil # Allow symbol or string key for title
    elsif data&.key?(key_s) then data[key_s] # Check string key in data
    elsif data&.key?(key.to_sym) then data[key.to_sym] # Check symbol key in data
    else nil
    end
  end

  def respond_to?(method_name, include_private = false)
    # Ensure common document attributes and '[]' are reported as available.
    return true if %i[data url content date title site collection []].include?(method_name.to_sym)
    super
  end

  # Override is_a? to pretend to be a Jekyll::Document for checks
  # This allows testing code that uses `is_a?(Jekyll::Document)`
  define_method(:is_a?) do |klass|
    # Note: This is a simplification. A real Page is not a Document.
    # If your injector logic needs to differentiate Page vs Document beyond layout/collection,
    # this mock might need further refinement. For the current injector logic,
    # pretending all mocks are Documents might suffice where collection checks are needed.
    # However, the injector *also* checks `is_a?(Jekyll::Page)`.
    # Let's make it specific:
    if klass == Jekyll::Document
      # Pretend to be a Document *if* it has a collection assigned
      # This helps distinguish it from a Page mock which wouldn't have one.
      !collection.nil?
    elsif klass == Jekyll::Page
      # Pretend to be a Page *if* it does NOT have a collection assigned
      collection.nil?
    else
      super(klass) # Use standard is_a? for other types
    end
  end

  # Mock for generate_excerpt, not strictly needed if data['excerpt'] is directly mocked,
  # but included for completeness if any code calls it.
  def generate_excerpt(separator)
    # This is a very basic mock. Real excerpt generation is more complex.
    # For testing, usually data['excerpt'] (as a Struct with :output) is set directly.
  end
end

# Mock for site.collections['some_collection'] or site.posts
MockCollection = Struct.new(:docs, :label)

# Mock for the Jekyll site object
MockSite = Struct.new(:config, :collections, :pages, :posts, :baseurl, :source, :converters, :data) do
  # Mimics Jekyll's internal path joining for source files.
  def in_source_dir(path)
    File.join(source || '.', path)
  end

  # Mimics Jekyll's converter lookup.
  def find_converter_instance(klass_or_name)
    return nil unless converters
    converters.find do |c|
      klass_or_name.is_a?(Class) ? c.is_a?(klass_or_name) : c.class.name.match?(klass_or_name.to_s)
    end
  end
end

# --- Helper Methods ---

# Creates a Liquid context for testing tags and filters.
def create_context(scopes = {}, registers = {})
  Liquid::Context.new(scopes, {}, registers)
end

# Creates a MockSite instance with specified configurations and data.
def create_site(config_overrides = {}, collections_data = {}, pages_data = [], posts_data = [])
  # Default plugin logging states (all off unless overridden for a specific test).
  test_plugin_logging_config = {
    'ANY_TAG' => false,
    'ARTICLE_CARD_ALT_MISSING' => false,
    'ARTICLE_CARD_LOOKUP' => false,
    'ARTICLE_CARD_UTIL' => false,
    'AUTHOR_LINK' => false,
    'AUTHOR_LINK_UTIL_ERROR' => false,
    'BACKLINK_UTIL' => false,
    'BOOK_BACKLINKS_TAG' => false,
    'BOOK_CARD_GENERIC_ALT' => false,
    'BOOK_CARD_LOOKUP' => false,
    'BOOK_CARD_MISSING_EXCERPT' => false,
    'BOOK_CARD_MISSING_IMAGE_PATH' => false,
    'BOOK_CARD_MISSING_TITLE' => false,
    'BOOK_CARD_RATING_ERROR' => false,
    'BOOK_CARD_USER_ALT_MISSING' => false,
    'BOOK_CARD_UTIL' => false,
    'BOOK_LINK_UTIL_ERROR' => false,
    'BOOK_LIST_AUTHOR_DISPLAY' => false,
    'BOOK_LIST_SERIES_DISPLAY' => false,
    'BOOK_LIST_UTIL' => false,
    'CARD_DATA_EXTRACTION' => false,
    'DISPLAY_RANKED_BOOKS' => false,
    'JSON_LD_REVIEW' => false,
    'RELATED_BOOKS' => false,
    'RELATED_POSTS' => false,
    'RENDER_ARTICLE_CARD_TAG' => false,
    'RENDER_AUTHOR_LINK' => false,
    'RENDER_BOOK_CARD_TAG' => false,
    'RENDER_BOOK_LINK' => false,
    'RENDER_SERIES_LINK' => false,
    'SERIES_LINK' => false,
    'SERIES_LINK_UTIL_ERROR' => false,
    'UNITS_TAG_ERROR' => false,
    'UNITS_TAG_WARNING' => false,
  }

  base_config = {
    'environment' => 'test', 'baseurl' => '', 'source' => '.',
    'plugin_logging' => test_plugin_logging_config,
    'excerpt_separator' => "<!--excerpt-->" # Default excerpt separator
  }.merge(config_overrides)

  collections = {}
  collections_data.each do |name, docs_array|
    collections[name.to_s] = MockCollection.new(docs_array, name.to_s)
  end

  # Initialize posts_collection correctly with its label 'posts'.
  posts_collection = MockCollection.new(posts_data, 'posts')

  # Mock a basic Markdown converter instance.
  mock_markdown_converter = Class.new(Jekyll::Converter) do
    def initialize(config = {}) @config = config; end # Add initializer
    def matches(ext); ext.casecmp('.md').zero?; end
    def output_ext(ext); ".html"; end
    def convert(content); "<p>#{content.strip}</p>"; end # Simplified Markdown to HTML
  end.new(base_config)

  MockSite.new(
    base_config,
    collections,
    pages_data,
    posts_collection, # Use the correctly initialized posts_collection
    base_config['baseurl'],
    base_config['source'],
    [mock_markdown_converter], # List of converters
    {}, # site.data, can be populated if needed
  )
end

def create_doc(data_overrides = {}, url = '/test-doc.html', content_attr_val = 'Test content attribute.', date_str_param = nil, collection = nil)
  # Ensure all keys in data_overrides are strings for consistency.
  string_keyed_data_overrides = data_overrides.transform_keys(&:to_s)

  base_data = {
    'layout' => 'test_layout', 'title' => 'Test Document', 'published' => true,
    'path' => url ? url.sub(%r{^/}, '') : nil # Derive path from URL if URL is provided
  }.merge(string_keyed_data_overrides)

  # Determine the canonical Time object for the document's date.
  # Priority:
  # 1. If data_overrides['date'] is already a Time object.
  # 2. Parse date_str_param if provided.
  # 3. Default to Time.now.
  final_date_obj_for_struct = nil
  if base_data['date'].is_a?(Time)
    final_date_obj_for_struct = base_data['date']
  elsif date_str_param
    begin
      final_date_obj_for_struct = Time.parse(date_str_param.to_s)
    rescue ArgumentError
      final_date_obj_for_struct = Time.now # Fallback if date_str_param is unparseable
    end
  else
    final_date_obj_for_struct = Time.now # Default if no date information provided
  end

  # Ensure the 'date' in the data hash is this canonical Time object.
  base_data['date'] = final_date_obj_for_struct

  # Create the mock document. The 4th argument to MockDocument.new is its direct .date attribute.
  doc = MockDocument.new(base_data, url, content_attr_val, final_date_obj_for_struct, nil, collection)

  # Mock excerpt handling:
  # If 'excerpt_output_override' is provided, use it directly for excerpt.output.
  # If 'excerpt' is a string in data_overrides, wrap it in a Struct with an :output method.
  if base_data.key?('excerpt_output_override')
    excerpt_html_output = base_data.delete('excerpt_output_override')
    doc.data['excerpt'] = Struct.new(:output).new(excerpt_html_output)
  elsif base_data.key?('excerpt') && base_data['excerpt'].is_a?(String)
    string_excerpt_content = base_data['excerpt']
    doc.data['excerpt'] = Struct.new(:output).new(string_excerpt_content)
  end
  # If 'excerpt' in data_overrides is already a pre-mocked object (e.g., Struct with :output), it will be used.

  doc
end

puts "Expanded test helper loaded (with improved MockDocument and logging disabled)."
