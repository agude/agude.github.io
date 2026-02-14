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
    assert_equal '/papers.md', Hook.compute_markdown_href(doc)
  end

  def test_compute_markdown_href_no_trailing_slash
    doc = create_doc({}, '/resume')
    assert_equal '/resume.md', Hook.compute_markdown_href(doc)
  end

  def test_compute_markdown_href_nested_path
    doc = create_doc({}, '/blog/2026/my-post/')
    assert_equal '/blog/2026/my-post.md', Hook.compute_markdown_href(doc)
  end

  def test_compute_markdown_href_root_url
    doc = create_doc({}, '/')
    assert_equal '/index.md', Hook.compute_markdown_href(doc)
  end

  def test_compute_markdown_href_html_extension
    doc = create_doc({}, '/books/hyperion-simmons.html')
    assert_equal '/books/hyperion-simmons.md', Hook.compute_markdown_href(doc)
  end

  # --- render_markdown_body ---

  def test_render_markdown_body_produces_markdown_for_book_link
    site, _, payload = build_rendering_fixtures
    content = "{% book_link 'Hyperion' author='Dan Simmons' %}"

    with_silent_logger do
      result = Hook.render_markdown_body(content, 'test.md', site, payload)
      assert_equal '[Hyperion](/books/hyperion.html)', result
    end
  end

  def test_render_markdown_body_produces_plain_text_for_missing_book
    site, _, payload = build_rendering_fixtures
    content = "{% book_link 'Nonexistent Book' %}"

    with_silent_logger do
      result = Hook.render_markdown_body(content, 'test.md', site, payload)
      assert_match(/Nonexistent Book/, result)
      refute_match(/\[/, result)
    end
  end

  # Regression: render_markdown_body must not pollute the Jekyll template
  # cache.  Jekyll 4 caches Liquid::Template objects by filename (||=) and
  # Liquid::Template#render mutates the cached template's @registers via
  # merge!.  If render_markdown_body used site.liquid_renderer, the
  # render_mode: :markdown register would leak into subsequent HTML renders,
  # causing every link tag to emit Markdown instead of HTML.
  def test_render_markdown_body_does_not_pollute_jekyll_template_cache
    site, page_data, payload = build_rendering_fixtures

    # Give MockSite the pieces Jekyll::LiquidRenderer expects
    site.config['liquid'] = { 'error_mode' => 'warn' }
    site.define_singleton_method(:theme) { nil }
    renderer = Jekyll::LiquidRenderer.new(site)

    content = "{% book_link 'Hyperion' author='Dan Simmons' %}"
    path = 'test_cache_isolation.md'

    with_silent_logger do
      # Step 1: markdown render (simulates :pre_render hook)
      md_result = Hook.render_markdown_body(content, path, site, payload)
      assert_match(/\[Hyperion\]/, md_result)

      # Step 2: HTML render via the shared LiquidRenderer (simulates Jekyll)
      html_file = renderer.file(path).parse(content)
      html_result = html_file.render!(payload, registers: { site: site, page: page_data })

      assert_match %r{<cite class="book-title">Hyperion</cite>},
                   html_result,
                   'render_mode: :markdown must not leak into subsequent HTML renders'
    end
  end

  private

  def build_rendering_fixtures
    book = create_doc(
      { 'title' => 'Hyperion', 'published' => true, 'book_authors' => ['Dan Simmons'] },
      '/books/hyperion.html',
    )
    site = create_site({}, { 'books' => [book] })
    page_data = { 'url' => '/test-page/', 'path' => 'test-page.md', 'title' => 'Test' }
    payload = { 'page' => page_data }
    [site, page_data, payload]
  end

  def with_silent_logger(&)
    silent = Object.new.tap do |l|
      def l.warn(*); end
      def l.error(*); end
      def l.info(*); end
      def l.debug(*); end
    end
    Jekyll.stub(:logger, silent, &)
  end
end
