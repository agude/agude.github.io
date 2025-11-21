# frozen_string_literal: true

# _tests/test_helper.rb
require 'minitest/autorun'
require 'jekyll'
require 'time' # Needed for Time.parse if mocking dates

# Add the parent _plugins directory to the load path
$LOAD_PATH.unshift(File.expand_path('../_plugins', __dir__))

# Explicitly require plugins and utils
require 'display_previous_reviews_tag'
require 'link_cache_generator'
require 'utils/article_card_utils'
require 'utils/author_link_util'
require 'utils/backlink_utils'
require 'utils/book_card_utils'
require 'utils/book_link_util'
require 'utils/book_list_utils'
require 'utils/card_data_extractor_utils'
require 'utils/card_renderer_utils'
require 'utils/citation_utils'
require 'utils/feed_utils'
require 'utils/front_matter_utils'
require 'utils/json_ld_generators/author_profile_generator'
require 'utils/json_ld_generators/blog_posting_generator'
require 'utils/json_ld_generators/book_review_generator'
require 'utils/json_ld_generators/generic_review_generator'
require 'utils/json_ld_utils'
require 'utils/link_helper_utils'
require 'utils/plugin_logger_utils'
require 'utils/post_list_utils'
require 'utils/rating_utils'
require 'utils/series_link_util'
require 'utils/series_text_utils'
require 'utils/short_story_link_util'
require 'utils/tag_argument_utils'
require 'utils/text_processing_utils'
require 'utils/typography_utils'
require 'utils/url_utils'

# --- Mock Objects ---

# Simple mock for Jekyll documents (Posts, Pages, Collection Items)
MockDocument = Struct.new(:data, :url, :content, :date, :site, :collection, :relative_path) do
  # Provides hash-like access to document attributes and front matter.
  def [](key)
    key_s = key.to_s
    lookup_special_key(key_s) || lookup_data_key(key_s, key)
  end

  def respond_to?(method_name, include_private = false)
    # Ensure common document attributes and '[]' are reported as available.
    return true if common_method_names.include?(method_name.to_sym)

    super
  end

  # Override is_a? to pretend to be a Jekyll::Document or Jekyll::Page for checks
  define_method(:is_a?) do |klass|
    if klass == Jekyll::Document
      # Pretend to be a Document if it has a collection assigned
      !collection.nil?
    elsif klass == Jekyll::Page
      # Pretend to be a Page if it does NOT have a collection assigned
      collection.nil?
    else
      super(klass)
    end
  end

  # Mock for generate_excerpt, not strictly needed if data['excerpt'] is directly mocked,
  # but included for completeness if any code calls it.
  def generate_excerpt(_separator)
    # This is a very basic mock. Real excerpt generation is more complex.
    # For testing, usually data['excerpt'] (as a Struct with :output) is set directly.
  end

  # Allow MockDocument to be treated as a Liquid Drop by responding to to_liquid
  def to_liquid
    self
  end

  private

  def lookup_special_key(key_s)
    case key_s
    when 'url' then url
    when 'content' then content
    when 'date' then data['date']
    when 'title'
      begin
        data['title'] || data[:title]
      rescue StandardError
        nil
      end
    end
  end

  def lookup_data_key(key_s, key_sym)
    return data[key_s] if data&.key?(key_s)
    return data[key_sym.to_sym] if data&.key?(key_sym.to_sym)

    nil
  end

  def common_method_names
    %i[data url content date title site collection [] to_liquid relative_path]
  end
end

# Mock for site.collections['some_collection'] or site.posts
MockCollection = Struct.new(:docs, :label)

# Mock for the Jekyll site object, now a full class for reliability.
class MockSite
  attr_accessor :config, :collections, :pages, :posts, :baseurl, :source, :converters, :data, :categories

  def initialize(config, collections, pages, posts, baseurl, source, converters, data, categories)
    @config = config
    @collections = collections
    @pages = pages
    @posts = posts
    @baseurl = baseurl
    @source = source
    @converters = converters
    @data = data
    @categories = categories
  end

  def documents
    collect_all_documents
  end

  def in_source_dir(path)
    File.join(source || '.', path)
  end

  def find_converter_instance(klass_or_name)
    return nil unless converters

    converters.find { |c| converter_matches?(c, klass_or_name) }
  end

  private

  def collect_all_documents
    all_docs = []
    all_docs.concat(posts.docs) if posts&.docs.is_a?(Array)
    collections&.each_value do |collection|
      all_docs.concat(collection.docs) if collection&.docs.is_a?(Array)
    end
    all_docs.uniq
  end

  def converter_matches?(converter, klass_or_name)
    if klass_or_name.is_a?(Class)
      converter.is_a?(klass_or_name)
    else
      converter.class.name.match?(klass_or_name.to_s)
    end
  end
end

# --- Helper Methods ---

# Creates a Liquid context for testing tags and filters.
def create_context(scopes = {}, registers = {})
  Liquid::Context.new(scopes, {}, registers)
