# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::SEO::Generators::WebPageLdGenerator
class TestWebPageLdGenerator < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://example.com',
      'baseurl' => '',
      'title' => 'Test Site',
      'author' => { 'name' => 'Test Author' },
    }
    @site = create_site(@site_config)
  end

  def test_generates_web_page_type
    doc = create_doc({ 'title' => 'Sample Code', 'layout' => 'page-not-on-sidebar' }, '/files/sample.html')
    result = Jekyll::SEO::Generators::WebPageLdGenerator.generate_hash(doc, @site)

    assert_equal 'https://schema.org', result['@context']
    assert_equal 'WebPage', result['@type']
  end

  def test_includes_name_from_title
    doc = create_doc({ 'title' => 'LLM Prompt Example', 'layout' => 'page-not-on-sidebar' }, '/files/prompt.html')
    result = Jekyll::SEO::Generators::WebPageLdGenerator.generate_hash(doc, @site)

    assert_equal 'LLM Prompt Example', result['name']
  end

  def test_includes_absolute_url
    doc = create_doc({ 'title' => 'Results', 'layout' => 'page-not-on-sidebar' }, '/files/sat2vec/results.html')
    result = Jekyll::SEO::Generators::WebPageLdGenerator.generate_hash(doc, @site)

    assert_equal 'https://example.com/files/sat2vec/results.html', result['url']
  end

  def test_includes_description_when_present
    doc = create_doc(
      {
        'title' => 'Code Sample',
        'description' => 'Example code from the blog post.',
        'layout' => 'page-not-on-sidebar',
      },
      '/files/code.html',
    )
    result = Jekyll::SEO::Generators::WebPageLdGenerator.generate_hash(doc, @site)

    assert_equal 'Example code from the blog post.', result['description']
  end

  def test_includes_site_author
    doc = create_doc({ 'title' => 'Sample', 'layout' => 'page-not-on-sidebar' }, '/files/sample.html')
    result = Jekyll::SEO::Generators::WebPageLdGenerator.generate_hash(doc, @site)

    assert_equal({ '@type' => 'Person', 'name' => 'Test Author' }, result['author'])
  end

  def test_includes_is_part_of_website
    doc = create_doc({ 'title' => 'Sample', 'layout' => 'page-not-on-sidebar' }, '/files/sample.html')
    result = Jekyll::SEO::Generators::WebPageLdGenerator.generate_hash(doc, @site)

    expected = {
      '@type' => 'WebSite',
      'name' => 'Test Site',
      'url' => 'https://example.com/',
    }
    assert_equal expected, result['isPartOf']
  end
end
