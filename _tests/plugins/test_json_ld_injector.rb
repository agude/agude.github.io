# frozen_string_literal: true

# _tests/plugins/test_json_ld_injector.rb
require_relative '../test_helper'
require_relative '../../_plugins/json_ld_injector'
require 'json'
require 'minitest/mock'

require 'utils/json_ld_generators/blog_posting_generator'
require 'utils/json_ld_generators/book_review_generator'
require 'utils/json_ld_generators/generic_review_generator'
require 'utils/json_ld_generators/author_profile_generator'

# Base test class with shared setup and helpers for JsonLdInjector tests.
#
# Provides common setup and helper methods for testing JSON-LD injection.
class TestJsonLdInjectorBase < Minitest::Test
  def setup
    @site = create_site
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
      '/blog/standard.html', 'Blog content', nil, @posts_collection
    )
    @book_review_doc = create_doc(
      { 'layout' => 'book', 'title' => 'Book Review' },
      '/books/review.html', 'Book review content', nil, @books_collection
    )
    @generic_review_post_doc = create_doc(
      { 'layout' => 'post', 'title' => 'Generic Review', 'review' => { 'item_name' => 'Gadget V1' } },
      '/blog/generic.html', 'Generic review content', nil, @posts_collection
    )
    @generic_review_missing_item_doc = create_doc(
      { 'layout' => 'post', 'title' => 'Generic Review Missing', 'review' => {} },
      '/blog/generic-missing.html', 'Generic review missing content', nil, @posts_collection
    )
    @author_page_doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Author Name' },
      '/authors/author.html', 'Author bio', nil, nil
    )
    @other_page_doc = create_doc(
      { 'layout' => 'default', 'title' => 'Other Page' },
      '/other.html', 'Other content', nil, nil
    )
  end

  def setup_expected_hashes
    @blog_posting_hash = { '@type' => 'BlogPosting', 'headline' => 'Standard Post', 'test_marker' => 'blog' }
    @book_review_hash = { '@type' => 'Review', 'itemReviewed' => { '@type' => 'Book' }, 'test_marker' => 'book' }
    @generic_review_hash = {
      '@type' => 'Review',
      'itemReviewed' => { '@type' => 'Product', 'name' => 'Gadget V1' },
      'test_marker' => 'generic'
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
      BlogPostingLdGenerator => @blog_posting_hash,
      BookReviewLdGenerator => @book_review_hash,
      GenericReviewLdGenerator => @generic_review_hash,
      AuthorProfileLdGenerator => @author_profile_hash
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
    stub_with_active_generator(BlogPostingLdGenerator, @blog_posting_hash) do
      JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
    end
    assert_json_script(@blog_post_doc, @site, @blog_posting_hash)
  end

  def test_injects_for_book_review
    stub_with_active_generator(BookReviewLdGenerator, @book_review_hash) do
      JsonLdInjector.inject_json_ld(@book_review_doc, @site)
    end
    assert_json_script(@book_review_doc, @site, @book_review_hash)
  end

  def test_injects_for_generic_review_post
    stub_with_active_generator(GenericReviewLdGenerator, @generic_review_hash) do
      JsonLdInjector.inject_json_ld(@generic_review_post_doc, @site)
    end
    assert_json_script(@generic_review_post_doc, @site, @generic_review_hash)
  end

  def test_injects_for_author_page
    stub_with_active_generator(AuthorProfileLdGenerator, @author_profile_hash) do
      JsonLdInjector.inject_json_ld(@author_page_doc, @site)
    end
    assert_json_script(@author_page_doc, @site, @author_profile_hash)
  end

  private

  def stub_with_active_generator(active_generator, active_hash, &block)
    BlogPostingLdGenerator.stub :generate_hash, stub_value_for(BlogPostingLdGenerator, active_generator, active_hash) do
      BookReviewLdGenerator.stub :generate_hash, stub_value_for(BookReviewLdGenerator, active_generator, active_hash) do
        GenericReviewLdGenerator.stub :generate_hash,
                                      stub_value_for(GenericReviewLdGenerator, active_generator, active_hash) do
          AuthorProfileLdGenerator.stub :generate_hash,
                                        stub_value_for(AuthorProfileLdGenerator, active_generator, active_hash), &block
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
        JsonLdInjector.inject_json_ld(@generic_review_missing_item_doc, @site)
      end
    end

    assert_no_json_script(@generic_review_missing_item_doc, @site)
    mock_logger.verify
  end

  def test_skips_injection_for_unhandled_layout
    stub_all_generators_to_flunk do
      JsonLdInjector.inject_json_ld(@other_page_doc, @site)
    end
    assert_no_json_script(@other_page_doc, @site)
  end

  def test_skips_injection_if_generator_returns_nil
    BlogPostingLdGenerator.stub :generate_hash, nil do
      JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
    end
    assert_no_json_script(@blog_post_doc, @site)
  end

  def test_skips_injection_if_generator_returns_empty_hash
    BlogPostingLdGenerator.stub :generate_hash, {} do
      JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
    end
    assert_no_json_script(@blog_post_doc, @site)
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
    BlogPostingLdGenerator.stub :generate_hash, ->(*) { flunk 'BlogPosting generator should not be called' } do
      BookReviewLdGenerator.stub :generate_hash, ->(*) { flunk 'BookReview generator should not be called' } do
        GenericReviewLdGenerator.stub :generate_hash, ->(*) { flunk 'GenericReview generator should not be called' } do
          AuthorProfileLdGenerator.stub :generate_hash, lambda { |*|
            flunk 'AuthorProfile generator should not be called'
          }, &block
        end
      end
    end
  end
end
