# frozen_string_literal: true

# _tests/plugins/test_json_ld_injector.rb
require_relative '../../test_helper'
require_relative '../../../_plugins/src/seo/json_ld_injector'
require 'json'
require 'minitest/mock'

require 'src/seo/generators/blog_posting_generator'
require 'src/seo/generators/book_review_generator'
require 'src/seo/generators/generic_review_generator'
require 'src/seo/generators/author_profile_generator'
require 'src/seo/generators/page_generator'
require 'src/seo/generators/web_page_generator'

# Base test class with shared setup and helpers for Jekyll::SEO::JsonLdInjector tests.
#
# Provides common setup and helper methods for testing JSON-LD injection.
class TestJsonLdInjectorBase < Minitest::Test
  def setup
    @site = create_site
    # Ensure MockSite responds to show_drafts for stubbing and plugin logic
    unless @site.respond_to?(:show_drafts)
      def @site.show_drafts
        config['show_drafts']
      end
    end

    setup_collections
    setup_mock_documents
    setup_expected_hashes
  end

  def assert_json_script(document, site, expected_hash)
    script_tag = get_script_tag_for_document(document, site)
    json_content = extract_json_from_script(script_tag)
    assert_parsed_json_matches(json_content, expected_hash)
  end

  def assert_no_json_script(document, site)
    lookup_url = document.url
    script_storage = site.data['generated_json_ld_scripts']
    script_present = script_storage && lookup_url && script_storage.key?(lookup_url)
    refute script_present, "Expected no json_ld_script for URL '#{lookup_url}', but found one in site.data"
  end

  private

  def setup_collections
    @posts_collection = MockCollection.new([], 'posts')
    @books_collection = MockCollection.new([], 'books')
  end

  def setup_mock_documents
    @blog_post_doc = create_doc(
      { 'layout' => 'post', 'title' => 'Standard Post' },
      '/blog/standard.html',
      'Blog content',
      nil,
      @posts_collection,
    )
    @blog_post_doc.site = @site

    @book_review_doc = create_doc(
      { 'layout' => 'book', 'title' => 'Book Review' },
      '/books/review.html',
      'Book review content',
      nil,
      @books_collection,
    )
    @book_review_doc.site = @site

    @generic_review_post_doc = create_doc(
      { 'layout' => 'post', 'title' => 'Generic Review', 'review' => { 'item_name' => 'Gadget V1' } },
      '/blog/generic.html',
      'Generic review content',
      nil,
      @posts_collection,
    )
    @generic_review_post_doc.site = @site

    @generic_review_missing_item_doc = create_doc(
      { 'layout' => 'post', 'title' => 'Generic Review Missing', 'review' => {} },
      '/blog/generic-missing.html',
      'Generic review missing content',
      nil,
      @posts_collection,
    )
    @generic_review_missing_item_doc.site = @site

    @author_page_doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Author Name' },
      '/authors/author.html',
      'Author bio',
      nil,
      nil,
    )
    @author_page_doc.site = @site

    @other_page_doc = create_doc(
      { 'layout' => 'default', 'title' => 'Other Page' },
      '/other.html',
      'Other content',
      nil,
      nil,
    )
    @other_page_doc.site = @site
  end

  def setup_expected_hashes
    @blog_posting_hash = { '@type' => 'BlogPosting', 'headline' => 'Standard Post', 'test_marker' => 'blog' }
    @book_review_hash = { '@type' => 'Review', 'itemReviewed' => { '@type' => 'Book' }, 'test_marker' => 'book' }
    @generic_review_hash = {
      '@type' => 'Review',
      'itemReviewed' => { '@type' => 'Product', 'name' => 'Gadget V1' },
      'test_marker' => 'generic',
    }
    @author_profile_hash = { '@type' => 'Person', 'name' => 'Author Name', 'test_marker' => 'author' }
  end

  def get_script_tag_for_document(document, site)
    lookup_url = document.url
    refute_nil lookup_url, 'Document URL is nil, cannot look up script.'

    script_storage = site.data['generated_json_ld_scripts']
    refute_nil script_storage, "site.data['generated_json_ld_scripts'] hash does not exist."

    script_tag = script_storage[lookup_url]
    refute_nil script_tag, "Expected json_ld_script to be set for URL '#{lookup_url}', but was nil in site.data"

    verify_script_tag_structure(script_tag)
    script_tag
  end

  def verify_script_tag_structure(script_tag)
    assert_match %r{<script type="application/ld\+json">}, script_tag, 'Script tag opening not found'
    assert_match %r{</script>}, script_tag, 'Script tag closing not found'
  end

  def extract_json_from_script(script_tag)
    match_data = script_tag.match(%r{<script type="application/ld\+json">\s*(.*)\s*</script>}m)
    refute_nil match_data, "Could not extract JSON content from script tag: #{script_tag.inspect}"
    match_data[1]
  end

  def assert_parsed_json_matches(json_content, expected_hash)
    parsed_json = JSON.parse(json_content)
    assert_equal expected_hash, parsed_json
  rescue JSON::ParserError => e
    flunk "Failed to parse JSON content: #{e.message}\nContent was:\n#{json_content}"
  end

  def stub_all_generators_except(active_generator, active_hash)
    stubs = {
      Jekyll::SEO::Generators::BlogPostingLdGenerator => @blog_posting_hash,
      Jekyll::SEO::Generators::BookReviewLdGenerator => @book_review_hash,
      Jekyll::SEO::Generators::GenericReviewLdGenerator => @generic_review_hash,
      Jekyll::SEO::Generators::AuthorProfileLdGenerator => @author_profile_hash,
    }

    stubs.each_key do |generator|
      stub_value = generator == active_generator ? active_hash : ->(*) { flunk "#{generator} should not be called" }
      generator.stub :generate_hash, stub_value do
        yield if generator == stubs.keys.last
      end
    end
  end
