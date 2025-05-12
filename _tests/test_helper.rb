# _tests/test_helper.rb
require 'minitest/autorun'
require 'jekyll'
require 'time' # Needed for Time.parse if mocking dates

# Add the parent _plugins directory to the load path
$LOAD_PATH.unshift(File.expand_path('../_plugins', __dir__))

# Require the main utility file (will be removed as we empty it)
# require 'liquid_utils' # Comment out or remove as LiquidUtils gets emptied

# Explicitly require utils files
require 'utils/author_link_util'
require 'utils/backlink_utils'
require 'utils/book_link_util'
require 'utils/book_list_utils'
require 'utils/card_renderer_utils'
require 'utils/citation_utils.rb'
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
  def [](key)
    key_s = key.to_s
    if key_s == 'url' then url
    elsif key_s == 'content' then content # Direct attribute for post-conversion body
    elsif key_s == 'date' then date
    elsif key_s == 'title' then data['title'] || data[:title] rescue nil
      # For data['content'] to access raw front matter or pre-conversion content if needed
    elsif data&.key?(key_s) then data[key_s]
    elsif data&.key?(key.to_sym) then data[key.to_sym]
    else nil
    end
  end

  def respond_to?(method_name, include_private = false)
    # Add '[]' to the list of methods it responds to
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

  # generate_excerpt method is not strictly needed here if we directly mock data['excerpt']
  # but keeping it doesn't harm if it was intended for other uses.
  def generate_excerpt(separator)
    # This is a very basic mock.
  end
end

# Mock for site.collections['some_collection'] or site.posts
MockCollection = Struct.new(:docs, :label)

# Mock for site object
MockSite = Struct.new(:config, :collections, :pages, :posts, :baseurl, :source, :converters, :data) do
  def in_source_dir(path)
    File.join(source || '.', path)
  end
  def find_converter_instance(klass_or_name) # Allow finding by class or string name
    return nil unless converters
    converters.find do |c|
      klass_or_name.is_a?(Class) ? c.is_a?(klass_or_name) : c.class.name.match?(klass_or_name.to_s)
    end
  end
end

# --- Helper Methods ---

def create_context(scopes = {}, registers = {})
  Liquid::Context.new(scopes, {}, registers)
end

def create_site(config_overrides = {}, collections_data = {}, pages_data = [], posts_data = [])
  test_plugin_logging_config = {
    'ANY_TAG' => false,
    'ARTICLE_CARD_LOOKUP' => false,
    'AUTHOR_LINK' => false,
    'BACKLINK_UTIL' => false,
    'BOOK_BACKLINKS' => false,
    'BOOK_CARD_LOOKUP' => false,
    'BOOK_LIST_SERIES_DISPLAY' => false,
    'DISPLAY_RANKED_BOOKS' => false,
    'JSON_LD_REVIEW' => false,
    'RELATED_BOOKS' => false,
    'RELATED_POSTS' => false,
    'RENDER_AUTHOR_LINK' => false,
    'RENDER_BOOK_LINK' => false,
    'RENDER_SERIES_LINK' => false,
    'SERIES_LINK' => false,
    'UNITS_WARNING' => false,
  }

  base_config = {
    'environment' => 'test', 'baseurl' => '', 'source' => '.',
    'plugin_logging' => test_plugin_logging_config,
    'excerpt_separator' => "<!--excerpt-->" # Define a default separator
  }.merge(config_overrides)

  collections = {}
  collections_data.each do |name, docs_array|
    collections[name.to_s] = MockCollection.new(docs_array, name.to_s)
  end

  # Initialize posts_collection correctly with its label
  posts_collection = MockCollection.new(posts_data, 'posts')

  # Mock a basic Markdown converter
  mock_markdown_converter = Class.new(Jekyll::Converter) do
    def initialize(config = {}) @config = config; end # Add initializer
    def matches(ext); ext.casecmp('.md').zero?; end
    def output_ext(ext); ".html"; end
    def convert(content); "<p>#{content.strip}</p>"; end # Simplified conversion
  end.new(base_config)

  MockSite.new(
    base_config,
    collections,
    pages_data,
    posts_collection, # Use the correctly initialized posts_collection
    base_config['baseurl'],
    base_config['source'],
    [mock_markdown_converter],
    {},
  )
end

def create_doc(data_overrides = {}, url = '/test-doc.html', content_attr_val = 'Test content attribute.', date_str = nil, collection = nil)
  base_data = {
    'layout' => 'test_layout', 'title' => 'Test Document', 'published' => true,
    'path' => url ? url.sub(%r{^/}, '') : nil
  }.merge(data_overrides)

  date_obj = date_str ? Time.parse(date_str) : Time.now

  # The `content_attr_val` is for the `document.content` attribute (post-conversion HTML body)
  doc = MockDocument.new(base_data, url, content_attr_val, date_obj, nil, collection)

  # Simpler excerpt mocking - just needs an 'output' attribute
  # Uses duck typing check `respond_to?(:output)` in JsonLdUtils now.
  if base_data.key?('excerpt_output_override')
    excerpt_html_output = base_data.delete('excerpt_output_override')
    # Create a simple struct with an 'output' method
    doc.data['excerpt'] = Struct.new(:output).new(excerpt_html_output)
  elsif base_data.key?('excerpt') && base_data['excerpt'].is_a?(String)
    # If 'excerpt' is just a string in data_overrides, wrap it for consistency
    # so it has an 'output' method.
    string_excerpt_content = base_data['excerpt']
    doc.data['excerpt'] = Struct.new(:output).new(string_excerpt_content)
  end
  # If 'excerpt' in data_overrides is already a pre-mocked object (like a Struct with :output), it will be used directly.

  doc
end

puts "Expanded test helper loaded (with improved MockDocument and logging disabled)."
