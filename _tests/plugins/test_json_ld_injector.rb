# _tests/plugins/test_json_ld_injector.rb
require_relative '../test_helper'
require_relative '../../_plugins/json_ld_injector' # Load the injector class/module
require 'json' # For parsing JSON results
require 'minitest/mock' # For mocking logger

class TestJsonLdInjector < Minitest::Test

  def setup
    @site = create_site # Basic site config is usually enough

    # Mock Collections
    @posts_collection = MockCollection.new([], 'posts')
    @books_collection = MockCollection.new([], 'books')

    # --- Mock Documents ---
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
    @author_page_doc = create_doc( # Assuming author pages are regular pages (no collection needed here)
                                  { 'layout' => 'author_page', 'title' => 'Author Name' },
                                  '/authors/author.html', 'Author bio', nil, nil # Pass nil for collection
                                 )
    @other_page_doc = create_doc( # An unhandled page
                                 { 'layout' => 'default', 'title' => 'Other Page' },
                                 '/other.html', 'Other content', nil, nil
                                )

    # --- Expected Hashes (Simple examples) ---
    @blog_posting_hash = { "@type" => "BlogPosting", "headline" => "Standard Post" }
    @book_review_hash = { "@type" => "Review", "itemReviewed" => { "@type" => "Book" } }
    @generic_review_hash = { "@type" => "Review", "itemReviewed" => { "@type" => "Product", "name" => "Gadget V1" } }
    @author_profile_hash = { "@type" => "Person", "name" => "Author Name" }
  end

  # Helper to assert JSON script content
  def assert_json_script(document, expected_hash)
    script_tag = document.data['json_ld_script']
    refute_nil script_tag, "Expected json_ld_script to be set, but was nil"
    assert_match %r{<script type="application/ld\+json">}, script_tag
    # Extract JSON part - handle potential newlines carefully
    json_content = script_tag.match(%r{<script type="application/ld\+json">\s*(.*)\s*</script>}m)[1]
    assert_equal expected_hash, JSON.parse(json_content)
  end

  # Helper to assert no script was injected
  def assert_no_json_script(document)
    assert_nil document.data['json_ld_script'], "Expected json_ld_script to be nil, but it was set"
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
    assert_json_script(@blog_post_doc, @blog_posting_hash)
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
    assert_json_script(@book_review_doc, @book_review_hash)
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
    assert_json_script(@generic_review_post_doc, @generic_review_hash)
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
    assert_json_script(@author_page_doc, @author_profile_hash)
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
    assert_no_json_script(@generic_review_missing_item_doc)
    mock_logger.verify # Check that logger.warn was called as expected
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
    assert_no_json_script(@other_page_doc)
  end

  def test_skips_injection_if_generator_returns_nil
    # Test with a blog post, but make the generator return nil
    BlogPostingLdGenerator.stub :generate_hash, nil do # Return nil
      # No need to stub others to flunk here, as we expect BlogPosting to be called
      JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
    end
    assert_no_json_script(@blog_post_doc)
  end

  def test_skips_injection_if_generator_returns_empty_hash
    # Test with a blog post, but make the generator return {}
    BlogPostingLdGenerator.stub :generate_hash, {} do # Return empty hash
      JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
    end
    assert_no_json_script(@blog_post_doc)
  end

end
