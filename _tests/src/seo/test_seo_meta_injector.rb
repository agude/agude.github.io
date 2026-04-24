# frozen_string_literal: true

require_relative '../../test_helper'

# Tests for Jekyll::SEO::SeoMetaInjector
#
# Verifies the injector correctly stores SEO meta data for documents and pages.
class TestSeoMetaInjector < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://example.com',
      'baseurl' => '',
      'title' => 'Test Site',
      'author' => { 'name' => 'Test Author' },
      'description' => 'Test description',
    }
    @books_collection = MockCollection.new([], 'books')
    @posts_collection = MockCollection.new([], 'posts')
  end

  # --- Storage Initialization ---

  def test_initialize_storage_creates_hash
    site = create_site(@site_config)
    site.data.delete('seo_meta')

    Jekyll::SEO::SeoMetaInjector.initialize_storage(site)

    assert_instance_of Hash, site.data['seo_meta']
  end

  def test_initialize_storage_preserves_existing_data
    site = create_site(@site_config)
    site.data['seo_meta'] = { '/existing/' => { 'title' => 'Existing' } }

    Jekyll::SEO::SeoMetaInjector.initialize_storage(site)

    assert_equal({ 'title' => 'Existing' }, site.data['seo_meta']['/existing/'])
  end

  # --- inject_meta ---

  def test_inject_meta_stores_data_at_document_url
    site = create_site(@site_config)
    doc = create_doc(
      { 'layout' => 'post', 'title' => 'Test Post' },
      '/blog/test-post/',
      'Content',
      '2024-01-01',
      @posts_collection,
    )

    Jekyll::SEO::SeoMetaInjector.inject_meta(doc, site)

    assert site.data['seo_meta'].key?('/blog/test-post/')
  end

  def test_inject_meta_stores_hash_with_expected_keys
    site = create_site(@site_config)
    doc = create_doc(
      { 'layout' => 'post', 'title' => 'Test Post' },
      '/blog/test-post/',
      'Content',
      '2024-01-01',
      @posts_collection,
    )

    Jekyll::SEO::SeoMetaInjector.inject_meta(doc, site)
    meta = site.data['seo_meta']['/blog/test-post/']

    assert meta.key?('title')
    assert meta.key?('og_title')
    assert meta.key?('canonical')
    assert meta.key?('description')
  end

  def test_inject_meta_skips_document_without_url
    site = create_site(@site_config)
    doc = create_doc(
      { 'layout' => 'post', 'title' => 'No URL' },
      nil,
      'Content',
      '2024-01-01',
      @posts_collection,
    )

    Jekyll::SEO::SeoMetaInjector.inject_meta(doc, site)

    assert_empty site.data['seo_meta']
  end

  def test_inject_meta_skips_empty_url
    site = create_site(@site_config)
    doc = create_doc(
      { 'layout' => 'post', 'title' => 'Empty URL' },
      '',
      'Content',
      '2024-01-01',
      @posts_collection,
    )

    Jekyll::SEO::SeoMetaInjector.inject_meta(doc, site)

    assert_empty site.data['seo_meta']
  end

  def test_inject_meta_works_for_book_documents
    site = create_site(@site_config)
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Test Book', 'book_authors' => ['Author'] },
      '/books/test-book/',
      'Content',
      '2024-01-01',
      @books_collection,
    )

    Jekyll::SEO::SeoMetaInjector.inject_meta(doc, site)

    assert site.data['seo_meta'].key?('/books/test-book/')
  end

  def test_inject_meta_works_for_pages
    site = create_site(@site_config)
    doc = create_doc(
      { 'layout' => 'page', 'title' => 'About' },
      '/about/',
      'Content',
      nil,
      nil,
    )

    Jekyll::SEO::SeoMetaInjector.inject_meta(doc, site)

    assert site.data['seo_meta'].key?('/about/')
  end

  def test_inject_meta_handles_multiple_documents
    site = create_site(@site_config)
    doc1 = create_doc(
      { 'layout' => 'post', 'title' => 'Post 1' },
      '/blog/post-1/',
      'Content',
      '2024-01-01',
      @posts_collection,
    )
    doc2 = create_doc(
      { 'layout' => 'post', 'title' => 'Post 2' },
      '/blog/post-2/',
      'Content',
      '2024-01-02',
      @posts_collection,
    )

    Jekyll::SEO::SeoMetaInjector.inject_meta(doc1, site)
    Jekyll::SEO::SeoMetaInjector.inject_meta(doc2, site)

    assert_equal 2, site.data['seo_meta'].size
    assert site.data['seo_meta'].key?('/blog/post-1/')
    assert site.data['seo_meta'].key?('/blog/post-2/')
  end

  def test_inject_meta_overwrites_existing_entry_for_same_url
    site = create_site(@site_config)
    doc1 = create_doc(
      { 'layout' => 'post', 'title' => 'Original Title' },
      '/blog/same-url/',
      'Content',
      '2024-01-01',
      @posts_collection,
    )
    doc2 = create_doc(
      { 'layout' => 'post', 'title' => 'Updated Title' },
      '/blog/same-url/',
      'Content',
      '2024-01-01',
      @posts_collection,
    )

    Jekyll::SEO::SeoMetaInjector.inject_meta(doc1, site)
    Jekyll::SEO::SeoMetaInjector.inject_meta(doc2, site)

    meta = site.data['seo_meta']['/blog/same-url/']
    assert_includes meta['title'], 'Updated Title'
  end

  # --- Skipping Non-HTML Output ---

  def test_inject_meta_skips_txt_files
    site = create_site(@site_config)
    doc = create_doc(
      { 'layout' => 'page', 'title' => 'Robots' },
      '/robots.txt',
      'Content',
      nil,
      nil,
    )

    Jekyll::SEO::SeoMetaInjector.inject_meta(doc, site)

    refute site.data['seo_meta'].key?('/robots.txt')
  end

  def test_inject_meta_skips_xml_files
    site = create_site(@site_config)
    doc = create_doc(
      { 'layout' => 'page', 'title' => 'Sitemap' },
      '/sitemap.xml',
      'Content',
      nil,
      nil,
    )

    Jekyll::SEO::SeoMetaInjector.inject_meta(doc, site)

    refute site.data['seo_meta'].key?('/sitemap.xml')
  end

  def test_inject_meta_processes_html_files
    site = create_site(@site_config)
    doc = create_doc(
      { 'layout' => 'page', 'title' => 'Test Page' },
      '/test.html',
      'Content',
      nil,
      nil,
    )

    Jekyll::SEO::SeoMetaInjector.inject_meta(doc, site)

    assert site.data['seo_meta'].key?('/test.html')
  end

  def test_inject_meta_processes_extensionless_urls
    site = create_site(@site_config)
    doc = create_doc(
      { 'layout' => 'page', 'title' => 'Test Page' },
      '/about/',
      'Content',
      nil,
      nil,
    )

    Jekyll::SEO::SeoMetaInjector.inject_meta(doc, site)

    assert site.data['seo_meta'].key?('/about/')
  end

  # --- Skipping Layouts ---

  def test_inject_meta_skips_redirect_layout
    site = create_site(@site_config)
    doc = create_doc(
      { 'layout' => 'redirect', 'title' => 'Redirect Page' },
      '/old-url/',
      'Content',
      nil,
      nil,
    )

    Jekyll::SEO::SeoMetaInjector.inject_meta(doc, site)

    refute site.data['seo_meta'].key?('/old-url/')
  end

  def test_inject_meta_skips_redirect_with_missing_title
    site = create_site(@site_config)
    doc = create_doc(
      { 'layout' => 'redirect', 'title' => nil },
      '/old-url/',
      'Content',
      nil,
      nil,
    )

    Jekyll::SEO::SeoMetaInjector.inject_meta(doc, site)

    refute site.data['seo_meta'].key?('/old-url/')
  end

  def test_inject_meta_skips_pages_without_layout
    site = create_site(@site_config)
    doc = create_doc(
      { 'layout' => nil, 'title' => 'No Layout Page' },
      '/no-layout/',
      'Content',
      nil,
      nil,
    )

    Jekyll::SEO::SeoMetaInjector.inject_meta(doc, site)

    refute site.data['seo_meta'].key?('/no-layout/')
  end

  def test_inject_meta_skips_empty_layout
    site = create_site(@site_config)
    doc = create_doc(
      { 'layout' => '', 'title' => 'Empty Layout Page' },
      '/empty-layout/',
      'Content',
      nil,
      nil,
    )

    Jekyll::SEO::SeoMetaInjector.inject_meta(doc, site)

    refute site.data['seo_meta'].key?('/empty-layout/')
  end
end