end

# Tests for successful JSON-LD injection into documents.
#
# Verifies that the injector correctly generates and stores JSON-LD scripts.
class TestJsonLdInjectorInjection < TestJsonLdInjectorBase
  def test_injects_for_standard_blog_post
    stub_with_active_generator(Jekyll::SEO::Generators::BlogPostingLdGenerator, @blog_posting_hash) do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
    end
    assert_json_script(@blog_post_doc, @site, @blog_posting_hash)
  end

  def test_injects_for_book_review
    stub_with_active_generator(Jekyll::SEO::Generators::BookReviewLdGenerator, @book_review_hash) do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(@book_review_doc, @site)
    end
    assert_json_script(@book_review_doc, @site, @book_review_hash)
  end

  def test_injects_for_generic_review_post
    stub_with_active_generator(Jekyll::SEO::Generators::GenericReviewLdGenerator, @generic_review_hash) do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(@generic_review_post_doc, @site)
    end
    assert_json_script(@generic_review_post_doc, @site, @generic_review_hash)
  end

  def test_injects_for_author_page
    stub_with_active_generator(Jekyll::SEO::Generators::AuthorProfileLdGenerator, @author_profile_hash) do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(@author_page_doc, @site)
    end
    assert_json_script(@author_page_doc, @site, @author_profile_hash)
  end

  private

  def stub_with_active_generator(active_generator, active_hash, &block)
    Jekyll::SEO::Generators::BlogPostingLdGenerator.stub :generate_hash, stub_value_for(Jekyll::SEO::Generators::BlogPostingLdGenerator, active_generator, active_hash) do
      Jekyll::SEO::Generators::BookReviewLdGenerator.stub :generate_hash, stub_value_for(Jekyll::SEO::Generators::BookReviewLdGenerator, active_generator, active_hash) do
        Jekyll::SEO::Generators::GenericReviewLdGenerator.stub :generate_hash,
                                                               stub_value_for(Jekyll::SEO::Generators::GenericReviewLdGenerator, active_generator, active_hash) do
          Jekyll::SEO::Generators::AuthorProfileLdGenerator.stub :generate_hash,
                                                                 stub_value_for(Jekyll::SEO::Generators::AuthorProfileLdGenerator, active_generator, active_hash),
                                                                 &block
        end
      end
    end
  end

  def stub_value_for(generator, active_generator, active_hash)
    if generator == active_generator
      active_hash
    else
      ->(*) { flunk "#{generator} should not be called" }
    end
  end
end

