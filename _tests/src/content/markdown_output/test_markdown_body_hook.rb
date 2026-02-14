# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::MarkdownOutput::MarkdownBodyHook module methods.
#
# Verifies eligibility checks, config-based enable/disable,
# and markdown href computation.
class TestMarkdownBodyHook < Minitest::Test
  Hook = Jekyll::MarkdownOutput::MarkdownBodyHook

  # --- enabled? ---

  def test_enabled_by_default
    site = create_site
    assert Hook.enabled?(site)
  end

  def test_disabled_via_config
    site = create_site('enable_markdown_output' => false)
    refute Hook.enabled?(site)
  end

  def test_enabled_explicitly
    site = create_site('enable_markdown_output' => true)
    assert Hook.enabled?(site)
  end

  # --- eligible_document? ---

  def test_eligible_document_posts
    collection = MockCollection.new([], 'posts')
    doc = create_doc({}, '/blog/test/', 'content', nil, collection)
    assert Hook.eligible_document?(doc)
  end

  def test_eligible_document_books
    collection = MockCollection.new([], 'books')
    doc = create_doc({}, '/books/test/', 'content', nil, collection)
    assert Hook.eligible_document?(doc)
  end

  def test_eligible_document_other_collection
    collection = MockCollection.new([], 'pages')
    doc = create_doc({}, '/pages/test/', 'content', nil, collection)
    refute Hook.eligible_document?(doc)
  end

  def test_eligible_document_opt_out
    collection = MockCollection.new([], 'posts')
    doc = create_doc({ 'markdown_output' => false }, '/blog/test/', 'content', nil, collection)
    refute Hook.eligible_document?(doc)
  end

  def test_eligible_document_no_collection
    doc = create_doc({}, '/test/')
    refute Hook.eligible_document?(doc)
  end

  # --- eligible_page? ---

  def test_eligible_page_with_layout
    page = create_doc({ 'layout' => 'page' }, '/papers/')
    # MockDocument uses ext from path; we need to set ext manually
    page.define_singleton_method(:ext) { '.html' }
    assert Hook.eligible_page?(page)
  end

  def test_excluded_page_opt_out
    page = create_doc({ 'layout' => 'page', 'markdown_output' => false }, '/404.html')
    page.define_singleton_method(:ext) { '.html' }
    refute Hook.eligible_page?(page)
  end

  def test_excluded_page_redirect_layout
    page = create_doc({ 'layout' => 'redirect' }, '/blog/old-url/')
    page.define_singleton_method(:ext) { '.html' }
    refute Hook.eligible_page?(page)
  end

  def test_excluded_page_no_layout
    page = create_doc({ 'layout' => nil }, '/feed.xml')
    page.define_singleton_method(:ext) { '.xml' }
    refute Hook.eligible_page?(page)
  end

  def test_excluded_page_xml_extension
    page = create_doc({ 'layout' => 'page' }, '/sitemap.xml')
    page.define_singleton_method(:ext) { '.xml' }
    refute Hook.eligible_page?(page)
  end

  def test_excluded_page_json_extension
    page = create_doc({ 'layout' => 'page' }, '/data.json')
    page.define_singleton_method(:ext) { '.json' }
    refute Hook.eligible_page?(page)
  end

  def test_eligible_page_md_extension
    page = create_doc({ 'layout' => 'page' }, '/papers/')
    page.define_singleton_method(:ext) { '.md' }
    assert Hook.eligible_page?(page)
  end

  # --- compute_markdown_href ---

  def test_compute_markdown_href_trailing_slash
    doc = create_doc({}, '/papers/')
    assert_equal '/papers/index.md', Hook.compute_markdown_href(doc)
  end

  def test_compute_markdown_href_no_trailing_slash
    doc = create_doc({}, '/resume')
    assert_equal '/index.md', Hook.compute_markdown_href(doc)
  end

  def test_compute_markdown_href_nested_path
    doc = create_doc({}, '/blog/2026/my-post/')
    assert_equal '/blog/2026/my-post/index.md', Hook.compute_markdown_href(doc)
  end

  def test_compute_markdown_href_html_extension
    doc = create_doc({}, '/books/hyperion-simmons.html')
    assert_equal '/books/index.md', Hook.compute_markdown_href(doc)
  end
end
