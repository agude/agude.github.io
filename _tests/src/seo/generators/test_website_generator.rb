# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::SEO::Generators::WebsiteLdGenerator module.
#
# Verifies that the generator correctly creates JSON-LD structured data for the homepage.
class TestWebsiteLdGenerator < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://alexgude.com',
      'baseurl' => '',
      'title' => 'Alex Gude',
      'tagline' => 'Data Scientist',
      'description' => 'A blog about technology, data science, and more!',
      'author' => { 'name' => 'Alexander Gude', 'url' => '/resume/' },
    }
  end

  def test_generate_hash_basic_homepage
    doc = create_homepage_doc
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::WebsiteLdGenerator.generate_hash(doc, site)

    assert_equal 'https://schema.org', result['@context']
    assert_equal 'WebSite', result['@type']
    assert_equal 'Alex Gude', result['name']
    assert_equal 'https://alexgude.com/', result['url']
    assert_equal 'A blog about technology, data science, and more!', result['description']
  end

  # isPartOf on every other page references this node by the same @id.
  def test_generate_hash_has_website_id
    doc = create_homepage_doc
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::WebsiteLdGenerator.generate_hash(doc, site)

    assert_equal 'https://alexgude.com/#website', result['@id']
  end

  # Google's site-name markup recommends alternateName on the home page
  # WebSite node. config `name` ("AlexGude.com") is the site's alternate name.
  def test_generate_hash_includes_alternate_name_from_config_name
    doc = create_homepage_doc
    site = create_site(@site_config.merge('name' => 'AlexGude.com'))
    result = Jekyll::SEO::Generators::WebsiteLdGenerator.generate_hash(doc, site)

    assert_equal 'AlexGude.com', result['alternateName']
  end

  def test_generate_hash_without_config_name_omits_alternate_name
    doc = create_homepage_doc
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::WebsiteLdGenerator.generate_hash(doc, site)

    refute result.key?('alternateName')
  end

  def test_generate_hash_includes_author
    doc = create_homepage_doc
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::WebsiteLdGenerator.generate_hash(doc, site)

    expected_author = { '@type' => 'Person', 'name' => 'Alexander Gude', '@id' => 'https://alexgude.com/resume/#person', 'url' => 'https://alexgude.com/resume/' }
    assert_equal expected_author, result['author']
  end

  def test_generate_hash_includes_publisher
    doc = create_homepage_doc
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::WebsiteLdGenerator.generate_hash(doc, site)

    expected_publisher = {
      '@type' => 'Person',
      'name' => 'Alexander Gude',
      '@id' => 'https://alexgude.com/resume/#person',
      'url' => 'https://alexgude.com/resume/',
    }
    assert_equal expected_publisher, result['publisher']
  end

  def test_generate_hash_without_description
    config = @site_config.dup
    config.delete('description')
    doc = create_homepage_doc
    site = create_site(config)
    result = Jekyll::SEO::Generators::WebsiteLdGenerator.generate_hash(doc, site)

    refute result.key?('description'), 'Missing description should omit field'
  end

  def test_generate_hash_without_author
    config = @site_config.dup
    config.delete('author')
    doc = create_homepage_doc
    site = create_site(config)
    result = Jekyll::SEO::Generators::WebsiteLdGenerator.generate_hash(doc, site)

    refute result.key?('author'), 'Missing author should omit field'
    refute result.key?('publisher'), 'Missing author should omit publisher'
  end

  def test_generate_hash_without_site_title
    config = @site_config.dup
    config.delete('title')
    doc = create_homepage_doc
    site = create_site(config)
    result = Jekyll::SEO::Generators::WebsiteLdGenerator.generate_hash(doc, site)

    refute result.key?('name'), 'Missing title should omit name'
  end

  private

  def create_homepage_doc
    data = {
      'layout' => 'default',
      'title' => 'Home',
    }
    create_doc(data, '/', 'Homepage content', nil, nil)
  end
end
