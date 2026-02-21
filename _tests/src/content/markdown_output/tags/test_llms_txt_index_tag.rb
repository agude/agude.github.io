# frozen_string_literal: true

require_relative '../../../../test_helper'

# Tests for Jekyll::MarkdownOutput::Tags::LlmsTxtIndexTag.
#
# Verifies the Liquid tag generates correct llms.txt sections with
# proper grouping, absolute URLs, and description extraction.
class TestLlmsTxtIndexTag < Minitest::Test
  Tag = Jekyll::MarkdownOutput::Tags::LlmsTxtIndexTag

  def test_blog_posts_grouped_under_heading
    site = build_site_with_entries
    output = render_tag(site)
    assert_includes output, '## Blog Posts'
    assert_includes output, 'My Blog Post'
  end

  def test_book_reviews_grouped_under_heading
    site = build_site_with_entries
    output = render_tag(site)
    assert_includes output, '## Book Reviews'
    assert_includes output, 'Dune Review'
  end

  def test_optional_pages_grouped_under_heading
    site = build_site_with_entries
    output = render_tag(site)
    assert_includes output, '## Optional'
    assert_includes output, 'About'
  end

  def test_absolute_md_urls_used
    site = build_site_with_entries
    output = render_tag(site)
    assert_includes output, 'https://alexgude.com/blog/my-post.md'
    assert_includes output, 'https://alexgude.com/books/dune.md'
  end

  def test_description_included_for_posts
    site = build_site_with_entries
    output = render_tag(site)
    assert_includes output, ': A great blog post'
  end

  def test_book_cards_include_authors_and_rating
    site = build_site_with_entries
    output = render_tag(site)
    assert_includes output, 'Frank Herbert'
    assert_includes output, "\u2605" # star character
  end

  def test_empty_section_omitted
    post = create_doc(
      { 'layout' => 'post', 'title' => 'Solo Post' },
      '/blog/solo/',
      'content',
      nil,
      MockCollection.new([], 'posts'),
    )
    site = create_site(
      { 'url' => 'https://example.com' },
      {},
      [],
      [post],
    )
    output = render_tag(site)
    assert_includes output, '## Blog Posts'
    refute_includes output, '## Book Reviews'
    refute_includes output, '## Optional'
  end

  def test_disabled_feature_returns_empty
    site = build_site_with_entries
    site.config['enable_markdown_output'] = false
    output = render_tag(site)
    assert_equal '', output
  end

  def test_ineligible_document_excluded
    opted_out = create_doc(
      {
        'layout' => 'post',
        'title' => 'Opted Out',
        'markdown_output' => false,
      },
      '/blog/opted-out/',
      'content',
      nil,
      MockCollection.new([], 'posts'),
    )
    site = create_site(
      { 'url' => 'https://example.com' },
      {},
      [],
      [opted_out],
    )
    output = render_tag(site)
    refute_includes output, 'Opted Out'
  end

  def test_llms_txt_page_excluded_from_optional
    llms_page = make_page_like(
      create_doc(
        { 'layout' => 'page', 'title' => 'LLMs Index' },
        '/llms.txt',
      ),
      ext: '.txt',
      name: 'llms.txt',
    )

    about_page = make_page_like(
      create_doc(
        { 'layout' => 'page', 'title' => 'About' },
        '/about/',
      ),
    )

    site = create_site(
      { 'url' => 'https://example.com' },
      {},
      [llms_page, about_page],
    )
    output = render_tag(site)
    refute_includes output, 'LLMs Index'
    assert_includes output, 'About'
  end

  def test_page_without_layout_excluded
    no_layout = make_page_like(
      create_doc(
        { 'title' => 'No Layout' },
        '/no-layout/',
      ),
    )
    no_layout.data.delete('layout')

    site = create_site(
      { 'url' => 'https://example.com' },
      {},
      [no_layout],
    )
    output = render_tag(site)
    refute_includes output, 'No Layout'
  end

  def test_syntax_error_on_arguments
    assert_raises(Liquid::SyntaxError) do
      Liquid::Template.parse('{% llms_txt_index foo %}')
    end
  end

  private

  def render_tag(site)
    context = create_context(
      {},
      { site: site, page: {} },
    )
    template = Liquid::Template.parse('{% llms_txt_index %}')
    template.render!(context)
  end

  # Add ext and name methods to a MockDocument so it passes eligible_page? checks.
  def make_page_like(doc, ext: '.html', name: nil)
    page_name = name || File.basename(doc.url)
    doc.define_singleton_method(:ext) { ext }
    doc.define_singleton_method(:name) { page_name }
    doc
  end

  def build_site_with_entries
    posts_coll = MockCollection.new([], 'posts')
    post = create_doc(
      {
        'layout' => 'post',
        'title' => 'My Blog Post',
        'description' => 'A great blog post',
      },
      '/blog/my-post/',
      'content',
      nil,
      posts_coll,
    )
    posts_coll.docs = [post]

    books_coll = MockCollection.new([], 'books')
    book = create_doc(
      {
        'layout' => 'book',
        'title' => 'Dune Review',
        'book_authors' => ['Frank Herbert'],
        'rating' => 5,
        'excerpt' => '<p>A review of Dune</p>',
      },
      '/books/dune/',
      'content',
      nil,
      books_coll,
    )
    books_coll.docs = [book]

    about_page = make_page_like(
      create_doc(
        { 'layout' => 'page', 'title' => 'About' },
        '/about/',
      ),
    )

    create_site(
      {
        'url' => 'https://alexgude.com',
        'description' => 'Test site description',
      },
      { 'books' => [book] },
      [about_page],
      [post],
    )
  end
end