# Tests for skipped injection scenarios where JSON-LD shouldn't be generated.
#
# Verifies that the injector correctly skips invalid or inappropriate documents.
class TestJsonLdInjectorSkip < TestJsonLdInjectorBase
  def test_skips_injection_for_generic_review_missing_item_name
    mock_logger = create_warning_logger_mock
    stub_all_generators_to_flunk do
      Jekyll.stub :logger, mock_logger do
        Jekyll::SEO::JsonLdInjector.inject_json_ld(@generic_review_missing_item_doc, @site)
      end
    end

    assert_no_json_script(@generic_review_missing_item_doc, @site)
    mock_logger.verify
  end

  def test_skips_injection_for_unhandled_layout
    stub_all_generators_to_flunk do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(@other_page_doc, @site)
    end
    assert_no_json_script(@other_page_doc, @site)
  end

  def test_skips_injection_if_generator_returns_nil
    Jekyll::SEO::Generators::BlogPostingLdGenerator.stub :generate_hash, nil do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
    end
    assert_no_json_script(@blog_post_doc, @site)
  end

  def test_skips_injection_if_generator_returns_empty_hash
    Jekyll::SEO::Generators::BlogPostingLdGenerator.stub :generate_hash, {} do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
    end
    assert_no_json_script(@blog_post_doc, @site)
  end

  def test_skips_injection_for_document_without_url
    # Create doc with all URL-related fields nil/empty
    doc_no_url = MockDocument.new(
      { 'layout' => 'post', 'title' => 'No URL Post', 'published' => true },
      nil, # url
      'Content',
      Time.now,
      @site,
      @posts_collection,
      nil, # relative_path
    )

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:warn, nil) do |prefix, message|
      prefix == 'JSON-LD:' && message.include?('Skipping LD injection for document without URL')
    end

    stub_all_generators_to_flunk do
      Jekyll.stub :logger, mock_logger do
        Jekyll::SEO::JsonLdInjector.inject_json_ld(doc_no_url, @site)
      end
    end

    assert_no_json_script(doc_no_url, @site)
    mock_logger.verify
  end

  def test_skips_injection_for_document_with_empty_url
    doc_empty_url = create_doc(
      { 'layout' => 'post', 'title' => 'Empty URL Post' },
      '', # URL is empty string
      'Content',
      nil,
      @posts_collection,
    )
    doc_empty_url.site = @site

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:warn, nil) do |prefix, message|
      prefix == 'JSON-LD:' && message.include?('Skipping LD injection for document without URL')
    end

    stub_all_generators_to_flunk do
      Jekyll.stub :logger, mock_logger do
        Jekyll::SEO::JsonLdInjector.inject_json_ld(doc_empty_url, @site)
      end
    end

    assert_no_json_script(doc_empty_url, @site)
    mock_logger.verify
  end

  def test_handles_json_generation_error
    # Create a hash that will cause JSON.pretty_generate to raise an error
    invalid_hash = { '@type' => 'BlogPosting', 'invalid' => Float::INFINITY }

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:debug, nil, ['JSON-LD Type:', String])
    mock_logger.expect(:error, nil) do |prefix, message|
      prefix == 'JSON-LD:' && message.include?('Failed to generate JSON')
    end

    Jekyll::SEO::Generators::BlogPostingLdGenerator.stub :generate_hash, invalid_hash do
      Jekyll.stub :logger, mock_logger do
        Jekyll::SEO::JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
      end
    end

    # Verify no script was stored due to the error
    assert_no_json_script(@blog_post_doc, @site)
    mock_logger.verify
  end

  private

  def create_warning_logger_mock
    mock = Minitest::Mock.new
    mock.expect(:warn, nil) do |prefix, message|
      prefix == 'JSON-LD:' && message.include?("Missing 'review.item_name'") &&
        message.include?(@generic_review_missing_item_doc.url)
    end
    mock
  end

  def stub_all_generators_to_flunk(&block)
    Jekyll::SEO::Generators::BlogPostingLdGenerator.stub :generate_hash, ->(*) { flunk 'BlogPosting generator should not be called' } do
      Jekyll::SEO::Generators::BookReviewLdGenerator.stub :generate_hash, ->(*) { flunk 'BookReview generator should not be called' } do
        Jekyll::SEO::Generators::GenericReviewLdGenerator.stub :generate_hash, ->(*) { flunk 'GenericReview generator should not be called' } do
          Jekyll::SEO::Generators::AuthorProfileLdGenerator.stub :generate_hash,
                                                                 lambda { |*|
                                                                   flunk 'AuthorProfile generator should not be called'
                                                                 },
                                                                 &block
        end
      end
    end
  end
end

