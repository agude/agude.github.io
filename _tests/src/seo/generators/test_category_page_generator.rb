# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::SEO::Generators::CategoryPageLdGenerator module.
#
# Verifies that the generator correctly creates JSON-LD structured data for category pages.
class TestCategoryPageLdGenerator < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://alexgude.com',
      'baseurl' => '',
      'title' => 'Alex Gude',
      'author' => { 'name' => 'Alexander Gude' },
    }
  end

  def test_generate_hash_basic_category_page
    doc = create_category_page_doc(title: 'Data Science')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::CategoryPageLdGenerator.generate_hash(doc, site)

    assert_equal 'https://schema.org', result['@context']
    assert_equal 'CollectionPage', result['@type']
    assert_equal 'Data Science - Articles', result['name']
    assert_equal 'https://alexgude.com/topics/data-science/', result['url']
  end

  def test_generate_hash_includes_description
    doc = create_category_page_doc(
      title: 'Data Science',
      description: 'Articles about data science and machine learning.',
    )
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::CategoryPageLdGenerator.generate_hash(doc, site)

    assert_equal 'Articles about data science and machine learning.', result['description']
  end

  def test_generate_hash_includes_author
    doc = create_category_page_doc(title: 'Data Science')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::CategoryPageLdGenerator.generate_hash(doc, site)

    expected_author = { '@type' => 'Person', 'name' => 'Alexander Gude' }
    assert_equal expected_author, result['author']
  end

  def test_generate_hash_includes_is_part_of
    doc = create_category_page_doc(title: 'Data Science')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::CategoryPageLdGenerator.generate_hash(doc, site)

    expected_part_of = {
      '@type' => 'WebSite',
      'name' => 'Alex Gude',
      'url' => 'https://alexgude.com/',
    }
    assert_equal expected_part_of, result['isPartOf']
  end

  def test_generate_hash_without_description
    doc = create_category_page_doc(title: 'Data Science')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::CategoryPageLdGenerator.generate_hash(doc, site)

    refute result.key?('description'), 'Missing description should omit field'
  end

  def test_generate_hash_without_author
    config = @site_config.dup
    config.delete('author')
    doc = create_category_page_doc(title: 'Data Science')
    site = create_site(config)
    result = Jekyll::SEO::Generators::CategoryPageLdGenerator.generate_hash(doc, site)

    refute result.key?('author'), 'Missing author should omit field'
  end

  def test_generate_hash_uses_category_title
    doc = create_category_page_doc(title: 'Data Science', category_title: 'Data Science & ML')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::CategoryPageLdGenerator.generate_hash(doc, site)

    assert_equal 'Data Science & ML - Articles', result['name']
  end

  private

  def create_category_page_doc(title:, description: nil, category_title: nil)
    data = {
      'layout' => 'category',
      'title' => title,
    }
    data['description'] = description if description
    data['category-title'] = category_title if category_title

    create_doc(data, '/topics/data-science/', 'Category page content', nil, nil)
  end
end
