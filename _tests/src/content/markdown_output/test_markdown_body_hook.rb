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

  # --- content_with_layout_tags ---

  def test_content_with_layout_tags_normal_page_unchanged
    page = create_doc({ 'layout' => 'page' }, '/papers/')
    result = Hook.content_with_layout_tags('Some body text', page)
    assert_equal 'Some body text', result
  end

  def test_content_with_layout_tags_author_page_empty_body
    page = create_doc({ 'layout' => 'author_page' }, '/books/authors/dan-simmons/')
    result = Hook.content_with_layout_tags('', page)
    assert_includes result, "short reviews of {{ page.title }}'s books:"
    assert_includes result, '{% display_books_by_author page.title %}'
  end

  def test_content_with_layout_tags_series_page_empty_body
    page = create_doc({ 'layout' => 'series_page' }, '/books/series/culture/')
    result = Hook.content_with_layout_tags('', page)
    assert_includes result, 'short reviews of the books from the series: {{ page.title }}'
    assert_includes result, '{% display_books_for_series page.title %}'
  end

  def test_content_with_layout_tags_category_page_with_intro
    page = create_doc({ 'layout' => 'category' }, '/topics/machine-learning/')
    result = Hook.content_with_layout_tags('Intro paragraph here.', page)
    assert_includes result, 'Intro paragraph here.'
    assert_includes result, '{% display_category_posts topic=topic %}'
    assert_match(/Intro paragraph here\.\n\n.*display_category_posts/, result)
  end

  def test_content_with_layout_tags_nil_content
    page = create_doc({ 'layout' => 'author_page' }, '/books/authors/someone/')
    result = Hook.content_with_layout_tags(nil, page)
    assert_includes result, '{% display_books_by_author page.title %}'
  end

  def test_content_with_layout_tags_whitespace_only_content
    page = create_doc({ 'layout' => 'series_page' }, '/books/series/dune/')
    result = Hook.content_with_layout_tags("  \n  \n  ", page)
    assert_includes result, '{% display_books_for_series page.title %}'
  end

  def test_content_with_layout_tags_author_page_with_body
    page = create_doc({ 'layout' => 'author_page' }, '/books/authors/someone/')
    result = Hook.content_with_layout_tags('Bio text here.', page)
    assert_includes result, 'Bio text here.'
    assert_includes result, '{% display_books_by_author page.title %}'
    # Body should come before snippet
    body_pos = result.index('Bio text here.')
    snippet_pos = result.index('display_books_by_author')
    assert body_pos < snippet_pos
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

  # --- Integration: layout-driven pages render through markdown pass ---

  def test_author_page_renders_book_list_via_layout_tag
    books = [
      create_doc(
        {
          'title' => 'Hyperion',
          'series' => 'Hyperion Cantos',
          'book_number' => 1,
          'book_authors' => ['Dan Simmons'],
          'rating' => 5,
        },
        '/books/hyperion.html',
      ),
      create_doc(
        {
          'title' => 'Fall of Hyperion',
          'series' => 'Hyperion Cantos',
          'book_number' => 2,
          'book_authors' => ['Dan Simmons'],
          'rating' => 4,
        },
        '/books/fall-of-hyperion.html',
      ),
    ]
    site = create_site({ 'url' => 'http://example.com' }, { 'books' => books })
    page = create_doc({ 'layout' => 'author_page', 'title' => 'Dan Simmons' }, '/books/authors/dan-simmons/')
    content = Hook.content_with_layout_tags('', page)
    payload = { 'page' => page.data.merge('title' => 'Dan Simmons') }

    with_silent_logger do
      result = Hook.render_markdown_body(content, 'test.md', site, payload)
      assert_includes result, "short reviews of Dan Simmons's books:"
      assert_includes result, '[Hyperion](/books/hyperion.html)'
      assert_includes result, '[Fall of Hyperion](/books/fall-of-hyperion.html)'
      refute_includes result, '<div'
    end
  end

  def test_series_page_renders_numbered_book_list_via_layout_tag
    books = [
      create_doc(
        {
          'title' => 'Dune',
          'series' => 'Dune',
          'book_number' => 1,
          'book_authors' => ['Frank Herbert'],
          'rating' => 5,
        },
        '/books/dune.html',
      ),
      create_doc(
        {
          'title' => 'Dune Messiah',
          'series' => 'Dune',
          'book_number' => 2,
          'book_authors' => ['Frank Herbert'],
          'rating' => 4,
        },
        '/books/dune-messiah.html',
      ),
    ]
    site = create_site({ 'url' => 'http://example.com' }, { 'books' => books })
    page = create_doc({ 'layout' => 'series_page', 'title' => 'Dune' }, '/books/series/dune/')
    content = Hook.content_with_layout_tags('', page)
    payload = { 'page' => page.data.merge('title' => 'Dune') }

    with_silent_logger do
      result = Hook.render_markdown_body(content, 'test.md', site, payload)
      assert_includes result, 'short reviews of the books from the series: Dune'
      assert_includes result, '[Dune](/books/dune.html)'
      assert_includes result, '[Dune Messiah](/books/dune-messiah.html)'
      refute_includes result, '<div'
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
