# _tests/plugins/test_json_ld_injector.rb
require_relative '../test_helper'
require_relative '../../_plugins/json_ld_injector' # Load the injector class/module
require 'json' # For parsing JSON results
require 'minitest/mock' # For mocking logger

# Ensure the real generators are loaded via test_helper.rb's requires:
require 'utils/json_ld_generators/blog_posting_generator'
require 'utils/json_ld_generators/book_review_generator'
require 'utils/json_ld_generators/generic_review_generator'
require 'utils/json_ld_generators/author_profile_generator'

class TestJsonLdInjector < Minitest::Test

  def setup
    # Create a site instance for each test to ensure clean site.data
    @site = create_site

    # Mock Collections
    @posts_collection = MockCollection.new([], 'posts')
    @books_collection = MockCollection.new([], 'books')

    # --- Mock Documents ---
    # Pass the relevant collection to create_doc
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
      { 'layout' => 'post', 'title' => 'Generic Review Missing', 'review' => {} }, # Missing item_name
      '/blog/generic-missing.html', 'Generic review missing content', nil, @posts_collection
    )
    # Author pages are regular pages, pass nil for collection
    @author_page_doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Author Name' },
      '/authors/author.html', 'Author bio', nil, nil
    )
    @other_page_doc = create_doc( # An unhandled page
                                 { 'layout' => 'default', 'title' => 'Other Page' },
                                 '/other.html', 'Other content', nil, nil
                                )

    # --- Expected Hashes (Simple examples used by stubs) ---
    @blog_posting_hash = { "@type" => "BlogPosting", "headline" => "Standard Post", "test_marker" => "blog" }
    @book_review_hash = { "@type" => "Review", "itemReviewed" => { "@type" => "Book" }, "test_marker" => "book" }
    @generic_review_hash = { "@type" => "Review", "itemReviewed" => { "@type" => "Product", "name" => "Gadget V1" }, "test_marker" => "generic" }
    @author_profile_hash = { "@type" => "Person", "name" => "Author Name", "test_marker" => "author" }
  end

  # Helper to assert JSON script content stored in site.data
  def assert_json_script(document, site, expected_hash)
    lookup_url = document.url
    refute_nil lookup_url, "Document URL is nil, cannot look up script."

    script_storage = site.data['generated_json_ld_scripts']
    refute_nil script_storage, "site.data['generated_json_ld_scripts'] hash does not exist."

    script_tag = script_storage[lookup_url]
    refute_nil script_tag, "Expected json_ld_script to be set for URL '#{lookup_url}', but was nil in site.data"

    assert_match %r{<script type="application/ld\+json">}, script_tag, "Script tag opening not found"
    assert_match %r{</script>}, script_tag, "Script tag closing not found"

    # Extract JSON part - handle potential newlines carefully
    match_data = script_tag.match(%r{<script type="application/ld\+json">\s*(.*)\s*</script>}m)
    refute_nil match_data, "Could not extract JSON content from script tag: #{script_tag.inspect}"
    json_content = match_data[1]

    begin
      parsed_json = JSON.parse(json_content)
      assert_equal expected_hash, parsed_json
    rescue JSON::ParserError => e
      flunk "Failed to parse JSON content: #{e.message}\nContent was:\n#{json_content}"
    end
  end

  # Helper to assert no script was injected into site.data
  def assert_no_json_script(document, site)
    lookup_url = document.url
    script_storage = site.data['generated_json_ld_scripts']
    # It's okay if script_storage is nil or doesn't contain the key
    script_present = script_storage && lookup_url && script_storage.key?(lookup_url)
    refute script_present, "Expected no json_ld_script for URL '#{lookup_url}', but found one in site.data"
  end

  # --- Test Cases ---

  def test_injects_for_standard_blog_post
    # Stub the correct generator, flunk others
    BlogPostingLdGenerator.stub :generate_hash, @blog_posting_hash do
      BookReviewLdGenerator.stub :generate_hash, ->(*) { flunk "BookReview generator should not be called" } do
        GenericReviewLdGenerator.stub :generate_hash, ->(*) { flunk "GenericReview generator should not be called" } do
          AuthorProfileLdGenerator.stub :generate_hash, ->(*) { flunk "AuthorProfile generator should not be called" } do
            JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
          end
        end
      end
    end
    assert_json_script(@blog_post_doc, @site, @blog_posting_hash)
  end

  def test_injects_for_book_review
    BookReviewLdGenerator.stub :generate_hash, @book_review_hash do
      BlogPostingLdGenerator.stub :generate_hash, ->(*) { flunk "BlogPosting generator should not be called" } do
        GenericReviewLdGenerator.stub :generate_hash, ->(*) { flunk "GenericReview generator should not be called" } do
          AuthorProfileLdGenerator.stub :generate_hash, ->(*) { flunk "AuthorProfile generator should not be called" } do
            JsonLdInjector.inject_json_ld(@book_review_doc, @site)
          end
        end
      end
    end
    assert_json_script(@book_review_doc, @site, @book_review_hash)
  end

  def test_injects_for_generic_review_post
    GenericReviewLdGenerator.stub :generate_hash, @generic_review_hash do
      BlogPostingLdGenerator.stub :generate_hash, ->(*) { flunk "BlogPosting generator should not be called" } do
        BookReviewLdGenerator.stub :generate_hash, ->(*) { flunk "BookReview generator should not be called" } do
          AuthorProfileLdGenerator.stub :generate_hash, ->(*) { flunk "AuthorProfile generator should not be called" } do
            JsonLdInjector.inject_json_ld(@generic_review_post_doc, @site)
          end
        end
      end
    end
    assert_json_script(@generic_review_post_doc, @site, @generic_review_hash)
  end

  def test_injects_for_author_page
    AuthorProfileLdGenerator.stub :generate_hash, @author_profile_hash do
      BlogPostingLdGenerator.stub :generate_hash, ->(*) { flunk "BlogPosting generator should not be called" } do
        BookReviewLdGenerator.stub :generate_hash, ->(*) { flunk "BookReview generator should not be called" } do
          GenericReviewLdGenerator.stub :generate_hash, ->(*) { flunk "GenericReview generator should not be called" } do
            JsonLdInjector.inject_json_ld(@author_page_doc, @site)
          end
        end
      end
    end
    assert_json_script(@author_page_doc, @site, @author_profile_hash)
  end

  def test_skips_injection_for_generic_review_missing_item_name
    # Mock Jekyll.logger.warn
    mock_logger = Minitest::Mock.new
    # Expect 'warn' to be called once with specific arguments (or use regex/matchers)
    # We expect 2 arguments: the prefix "JSON-LD:" and a message containing the identifier.
    mock_logger.expect(:warn, nil) do |prefix, message|
      prefix == "JSON-LD:" && message.include?("Missing 'review.item_name'") && message.include?(@generic_review_missing_item_doc.url)
    end

    # Stub all generators to flunk if called
    BlogPostingLdGenerator.stub :generate_hash, ->(*) { flunk "BlogPosting generator should not be called" } do
      BookReviewLdGenerator.stub :generate_hash, ->(*) { flunk "BookReview generator should not be called" } do
        GenericReviewLdGenerator.stub :generate_hash, ->(*) { flunk "GenericReview generator should not be called" } do
          AuthorProfileLdGenerator.stub :generate_hash, ->(*) { flunk "AuthorProfile generator should not be called" } do
            # Stub Jekyll.logger while calling the injector
            Jekyll.stub :logger, mock_logger do
              JsonLdInjector.inject_json_ld(@generic_review_missing_item_doc, @site)
            end
          end
        end
      end
    end

    # Verify no script was injected and logger was called
    assert_no_json_script(@generic_review_missing_item_doc, @site)
    mock_logger.verify
  end

  def test_skips_injection_for_unhandled_layout
    # Stub all generators to flunk if called
    BlogPostingLdGenerator.stub :generate_hash, ->(*) { flunk "BlogPosting generator should not be called" } do
      BookReviewLdGenerator.stub :generate_hash, ->(*) { flunk "BookReview generator should not be called" } do
        GenericReviewLdGenerator.stub :generate_hash, ->(*) { flunk "GenericReview generator should not be called" } do
          AuthorProfileLdGenerator.stub :generate_hash, ->(*) { flunk "AuthorProfile generator should not be called" } do
            JsonLdInjector.inject_json_ld(@other_page_doc, @site)
          end
        end
      end
    end
    assert_no_json_script(@other_page_doc, @site)
  end

  def test_skips_injection_if_generator_returns_nil
    # Test with a blog post, but make the generator return nil
    BlogPostingLdGenerator.stub :generate_hash, nil do # Return nil
      # No need to stub others to flunk here, as we expect BlogPosting to be called
      JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
    end
    assert_no_json_script(@blog_post_doc, @site)
  end

  def test_skips_injection_if_generator_returns_empty_hash
    # Test with a blog post, but make the generator return {}
    BlogPostingLdGenerator.stub :generate_hash, {} do # Return empty hash
      JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
    end
    assert_no_json_script(@blog_post_doc, @site)
  end

end
