# frozen_string_literal: true

# _tests/plugins/utils/json_ld_generators/test_blog_posting_generator.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/utils/json_ld_generators/blog_posting_generator'

# Tests for BlogPostingLdGenerator module.
#
# Verifies that the generator correctly creates JSON-LD structured data for blog posts.
class TestBlogPostingLdGenerator < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://blog.example.com',
      'baseurl' => '',
      'author' => { 'name' => 'Test Author' }
    }
    @site = create_site(@site_config)
    @post_collection = MockCollection.new([], 'posts')
  end

  def test_generate_hash_basic_post
    doc = create_basic_post_doc
    expected = build_expected_basic_post_hash
    assert_equal expected, BlogPostingLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_excerpt_and_description
    doc = create_excerpt_and_description_doc
    expected = build_expected_excerpt_hash
    assert_equal expected, BlogPostingLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_description_no_excerpt
    doc = create_description_no_excerpt_doc
    expected = build_expected_description_hash
    assert_equal expected, BlogPostingLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_image_and_last_modified
    doc = create_image_and_modified_doc
    expected = build_expected_image_modified_hash
    assert_equal expected, BlogPostingLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_long_description_truncation
    doc = create_long_description_doc
    result_hash = BlogPostingLdGenerator.generate_hash(doc, @site)
    expected_truncated_desc = build_expected_truncated_description
    assert_equal expected_truncated_desc, result_hash['description']
    assert result_hash.key?('headline')
  end

  def test_generate_hash_minimal_data
    doc = create_minimal_doc
    actual_hash = BlogPostingLdGenerator.generate_hash(doc, @site)
    assert_minimal_hash_structure(actual_hash)
    assert_date_fields_present_and_valid(actual_hash)
    assert_expected_keys_only(actual_hash)
  end

  private

  def create_basic_post_doc
    create_doc(
      { 'layout' => 'post', 'title' => 'My First Post', 'categories' => ['Tech'] },
      '/tech/first-post.html',
      '<p>This is the main content.</p>',
      '2024-01-15 10:00:00 EST',
      @post_collection
    )
  end

  def build_expected_basic_post_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'BlogPosting',
      'headline' => 'My First Post',
      'author' => { '@type' => 'Person', 'name' => 'Test Author' },
      'publisher' => { '@type' => 'Person', 'name' => 'Test Author', 'url' => 'https://blog.example.com/' },
      'datePublished' => '2024-01-15T10:00:00-05:00',
      'dateModified' => '2024-01-15T10:00:00-05:00',
      'url' => 'https://blog.example.com/tech/first-post.html',
      'mainEntityOfPage' => {
        '@type' => 'WebPage',
        '@id' => 'https://blog.example.com/tech/first-post.html'
      },
      'articleBody' => 'This is the main content.',
      'keywords' => 'Tech'
    }
  end

  def create_excerpt_and_description_doc
    create_doc(
      {
        'layout' => 'post',
        'title' => 'Post With Excerpt',
        'excerpt_output_override' => '<p>This is the <strong>excerpt</strong>.</p>',
        'description' => 'This front matter description should be ignored for LD description.',
        'tags' => %w[Example Test]
      },
      '/test/excerpt-post.html',
      '<p>Full content here.</p>',
      '2024-02-10',
      @post_collection
    )
  end

  def build_expected_excerpt_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'BlogPosting',
      'headline' => 'Post With Excerpt',
      'author' => { '@type' => 'Person', 'name' => 'Test Author' },
      'publisher' => { '@type' => 'Person', 'name' => 'Test Author', 'url' => 'https://blog.example.com/' },
      'datePublished' => Time.parse('2024-02-10').xmlschema,
      'dateModified' => Time.parse('2024-02-10').xmlschema,
      'url' => 'https://blog.example.com/test/excerpt-post.html',
      'mainEntityOfPage' => {
        '@type' => 'WebPage',
        '@id' => 'https://blog.example.com/test/excerpt-post.html'
      },
      'description' => 'This is the excerpt.',
      'articleBody' => 'Full content here.',
      'keywords' => 'Example, Test'
    }
  end

  def create_description_no_excerpt_doc
    create_doc(
      {
        'layout' => 'post',
        'title' => 'Post With Description',
        'excerpt_output_override' => '',
        'description' => ' This is the <strong>description</strong> from front matter. ',
        'categories' => ['Info'],
        'tags' => ['Test']
      },
      '/test/desc-post.html',
      '<p>Main body.</p>',
      '2024-03-01',
      @post_collection
    )
  end

  def build_expected_description_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'BlogPosting',
      'headline' => 'Post With Description',
      'author' => { '@type' => 'Person', 'name' => 'Test Author' },
      'publisher' => { '@type' => 'Person', 'name' => 'Test Author', 'url' => 'https://blog.example.com/' },
      'datePublished' => Time.parse('2024-03-01').xmlschema,
      'dateModified' => Time.parse('2024-03-01').xmlschema,
      'url' => 'https://blog.example.com/test/desc-post.html',
      'mainEntityOfPage' => {
        '@type' => 'WebPage',
        '@id' => 'https://blog.example.com/test/desc-post.html'
      },
      'description' => 'This is the description from front matter.',
      'articleBody' => 'Main body.',
      'keywords' => 'Info, Test'
    }
  end

  def create_image_and_modified_doc
    create_doc(
      {
        'layout' => 'post',
        'title' => 'Updated Post',
        'image' => '/images/featured.png',
        'last_modified_at' => Time.parse('2024-04-01 12:00:00 UTC')
      },
      '/updates/updated-post.html',
      '<p>Updated content.</p>',
      '2024-03-15',
      @post_collection
    )
  end

  def build_expected_image_modified_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'BlogPosting',
      'headline' => 'Updated Post',
      'author' => { '@type' => 'Person', 'name' => 'Test Author' },
      'publisher' => { '@type' => 'Person', 'name' => 'Test Author', 'url' => 'https://blog.example.com/' },
      'datePublished' => Time.parse('2024-03-15').xmlschema,
      'dateModified' => '2024-04-01T12:00:00Z',
      'image' => { '@type' => 'ImageObject', 'url' => 'https://blog.example.com/images/featured.png' },
      'url' => 'https://blog.example.com/updates/updated-post.html',
      'mainEntityOfPage' => {
        '@type' => 'WebPage',
        '@id' => 'https://blog.example.com/updates/updated-post.html'
      },
      'articleBody' => 'Updated content.'
    }
  end

  def create_long_description_doc
    long_desc = 'Word ' * 60
    create_doc(
      {
        'layout' => 'post',
        'title' => 'Long Desc Post',
        'description' => "<p>#{long_desc}</p>"
      },
      '/test/long-desc.html',
      'Body',
      '2024-01-01',
      @post_collection
    )
  end

  def build_expected_truncated_description
    "#{'Word ' * 49}Word..."
  end

  def create_minimal_doc
    create_doc(
      { 'layout' => 'post', 'title' => 'Minimal' },
      '/minimal.html',
      '',
      nil,
      @post_collection
    )
  end

  def assert_minimal_hash_structure(actual_hash)
    expected_structure = {
      '@context' => 'https://schema.org',
      '@type' => 'BlogPosting',
      'headline' => 'Minimal',
      'author' => { '@type' => 'Person', 'name' => 'Test Author' },
      'publisher' => { '@type' => 'Person', 'name' => 'Test Author', 'url' => 'https://blog.example.com/' },
      'url' => 'https://blog.example.com/minimal.html',
      'mainEntityOfPage' => { '@type' => 'WebPage', '@id' => 'https://blog.example.com/minimal.html' }
    }

    expected_structure.each do |key, value|
      assert_equal value, actual_hash[key.to_s], "Mismatch for key '#{key}'"
    end
  end

  def assert_date_fields_present_and_valid(actual_hash)
    assert actual_hash.key?('datePublished'), 'Expected datePublished to be present'
    assert actual_hash.key?('dateModified'), 'Expected dateModified to be present'

    xml_schema_date_regex = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$/
    assert_match xml_schema_date_regex, actual_hash['datePublished']
    assert_match xml_schema_date_regex, actual_hash['dateModified']
  end

  def assert_expected_keys_only(actual_hash)
    expected_keys = [
      '@context', '@type', 'headline', 'author', 'publisher',
      'url', 'mainEntityOfPage', 'datePublished', 'dateModified'
    ]
    assert_equal expected_keys.sort, actual_hash.keys.sort, 'Hash keys do not match expected set'
  end
end
