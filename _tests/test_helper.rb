# _plugins/tests/test_helper.rb
require 'minitest/autorun'
require 'jekyll'
require 'time' # Needed for Time.parse if mocking dates

# Add the parent _plugins directory to the load path
$LOAD_PATH.unshift(File.expand_path('../_plugins', __dir__))

# Require the main utility file
require 'liquid_utils'
# Explicitly require utils files
require 'utils/link_helper_utils' # Load shared helpers first
require 'utils/author_link_util'
require 'utils/book_link_util'
require 'utils/series_link_util'
# Add requires for other future util files here...


# --- Mock Objects ---

# Simple mock for Jekyll documents (Posts, Pages, Collection Items)
MockDocument = Struct.new(:data, :url, :content, :date) do
  # Allow accessing data via string or symbol keys, AND specific attributes like 'url'
  def [](key)
    key_s = key.to_s
    # Prioritize direct attributes if key matches common names
    if key_s == 'url'
      url
    elsif key_s == 'content'
      content
    elsif key_s == 'date'
      date
    elsif key_s == 'title'
       data['title'] || data[:title] rescue nil
    else
      # Fallback to data hash (check string/symbol)
      data[key_s] || data[key.to_sym] rescue nil
    end
  end

  # Mimic respond_to? for common attributes if needed by plugins
  def respond_to?(method_name, include_private = false)
    # Add '[]' to the list of methods it responds to
    return true if %i[data url content date title []].include?(method_name.to_sym)
    super
  end
end

# Mock for site.collections['some_collection'] or site.posts
MockCollection = Struct.new(:docs)

# Mock for site object
MockSite = Struct.new(:config, :collections, :pages, :posts, :baseurl, :source) do
  # Mock method used by tags loading includes (though less relevant for utils)
  def in_source_dir(path)
     File.join(source || '.', path)
  end
end

# --- Helper Methods ---

# Creates a Liquid context with optional site/page registers
def create_context(scopes = {}, registers = {})
  Liquid::Context.new(scopes, {}, registers) # Environment, Outer Scope, Registers
end

# Creates a mock site object with default and override configurations
# Disables plugin logging by default for tests.
def create_site(config_overrides = {}, collections_data = {}, pages_data = [], posts_data = [])

  # --- Configuration to disable logging for known tags ---
  # List all tag_type strings used in log_failure calls across your plugins/utils
  test_plugin_logging_config = {
    'ARTICLE_CARD_LOOKUP' => false,
    'AUTHOR_LINK' => false,
    'BOOK_BACKLINKS' => false,
    'BOOK_CARD_LOOKUP' => false,
    'DISPLAY_RANKED_BOOKS' => false,
    'RELATED_BOOKS' => false,
    'RELATED_POSTS' => false,
    'RENDER_AUTHOR_LINK' => false,
    'RENDER_BOOK_LINK' => false,
    'RENDER_SERIES_LINK' => false,
    'SERIES_LINK' => false,
    'UNITS_WARNING' => false,
    # Add any other tag types used by {% log_failure %} here if needed
    # Used in the tests only:
    'ANY_TAG' => false,
  }


  # Base config including defaults our utils might check
  base_config = {
    'environment' => 'test', # Keep environment as test for other potential checks
    'baseurl' => '',
    'source' => '.', # Assume source is current dir for tests
    # --- Use the disabling config ---
    'plugin_logging' => test_plugin_logging_config
  }.merge(config_overrides) # Allow test-specific overrides if needed

  # Mock collections
  collections = {}
  collections_data.each do |name, docs_array|
    collections[name.to_s] = MockCollection.new(docs_array)
  end

  # Mock posts
  posts_collection = MockCollection.new(posts_data)

  MockSite.new(
    base_config,
    collections,
    pages_data, # Array of MockDocument for pages
    posts_collection, # MockCollection for posts
    base_config['baseurl'],
    base_config['source']
  )
end

# Creates a mock document (page, post, book)
def create_doc(data_overrides = {}, url = '/test-doc.html', content = 'Test content.', date_str = nil)
  base_data = {
    'layout' => 'test_layout',
    'title' => 'Test Document',
    'published' => true,
    # Only set path if url is not nil
    'path' => url ? url.sub(%r{^/}, '') : nil
  }.merge(data_overrides)

  date_obj = date_str ? Time.parse(date_str) : Time.now

  MockDocument.new(base_data, url, content, date_obj)
end


puts "Expanded test helper loaded (with improved MockDocument and logging disabled)."