# Tests for edge cases with non-Document objects (Pages, etc.).
#
# Verifies that type checkers correctly handle objects which are
# not Jekyll::Document instances (triggers else branches in type checkers).
class TestJsonLdInjectorNonDocuments < TestJsonLdInjectorBase
  # Struct to mimic Jekyll::Page behavior (not a Jekyll::Document)
  PageLike = Struct.new(:data, :url, :path, :relative_path)

  def test_handles_page_like_object_with_matching_layout
    # Create a page-like object (not a Jekyll::Document)
    author_page = PageLike.new(
      { 'layout' => 'author_page', 'title' => 'Page Author' },
      '/authors/page-author.html',
      'authors/page-author.html',
      'authors/page-author.html',
    )

    # Jekyll::SEO::Generators::AuthorProfileLdGenerator should be called since layout matches
    mock_hash = { '@type' => 'Person', 'name' => 'Page Author' }
    mock_logger = Minitest::Mock.new
    mock_logger.expect(:debug, nil, ['JSON-LD Type:', String])

    Jekyll::SEO::Generators::AuthorProfileLdGenerator.stub :generate_hash, mock_hash do
      Jekyll.stub :logger, mock_logger do
        Jekyll::SEO::JsonLdInjector.inject_json_ld(author_page, @site)
      end
    end

    # Should have generated script for this page
    assert_json_script(author_page, @site, mock_hash)
    mock_logger.verify
  end

  def test_handles_page_like_object_with_no_matching_layout
    # Create a page-like object with a layout that doesn't match any generator
    regular_page = PageLike.new(
      { 'layout' => 'default', 'title' => 'Regular Page' },
      '/regular.html',
      'regular.html',
      'regular.html',
    )

    # No generator should be called
    stub_all_generators_to_flunk do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(regular_page, @site)
    end

    # Should not have generated script
    assert_no_json_script(regular_page, @site)
  end

  private

  def stub_all_generators_to_flunk(&block)
    Jekyll::SEO::Generators::BlogPostingLdGenerator.stub :generate_hash, ->(*) { flunk 'BlogPosting generator should not be called' } do
      Jekyll::SEO::Generators::BookReviewLdGenerator.stub :generate_hash, ->(*) { flunk 'BookReview generator should not be called' } do
        Jekyll::SEO::Generators::GenericReviewLdGenerator.stub :generate_hash, ->(*) { flunk 'GenericReview generator should not be called' } do
          Jekyll::SEO::Generators::AuthorProfileLdGenerator.stub :generate_hash,
                                                                 lambda { |*|
                                                                   flunk 'AuthorProfile generator should not be called'
                                                                 },
                                                                 &block
        end
      end
    end
  end
end

# Tests for Jekyll Hooks registration and execution.
#
# Verifies that the plugin correctly registers and handles Jekyll hooks
# for site reset, document processing, and page processing.
class TestJsonLdInjectorHooks < TestJsonLdInjectorBase
  def test_site_after_reset_hook_initializes_storage
    # Clear existing storage to verify hook re-initializes it
    @site.data.delete('generated_json_ld_scripts')

    Jekyll::Hooks.trigger(:site, :after_reset, @site)

    assert @site.data.key?('generated_json_ld_scripts'),
           "Expected 'generated_json_ld_scripts' to be initialized in site.data"
    assert_equal({}, @site.data['generated_json_ld_scripts'])
  end

  def test_documents_post_convert_hook_injects_json_ld
    # Verify that the hook calls inject_json_ld (evidenced by script generation)
    Jekyll::SEO::Generators::BlogPostingLdGenerator.stub :generate_hash, @blog_posting_hash do
      Jekyll::Hooks.trigger(:documents, :post_convert, @blog_post_doc)
    end

    assert_json_script(@blog_post_doc, @site, @blog_posting_hash)
  end

  def test_documents_post_convert_hook_skips_static_files
    static_file = Jekyll::StaticFile.new(@site, @site.source, 'assets', 'image.jpg')

    # Should not raise error
    Jekyll::Hooks.trigger(:documents, :post_convert, static_file)

    # Verify no script storage was created for a static file (it wouldn't have a URL key in the same way)
  end

  def test_documents_post_convert_hook_skips_drafts_when_disabled
    # Create a draft document
    draft_doc = create_doc(
      { 'layout' => 'post', 'title' => 'Draft Post' },
      '/drafts/post.html',
      'Draft content',
      nil,
      @posts_collection,
    )
    draft_doc.site = @site

    # Mock draft? to return true
    draft_doc.define_singleton_method(:draft?) { true }

    # Force site.show_drafts to false
    @site.stub :show_drafts, false do
      Jekyll::Hooks.trigger(:documents, :post_convert, draft_doc)
    end

    assert_no_json_script(draft_doc, @site)
  end

  def test_documents_post_convert_hook_logs_error_when_site_missing
    # Create document with nil site
    doc_no_site = MockDocument.new(
      { 'layout' => 'post' }, '/no-site.html', 'Content', Time.now, nil, @posts_collection, 'no-site.html',
    )

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil) do |prefix, message|
      prefix == 'JSON-LD Hook:' && message.include?('Site object not available')
    end

    Jekyll.stub :logger, mock_logger do
      Jekyll::Hooks.trigger(:documents, :post_convert, doc_no_site)
    end

    mock_logger.verify
  end

  def test_pages_post_convert_hook_injects_json_ld
    # Create a page-like object that responds to :site
    page_struct = Struct.new(:site, :data, :url, :path, :relative_path)
    page = page_struct.new(
      @site,
      { 'layout' => 'author_page', 'title' => 'Page Author' },
      '/page-author.html',
      'page-author.html',
      'page-author.html',
    )

    Jekyll::SEO::Generators::AuthorProfileLdGenerator.stub :generate_hash, @author_profile_hash do
      Jekyll::Hooks.trigger(:pages, :post_convert, page)
    end

    assert_json_script(page, @site, @author_profile_hash)
  end

  def test_pages_post_convert_hook_skips_static_files
    static_file = Jekyll::StaticFile.new(@site, @site.source, 'assets', 'style.css')
    Jekyll::Hooks.trigger(:pages, :post_convert, static_file)
  end

  def test_pages_post_convert_hook_logs_error_when_site_missing
    # Page without site
    page_no_site_struct = Struct.new(:site, :data, :url, :relative_path)
    page_no_site = page_no_site_struct.new(
      nil,
      { 'layout' => 'page' },
      '/no-site-page.html',
      'no-site-page.html',
    )

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil) do |prefix, message|
      prefix == 'JSON-LD Hook:' && message.include?('Site object not available')
    end

    Jekyll.stub :logger, mock_logger do
      Jekyll::Hooks.trigger(:pages, :post_convert, page_no_site)
    end

    mock_logger.verify
  end