end

# rubocop:disable Metrics/ParameterLists
def create_site(config_overrides = {}, collections_data = {}, pages_data = [],
                posts_data = [], categories_data = {})
  # rubocop:enable Metrics/ParameterLists
  base_config = build_test_site_config(config_overrides)
  collections = build_collections(collections_data)
  posts_collection = MockCollection.new(posts_data, 'posts')
  mock_markdown_converter = create_mock_converter(base_config)

  site = MockSite.new(
    base_config,
    collections,
    pages_data,
    posts_collection,
    base_config['baseurl'],
    base_config['source'],
    [mock_markdown_converter],
    {},
    categories_data
  )

  generate_link_cache(site)
  site
end

# rubocop:disable Metrics/ParameterLists
def create_doc(data_overrides = {}, url = '/test-doc.html', content_attr_val = 'Test content attribute.',
               date_str_param = nil, collection = nil)
  # rubocop:enable Metrics/ParameterLists
  string_keyed_data_overrides = data_overrides.transform_keys(&:to_s)
  base_data = build_base_doc_data(string_keyed_data_overrides, url)
  final_date_obj = parse_date_for_doc(base_data, date_str_param)
  base_data['date'] = final_date_obj

  doc = MockDocument.new(
    base_data,
    url,
    content_attr_val,
    final_date_obj,
    nil,
    collection,
    base_data['path']
  )

  setup_mock_excerpt(doc, base_data)
  doc
end

# --- Private Helper Methods ---

def build_test_site_config(config_overrides)
  {
    'environment' => 'test',
    'baseurl' => '',
    'source' => '.',
    'plugin_logging' => test_plugin_logging_config,
    'excerpt_separator' => '<!--excerpt-->',
    'plugin_log_level' => PluginLoggerUtils::DEFAULT_SITE_CONSOLE_LEVEL_STRING
  }.merge(config_overrides)
end

def test_plugin_logging_config
  {
    'ALL_BOOKS_BY_AUTHOR_DISPLAY' => false,
    'ALL_BOOKS_BY_AWARD_DISPLAY' => false,
    'ALL_BOOKS_BY_TITLE_ALPHA_GROUP' => false,
    'ALL_BOOKS_BY_YEAR_DISPLAY' => false,
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
    'DISPLAY_CATEGORY_POSTS' => false,
    'DISPLAY_RANKED_BOOKS' => false,
    'JSON_LD_REVIEW' => false,
    'POST_LIST_UTIL_CATEGORY' => false,
    'PREVIOUS_REVIEWS' => false,
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
    'UNITS_TAG_WARNING' => false
  }
end

def build_collections(collections_data)
  collections = {}
  collections_data.each do |name, docs_array|
    collections[name.to_s] = MockCollection.new(docs_array, name.to_s)
  end
  collections
end

def create_mock_converter(config)
  Class.new(Jekyll::Converter) do
    def initialize(config = {})
      super
      @config = config
    end

    def matches?(ext)
      ext.casecmp('.md').zero?
    end

    def output_ext(_ext)
      '.html'
    end

    def convert(content)
      "<p>#{content.strip}</p>"
    end
  end.new(config)
end

def generate_link_cache(site)
  silent_logger = Minitest::Mock.new
  4.times { silent_logger.expect :info, nil, [String, String] }

  Jekyll.stub :logger, silent_logger do
    Jekyll::LinkCacheGenerator.new.generate(site)
  end
end

def build_base_doc_data(string_keyed_data_overrides, url)
  {
    'layout' => 'test_layout',
    'title' => 'Test Document',
    'published' => true,
    'path' => url&.sub(%r{^/}, '')
  }.merge(string_keyed_data_overrides)
end

def parse_date_for_doc(base_data, date_str_param)
  return base_data['date'] if base_data['date'].is_a?(Time)

  if base_data['date'].is_a?(String)
    parse_date_string(base_data['date']) || parse_fallback_date(date_str_param)
  elsif date_str_param
    parse_date_string(date_str_param.to_s) || Time.now
  else
    Time.now
  end
end

def parse_date_string(date_str)
  Time.parse(date_str)
rescue ArgumentError
  nil
end

def parse_fallback_date(date_str_param)
  return Time.now unless date_str_param

  parse_date_string(date_str_param.to_s) || Time.now
end

def setup_mock_excerpt(doc, base_data)
  if base_data.key?('excerpt_output_override')
    excerpt_html_output = base_data.delete('excerpt_output_override')
    doc.data['excerpt'] = Struct.new(:output).new(excerpt_html_output)
  elsif base_data.key?('excerpt') && base_data['excerpt'].is_a?(String)
    string_excerpt_content = base_data['excerpt']
    doc.data['excerpt'] = Struct.new(:output).new(string_excerpt_content)
  end
end

puts 'Expanded test helper loaded (with improved MockDocument and logging disabled).'
