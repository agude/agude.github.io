# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::MarkdownOutput::LlmsTxtGenerator.
#
# Verifies llms.txt generation with correct grouping, absolute URLs,
# and description extraction.
class TestLlmsTxtGenerator < Minitest::Test
  Generator = Jekyll::MarkdownOutput::LlmsTxtGenerator

  def test_generate_creates_llms_txt_static_file
    site = build_site_with_entries
    Generator.generate(site)

    llms_file = site.static_files.find { |f| f.generated_name == 'llms.txt' }
    refute_nil llms_file, 'Expected llms.txt in static_files'
  end

  def test_generate_skipped_when_disabled
    site = build_site_with_entries
    site.config['enable_markdown_output'] = false
    initial_count = site.static_files.size
    Generator.generate(site)

    assert_equal initial_count, site.static_files.size
  end

  def test_generate_skipped_when_no_markdown_items
    site = create_site({ 'markdown_output' => { 'enabled' => true } })
    Generator.generate(site)

    llms_file = site.static_files.find do |f|
      f.respond_to?(:generated_name) && f.generated_name == 'llms.txt'
    end
    assert_nil llms_file
  end

  def test_blog_posts_grouped_under_heading
    site = build_site_with_entries
    Generator.generate(site)

    content = extract_llms_content(site)
    assert_includes content, '## Blog Posts'
    assert_includes content, '[My Blog Post]'
  end

  def test_book_reviews_grouped_under_heading
    site = build_site_with_entries
    Generator.generate(site)

    content = extract_llms_content(site)
    assert_includes content, '## Book Reviews'
    assert_includes content, '[Dune Review]'
  end

  def test_optional_pages_grouped_under_heading
    site = build_site_with_entries
    Generator.generate(site)

    content = extract_llms_content(site)
    assert_includes content, '## Optional'
    assert_includes content, '[About]'
  end

  def test_absolute_urls_used
    site = build_site_with_entries
    Generator.generate(site)

    content = extract_llms_content(site)
    assert_includes content, 'https://alexgude.com/blog/my-post.md'
    assert_includes content, 'https://alexgude.com/books/dune.md'
  end

  def test_description_included_when_available
    site = build_site_with_entries
    Generator.generate(site)

    content = extract_llms_content(site)
    assert_includes content, ': A great blog post'
  end

  def test_description_omitted_when_missing
    site = build_site_with_entries
    Generator.generate(site)

    content = extract_llms_content(site)
    # The About page has no description, so the line should end after the URL
    line = content.lines.find { |l| l.include?('[About]') }
    # After the closing paren of the markdown link, there should be no ": description"
    after_link = line.split(')', 2).last
    refute_match(/: \S/, after_link)
  end

  def test_site_title_in_header
    site = build_site_with_entries
    Generator.generate(site)

    content = extract_llms_content(site)
    assert_match(/\A# /, content)
  end

  def test_site_description_in_blockquote
    site = build_site_with_entries
    Generator.generate(site)

    content = extract_llms_content(site)
    assert_includes content, '> Test site description'
  end

  def test_empty_section_omitted
    # Only posts, no books or pages
    post = create_doc(
      {
        'layout' => 'post',
        'title' => 'Solo Post',
        'markdown_body' => 'body',
        'markdown_alternate_href' => '/blog/solo.md',
      },
      '/blog/solo/',
    )
    site = create_site(
      { 'markdown_output' => { 'enabled' => true } },
      {},
      [],
      [post],
    )
    Generator.generate(site)

    content = extract_llms_content(site)
    assert_includes content, '## Blog Posts'
    refute_includes content, '## Book Reviews'
    refute_includes content, '## Optional'
  end

  def test_excerpt_used_as_fallback_description
    post = create_doc(
      {
        'layout' => 'post',
        'title' => 'Excerpt Post',
        'excerpt' => '<p>HTML excerpt text</p>',
        'markdown_body' => 'body',
        'markdown_alternate_href' => '/blog/excerpt.md',
      },
      '/blog/excerpt/',
    )
    site = create_site(
      {
        'markdown_output' => { 'enabled' => true },
        'description' => 'Site desc',
      },
      {},
      [],
      [post],
    )
    Generator.generate(site)

    content = extract_llms_content(site)
    assert_includes content, ': HTML excerpt text'
  end

  private

  def build_site_with_entries
    post = create_doc(
      {
        'layout' => 'post',
        'title' => 'My Blog Post',
        'description' => 'A great blog post',
        'markdown_body' => 'body',
        'markdown_alternate_href' => '/blog/my-post.md',
      },
      '/blog/my-post/',
    )

    coll = MockCollection.new([], 'books')
    book = create_doc(
      {
        'layout' => 'book',
        'title' => 'Dune Review',
        'book_authors' => ['Frank Herbert'],
        'rating' => 5,
        'description' => 'Review of Dune',
        'markdown_body' => 'body',
        'markdown_alternate_href' => '/books/dune.md',
      },
      '/books/dune/',
      'content',
      nil,
      coll,
    )
    coll.docs = [book]

    about_page = create_doc(
      {
        'layout' => 'page',
        'title' => 'About',
        'markdown_body' => 'body',
        'markdown_alternate_href' => '/about.md',
      },
      '/about/',
    )

    create_site(
      {
        'markdown_output' => { 'enabled' => true },
        'url' => 'https://alexgude.com',
        'description' => 'Test site description',
      },
      { 'books' => [book] },
      [about_page],
      [post],
    )
  end

  def extract_llms_content(site)
    llms_file = site.static_files.find do |f|
      f.respond_to?(:generated_name) && f.generated_name == 'llms.txt'
    end
    # Access the generated content via instance variable
    llms_file.instance_variable_get(:@generated_content)
  end
end