end

# Tests for page layout routing (page, page-not-on-sidebar, supplementary files).
#
# Verifies that different page types are routed to the correct generators.
class TestJsonLdInjectorPageRouting < TestJsonLdInjectorBase
  def setup
    super
    @page_hash = { '@type' => 'CollectionPage', 'name' => 'Test Page' }
    @web_page_hash = { '@type' => 'WebPage', 'name' => 'Supplementary Content' }
  end

  def test_routes_page_layout_to_page_generator
    page_doc = create_page_like(
      { 'layout' => 'page', 'title' => 'Book Reviews' },
      '/books/index.html',
    )

    Jekyll::SEO::Generators::PageLdGenerator.stub :generate_hash, @page_hash do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(page_doc, @site)
    end

    assert_json_script(page_doc, @site, @page_hash)
  end

  def test_routes_page_not_on_sidebar_to_page_generator
    topics_page = create_page_like(
      { 'layout' => 'page-not-on-sidebar', 'title' => 'Topics' },
      '/topics/index.html',
    )

    Jekyll::SEO::Generators::PageLdGenerator.stub :generate_hash, @page_hash do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(topics_page, @site)
    end

    assert_json_script(topics_page, @site, @page_hash)
  end

  def test_routes_files_page_to_web_page_generator
    supplementary_page = create_page_like(
      { 'layout' => 'page-not-on-sidebar', 'title' => 'Code Sample' },
      '/blog/sample-code.html',
      'files/sample-code.md',
    )

    Jekyll::SEO::Generators::WebPageLdGenerator.stub :generate_hash, @web_page_hash do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(supplementary_page, @site)
    end

    assert_json_script(supplementary_page, @site, @web_page_hash)
  end

  def test_routes_nested_files_page_to_web_page_generator
    nested_page = create_page_like(
      { 'layout' => 'page-not-on-sidebar', 'title' => 'SAT2VEC Results' },
      '/blog/sat2vec/results.html',
      'files/sat2vec/results.md',
    )

    Jekyll::SEO::Generators::WebPageLdGenerator.stub :generate_hash, @web_page_hash do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(nested_page, @site)
    end

    assert_json_script(nested_page, @site, @web_page_hash)
  end

  def test_files_with_page_layout_routes_to_web_page_generator
    files_page = create_page_like(
      { 'layout' => 'page', 'title' => 'Embedded Data' },
      '/blog/data.html',
      'files/data.md',
    )

    Jekyll::SEO::Generators::WebPageLdGenerator.stub :generate_hash, @web_page_hash do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(files_page, @site)
    end

    assert_json_script(files_page, @site, @web_page_hash)
  end

  private

  def create_page_like(data, url, source_path = nil)
    page_struct = Struct.new(:site, :data, :url, :path, :relative_path)
    path = source_path || url.delete_prefix('/')
    page_struct.new(@site, data, url, path, path)
  end
end
