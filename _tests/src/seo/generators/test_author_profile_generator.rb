# frozen_string_literal: true

# _tests/plugins/utils/json_ld_generators/test_author_profile_generator.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/seo/generators/author_profile_generator' # Load the specific generator
require 'minitest/mock' # For mocking logger

# Tests for Jekyll::SEO::Generators::AuthorProfileLdGenerator module.
#
# Verifies that the generator correctly creates JSON-LD structured data for author profile pages.
class TestAuthorProfileLdGenerator < Minitest::Test
  def setup
    @site = create_site({ 'url' => 'https://mysite.dev', 'baseurl' => '' })
  end

  private

  # Helper to create expected base hash
  def expected_base_hash(name, url)
    {
      '@context' => 'https://schema.org',
      '@type' => 'Person',
      'name' => name,
      'url' => url
    }
  end

  # Helper to create expected hash with optional fields
  def expected_hash_with_fields(name, url, description: nil, same_as: nil, alternate_name: nil)
    hash = expected_base_hash(name, url)
    hash['description'] = description if description
    hash['sameAs'] = same_as if same_as
    hash['alternateName'] = alternate_name if alternate_name
    hash
  end

  public

  # --- Test Cases ---

  def test_generate_hash_basic
    doc = create_doc({ 'layout' => 'author_page', 'title' => 'Jane Doe' }, '/authors/jane-doe.html')
    expected = expected_base_hash('Jane Doe', 'https://mysite.dev/authors/jane-doe.html')
    assert_equal expected, Jekyll::SEO::Generators::AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_same_as_urls
    doc = create_doc(
      {
        'layout' => 'author_page', 'title' => 'Jane Doe',
        'same_as_urls' => ['https://twitter.com/janedoe', ' https://linkedin.com/in/janedoe ', nil, '']
      },
      '/authors/jane-doe.html'
    )
    expected = expected_hash_with_fields('Jane Doe', 'https://mysite.dev/authors/jane-doe.html',
                                         same_as: ['https://twitter.com/janedoe', 'https://linkedin.com/in/janedoe'])
    assert_equal expected, Jekyll::SEO::Generators::AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_pen_names
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Canonical Name',
        'pen_names' => ['Pen Name One', '  Pen Name Two  ', nil, ''] },
      '/authors/canonical.html'
    )
    expected = expected_hash_with_fields('Canonical Name', 'https://mysite.dev/authors/canonical.html',
                                         alternate_name: ['Pen Name One', 'Pen Name Two'])
    assert_equal expected, Jekyll::SEO::Generators::AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_all_fields
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Jane Doe', 'description' => 'An author bio.',
        'same_as_urls' => ['https://example.com/jane'], 'pen_names' => ['J.D.'] },
      '/authors/jane-doe.html'
    )
    expected = expected_hash_with_fields('Jane Doe', 'https://mysite.dev/authors/jane-doe.html',
                                         description: 'An author bio.', same_as: ['https://example.com/jane'],
                                         alternate_name: ['J.D.'])
    assert_equal expected, Jekyll::SEO::Generators::AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_empty_same_as_urls
    doc = create_doc({ 'layout' => 'author_page', 'title' => 'Jane Doe', 'same_as_urls' => [] },
                     '/authors/jane-doe.html')
    expected = expected_base_hash('Jane Doe', 'https://mysite.dev/authors/jane-doe.html')
    assert_equal expected, Jekyll::SEO::Generators::AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_nil_same_as_urls
    doc = create_doc({ 'layout' => 'author_page', 'title' => 'Jane Doe', 'same_as_urls' => nil },
                     '/authors/jane-doe.html')
    expected = expected_base_hash('Jane Doe', 'https://mysite.dev/authors/jane-doe.html')
    assert_equal expected, Jekyll::SEO::Generators::AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_description
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Jane Doe', 'description' => ' An author bio. ' },
      '/authors/jane-doe.html'
    )
    expected = expected_hash_with_fields('Jane Doe', 'https://mysite.dev/authors/jane-doe.html',
                                         description: 'An author bio.')
    assert_equal expected, Jekyll::SEO::Generators::AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_excerpt
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Jane Doe', 'excerpt_output_override' => '<p>Excerpt bio.</p>' },
      '/authors/jane-doe.html'
    )
    expected = expected_hash_with_fields('Jane Doe', 'https://mysite.dev/authors/jane-doe.html',
                                         description: 'Excerpt bio.')
    assert_equal expected, Jekyll::SEO::Generators::AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_excerpt_and_description_priority
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Jane Doe', 'excerpt_output_override' => '<p>Excerpt bio.</p>',
        'description' => 'This should be ignored.' },
      '/authors/jane-doe.html'
    )
    expected = expected_hash_with_fields('Jane Doe', 'https://mysite.dev/authors/jane-doe.html',
                                         description: 'Excerpt bio.')
    assert_equal expected, Jekyll::SEO::Generators::AuthorProfileLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_skips_invalid_same_as_urls_type_and_logs
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Jane Doe', 'same_as_urls' => 'not-an-array' },
      '/authors/jane-doe.html'
    )
    expected = expected_base_hash('Jane Doe', 'https://mysite.dev/authors/jane-doe.html')

    # Mock logger
    mock_logger = Minitest::Mock.new
    mock_logger.expect(:warn, nil) do |prefix, message|
      prefix == 'JSON-LD:' && message.include?('not an Array') && message.include?(doc.url)
    end

    actual_hash = nil
    Jekyll.stub :logger, mock_logger do
      actual_hash = Jekyll::SEO::Generators::AuthorProfileLdGenerator.generate_hash(doc, @site)
    end

    assert_equal expected, actual_hash
    mock_logger.verify
  end

  def test_generate_hash_omits_empty_fields
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => ' ', 'description' => '', 'same_as_urls' => [], 'pen_names' => [] },
      '/authors/empty.html'
    )
    # Only context, type, and URL should remain
    expected = {
      '@context' => 'https://schema.org',
      '@type' => 'Person',
      'url' => 'https://mysite.dev/authors/empty.html'
    }
    assert_equal expected, Jekyll::SEO::Generators::AuthorProfileLdGenerator.generate_hash(doc, @site)
  end
end
