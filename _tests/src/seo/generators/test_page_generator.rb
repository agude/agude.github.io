# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::SEO::Generators::PageLdGenerator module.
#
# Verifies that the generator correctly creates JSON-LD structured data for
# generic pages (blog index, books index, papers, etc.).
class TestPageLdGenerator < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://alexgude.com',
      'baseurl' => '',
      'title' => 'Alex Gude',
      'author' => { 'name' => 'Alexander Gude' },
    }
  end

  def test_generate_hash_blog_index
    doc = create_page_doc(title: 'Writings', url: '/blog/')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::PageLdGenerator.generate_hash(doc, site)

    assert_equal 'https://schema.org', result['@context']
    assert_equal 'CollectionPage', result['@type']
    assert_equal 'Writings', result['name']
    assert_equal 'https://alexgude.com/blog/', result['url']
  end

  def test_generate_hash_books_index
    doc = create_page_doc(title: 'Book Reviews', url: '/books/')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::PageLdGenerator.generate_hash(doc, site)

    assert_equal 'CollectionPage', result['@type']
    assert_equal 'Book Reviews', result['name']
    assert_equal 'https://alexgude.com/books/', result['url']
  end

  def test_generate_hash_books_by_author
    doc = create_page_doc(title: 'Book Reviews: By Author', url: '/books/by-author/')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::PageLdGenerator.generate_hash(doc, site)

    assert_equal 'Book Reviews: By Author', result['name']
  end

  def test_generate_hash_papers
    doc = create_page_doc(
      title: 'Papers',
      url: '/papers/',
      description: 'Academic papers by Alexander Gude.',
    )
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::PageLdGenerator.generate_hash(doc, site)

    assert_equal 'Papers', result['name']
    assert_equal 'Academic papers by Alexander Gude.', result['description']
  end

  def test_generate_hash_includes_author
    doc = create_page_doc(title: 'Writings', url: '/blog/')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::PageLdGenerator.generate_hash(doc, site)

    expected_author = { '@type' => 'Person', 'name' => 'Alexander Gude' }
    assert_equal expected_author, result['author']
  end

  def test_generate_hash_includes_is_part_of
    doc = create_page_doc(title: 'Writings', url: '/blog/')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::PageLdGenerator.generate_hash(doc, site)

    expected_part_of = {
      '@type' => 'WebSite',
      'name' => 'Alex Gude',
      'url' => 'https://alexgude.com/',
    }
    assert_equal expected_part_of, result['isPartOf']
  end

  def test_generate_hash_without_description
    doc = create_page_doc(title: 'Writings', url: '/blog/')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::PageLdGenerator.generate_hash(doc, site)

    refute result.key?('description'), 'Missing description should omit field'
  end

  def test_generate_hash_without_author
    config = @site_config.dup
    config.delete('author')
    doc = create_page_doc(title: 'Writings', url: '/blog/')
    site = create_site(config)
    result = Jekyll::SEO::Generators::PageLdGenerator.generate_hash(doc, site)

    refute result.key?('author'), 'Missing author should omit field'
  end

  private

  def create_page_doc(title:, url:, description: nil)
    data = {
      'layout' => 'page',
      'title' => title,
    }
    data['description'] = description if description

    create_doc(data, url, 'Page content', nil, nil)
  end
end
