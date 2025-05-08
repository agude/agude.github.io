# _tests/plugins/utils/json_ld_generators/test_author_profile_generator.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/utils/json_ld_generators/author_profile_generator' # Load the specific generator
require 'minitest/mock' # For mocking logger

class TestAuthorProfileLdGenerator < Minitest::Test

  def setup
    @site = create_site({ 'url' => 'https://mysite.dev', 'baseurl' => '' })
  end

  # --- Test Cases ---

  def test_generate_hash_basic
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Jane Doe' },
      '/authors/jane-doe.html'
    )
    expected = {
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => "Jane Doe",
      "url" => "https://mysite.dev/authors/jane-doe.html"
    }
    assert_equal expected, AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_same_as_urls
    doc = create_doc(
      {
        'layout' => 'author_page', 'title' => 'Jane Doe',
        'same_as_urls' => [
          "https://twitter.com/janedoe",
          " https://linkedin.com/in/janedoe ", # With whitespace
          nil, # Should be ignored
          ""   # Should be ignored
        ]
      },
      '/authors/jane-doe.html'
    )
    expected = {
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => "Jane Doe",
      "url" => "https://mysite.dev/authors/jane-doe.html",
      "sameAs" => [
        "https://twitter.com/janedoe",
        "https://linkedin.com/in/janedoe"
      ]
    }
    assert_equal expected, AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_empty_same_as_urls
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Jane Doe', 'same_as_urls' => [] },
      '/authors/jane-doe.html'
    )
    expected = {
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => "Jane Doe",
      "url" => "https://mysite.dev/authors/jane-doe.html"
      # No sameAs key
    }
    assert_equal expected, AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_nil_same_as_urls
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Jane Doe', 'same_as_urls' => nil },
      '/authors/jane-doe.html'
    )
    expected = {
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => "Jane Doe",
      "url" => "https://mysite.dev/authors/jane-doe.html"
      # No sameAs key
    }
    assert_equal expected, AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_description
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Jane Doe', 'description' => ' An author bio. ' },
      '/authors/jane-doe.html'
    )
    expected = {
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => "Jane Doe",
      "url" => "https://mysite.dev/authors/jane-doe.html",
      "description" => "An author bio." # Cleaned by extract_descriptive_text
    }
    assert_equal expected, AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_excerpt
    # Use the override mechanism from test_helper
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Jane Doe', 'excerpt_output_override' => '<p>Excerpt bio.</p>' },
      '/authors/jane-doe.html'
    )
    expected = {
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => "Jane Doe",
      "url" => "https://mysite.dev/authors/jane-doe.html",
      "description" => "Excerpt bio." # Cleaned from excerpt
    }
    assert_equal expected, AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_excerpt_and_description_priority
    # Excerpt should take priority
    doc = create_doc(
      {
        'layout' => 'author_page', 'title' => 'Jane Doe',
        'excerpt_output_override' => '<p>Excerpt bio.</p>',
        'description' => 'This should be ignored.'
      },
      '/authors/jane-doe.html'
    )
    expected = {
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => "Jane Doe",
      "url" => "https://mysite.dev/authors/jane-doe.html",
      "description" => "Excerpt bio." # Excerpt wins
    }
    assert_equal expected, AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_skips_invalid_same_as_urls_type_and_logs
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Jane Doe', 'same_as_urls' => "not-an-array" },
      '/authors/jane-doe.html'
    )
    expected = { # sameAs should be omitted
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => "Jane Doe",
      "url" => "https://mysite.dev/authors/jane-doe.html"
    }

    # Mock logger
    mock_logger = Minitest::Mock.new
    mock_logger.expect(:warn, nil) do |prefix, message|
      prefix == "JSON-LD:" && message.include?("not an Array") && message.include?(doc.url)
    end

    actual_hash = nil
    Jekyll.stub :logger, mock_logger do
      actual_hash = AuthorProfileLdGenerator.generate_hash(doc, @site)
    end

    assert_equal expected, actual_hash
    mock_logger.verify
  end

  def test_generate_hash_omits_empty_fields
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => ' ', 'description' => '', 'same_as_urls' => [] },
      '/authors/empty.html'
    )
    expected = { # Only context, type, and URL should remain
      "@context" => "https://schema.org",
      "@type" => "Person",
      "url" => "https://mysite.dev/authors/empty.html"
    }
    assert_equal expected, AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

end
