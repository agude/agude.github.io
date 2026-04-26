# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::SEO::Generators::SeriesPageLdGenerator module.
#
# Verifies that the generator correctly creates JSON-LD structured data for series pages.
class TestSeriesPageLdGenerator < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://alexgude.com',
      'baseurl' => '',
      'title' => 'Alex Gude',
      'author' => { 'name' => 'Alexander Gude' },
    }
  end

  def test_generate_hash_basic_series_page
    doc = create_series_page_doc(title: 'Bobiverse')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::SeriesPageLdGenerator.generate_hash(doc, site)

    assert_equal 'https://schema.org', result['@context']
    assert_equal 'CollectionPage', result['@type']
    assert_equal 'Bobiverse - Book Reviews', result['name']
    assert_equal 'https://alexgude.com/books/series/bobiverse/', result['url']
  end

  def test_generate_hash_includes_description
    doc = create_series_page_doc(
      title: 'Bobiverse',
      description: 'Reviews of the Bobiverse series by Dennis E. Taylor.',
    )
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::SeriesPageLdGenerator.generate_hash(doc, site)

    assert_equal 'Reviews of the Bobiverse series by Dennis E. Taylor.', result['description']
  end

  def test_generate_hash_includes_about_book_series
    doc = create_series_page_doc(title: 'Foundation')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::SeriesPageLdGenerator.generate_hash(doc, site)

    expected_about = { '@type' => 'BookSeries', 'name' => 'Foundation' }
    assert_equal expected_about, result['about']
  end

  def test_generate_hash_includes_author
    doc = create_series_page_doc(title: 'Bobiverse')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::SeriesPageLdGenerator.generate_hash(doc, site)

    expected_author = { '@type' => 'Person', 'name' => 'Alexander Gude' }
    assert_equal expected_author, result['author']
  end

  def test_generate_hash_without_description
    doc = create_series_page_doc(title: 'Bobiverse')
    site = create_site(@site_config)
    result = Jekyll::SEO::Generators::SeriesPageLdGenerator.generate_hash(doc, site)

    refute result.key?('description'), 'Missing description should omit field'
  end

  def test_generate_hash_without_author
    config = @site_config.dup
    config.delete('author')
    doc = create_series_page_doc(title: 'Bobiverse')
    site = create_site(config)
    result = Jekyll::SEO::Generators::SeriesPageLdGenerator.generate_hash(doc, site)

    refute result.key?('author'), 'Missing author should omit field'
  end

  private

  def create_series_page_doc(title:, description: nil)
    data = {
      'layout' => 'series_page',
      'title' => title,
    }
    data['description'] = description if description

    create_doc(data, '/books/series/bobiverse/', 'Series page content', nil, nil)
  end
end
