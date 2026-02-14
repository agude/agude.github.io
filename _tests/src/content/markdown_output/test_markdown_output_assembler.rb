# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::MarkdownOutput::MarkdownOutputAssembler.
#
# Verifies header generation and markdown assembly for different page types.
class TestMarkdownOutputAssembler < Minitest::Test
  Assembler = Jekyll::MarkdownOutput::MarkdownOutputAssembler

  # --- Header builders ---

  def test_header_post_includes_title_and_date
    doc = create_doc(
      { 'layout' => 'post', 'title' => 'My Post',
        'date' => Time.new(2026, 2, 13), 'categories' => %w[tech ai],
        'markdown_body' => 'Body content' },
      '/blog/my-post/'
    )
    header = Assembler.build_header(doc)
    assert_includes header, '# My Post'
    assert_includes header, '*February 13, 2026*'
    assert_includes header, '#tech, #ai'
  end

  def test_header_book_includes_authors_and_rating
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Dune',
        'book_authors' => ['Frank Herbert'], 'series' => 'Dune',
        'book_number' => 1, 'rating' => 5,
        'markdown_body' => 'Review body' },
      '/books/dune/'
    )
    header = Assembler.build_header(doc)
    assert_includes header, '# Dune'
    assert_includes header, 'by Frank Herbert'
    assert_includes header, 'Book 1 of Dune'
    assert_includes header, "\u2605\u2605\u2605\u2605\u2605"
    assert_includes header, '## Review'
  end

  def test_header_book_multiple_authors
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'Good Omens',
        'book_authors' => ['Terry Pratchett', 'Neil Gaiman'],
        'rating' => 4, 'markdown_body' => 'Body' },
      '/books/good-omens/'
    )
    header = Assembler.build_header(doc)
    assert_includes header, 'by Terry Pratchett and Neil Gaiman'
  end

  def test_header_author_page
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Dan Simmons', 'markdown_body' => '' },
      '/books/authors/dan-simmons/'
    )
    header = Assembler.build_header(doc)
    assert_equal '# Dan Simmons', header
  end

  def test_header_series_page
    doc = create_doc(
      { 'layout' => 'series_page', 'title' => 'Culture', 'markdown_body' => '' },
      '/books/series/culture/'
    )
    header = Assembler.build_header(doc)
    assert_equal '# Culture', header
  end

  def test_header_generic_page
    doc = create_doc(
      { 'layout' => 'page', 'title' => 'Papers', 'markdown_body' => '' },
      '/papers/'
    )
    header = Assembler.build_header(doc)
    assert_equal '# Papers', header
  end

  # --- Assembly ---

  def test_body_content_preserved
    doc = create_doc(
      { 'layout' => 'page', 'title' => 'Test',
        'markdown_body' => "Some **bold** content\n\nWith paragraphs.",
        'markdown_alternate_href' => '/test.md' },
      '/test/'
    )
    result = Assembler.assemble_markdown(doc)
    assert_includes result, '# Test'
    assert_includes result, 'Some **bold** content'
    assert_includes result, 'With paragraphs.'
  end

  def test_skips_items_without_markdown_body
    site = create_site
    site.define_singleton_method(:static_files) { @static_files ||= [] }
    doc = create_doc({ 'layout' => 'post', 'title' => 'No Body' }, '/blog/test/')
    # markdown_body is not set
    Assembler.process_items(site, [doc])
    assert_empty site.static_files
  end

  def test_output_path_for_trailing_slash_url
    doc = create_doc(
      { 'layout' => 'page', 'title' => 'Test',
        'markdown_body' => 'content',
        'markdown_alternate_href' => '/papers.md' },
      '/papers/'
    )
    site = create_site
    site.define_singleton_method(:static_files) { @static_files ||= [] }
    Assembler.process_items(site, [doc])
    assert_equal 1, site.static_files.length
    file = site.static_files.first
    assert_equal 'papers.md', file.generated_name
  end
end
