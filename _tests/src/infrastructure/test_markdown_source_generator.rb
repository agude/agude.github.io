# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../_plugins/src/infrastructure/markdown_source_generator'

# Tests for Jekyll::Infrastructure::MarkdownSourceGenerator
class TestMarkdownSourceGenerator < Minitest::Test
  def setup
    @generator = Jekyll::Infrastructure::MarkdownSourceGenerator.new
  end

  # --- yaml_quote tests ---

  def test_yaml_quote_simple_string
    result = @generator.send(:yaml_quote, 'Simple Title')
    assert_equal 'Simple Title', result
  end

  def test_yaml_quote_string_with_colon
    result = @generator.send(:yaml_quote, 'Title: A Subtitle')
    assert_equal '"Title: A Subtitle"', result
  end

  def test_yaml_quote_string_with_quotes
    result = @generator.send(:yaml_quote, 'The "Great" Book')
    assert_equal '"The \\"Great\\" Book"', result
  end

  def test_yaml_quote_string_with_brackets
    result = @generator.send(:yaml_quote, 'Book [Volume 1]')
    assert_equal '"Book [Volume 1]"', result
  end

  def test_yaml_quote_nil_returns_empty_quotes
    result = @generator.send(:yaml_quote, nil)
    assert_equal '""', result
  end

  # --- format_date tests ---

  def test_format_date_with_time
    time = Time.new(2024, 3, 15, 12, 0, 0)
    result = @generator.send(:format_date, time)
    assert_equal '2024-03-15', result
  end

  def test_format_date_with_nil
    result = @generator.send(:format_date, nil)
    assert_nil result
  end

  # --- build_post_frontmatter tests ---

  def test_build_post_frontmatter_includes_all_fields
    doc = create_doc(
      {
        'title' => 'My Post Title',
        'description' => 'A great post',
        'categories' => %w[tech ruby],
        'date' => Time.new(2024, 5, 20)
      },
      '/blog/2024/05/20/my-post/'
    )

    lines = @generator.send(:build_post_frontmatter, doc)

    assert_includes lines, 'title: My Post Title'
    assert_includes lines, 'date: 2024-05-20'
    assert_includes lines, 'description: A great post'
    assert_includes lines, 'categories: [tech, ruby]'
    assert_includes lines, 'url: /blog/2024/05/20/my-post/'
  end

  # --- build_book_frontmatter tests ---

  def test_build_book_frontmatter_includes_all_fields
    doc = create_doc(
      {
        'title' => 'My Book',
        'book_authors' => 'Jane Doe',
        'series' => 'Great Series',
        'book_number' => 3,
        'rating' => 4,
        'date' => Time.new(2024, 6, 10)
      },
      '/books/my-book/'
    )

    lines = @generator.send(:build_book_frontmatter, doc)

    assert_includes lines, 'title: My Book'
    assert_includes lines, 'author: Jane Doe'
    # Series with book number contains parentheses, which need quoting
    series_line = lines.find { |l| l.start_with?('series:') }
    refute_nil series_line
    assert_match(/Great Series.*Book 3/, series_line)
    assert_includes lines, 'rating: 4/5'
    assert_includes lines, 'review_date: 2024-06-10'
    assert_includes lines, 'url: /books/my-book/'
  end

  def test_build_book_frontmatter_with_multiple_authors
    doc = create_doc(
      {
        'title' => 'Collab Book',
        'book_authors' => ['Author One', 'Author Two'],
        'date' => Time.new(2024, 1, 1)
      },
      '/books/collab/'
    )

    lines = @generator.send(:build_book_frontmatter, doc)

    # Should use authors (plural) for array
    author_line = lines.find { |l| l.start_with?('authors:') }
    refute_nil author_line
    assert_match(/Author One/, author_line)
    assert_match(/Author Two/, author_line)
  end

  def test_build_book_frontmatter_without_series
    doc = create_doc(
      {
        'title' => 'Standalone Book',
        'book_authors' => 'Solo Author',
        'date' => Time.new(2024, 1, 1)
      },
      '/books/standalone/'
    )

    lines = @generator.send(:build_book_frontmatter, doc)

    series_line = lines.find { |l| l.start_with?('series:') }
    assert_nil series_line
  end

  # --- build_frontmatter tests ---

  def test_build_frontmatter_wraps_with_markers
    doc = create_doc(
      { 'title' => 'Test', 'date' => Time.new(2024, 1, 1) },
      '/test/'
    )

    result = @generator.send(:build_frontmatter, doc, :post)

    assert result.start_with?("---\n")
    assert result.include?("\n---\n")
  end

  # --- extract_source_content tests ---

  def test_extract_source_content_removes_frontmatter
    # Create a temp file with frontmatter
    require 'tempfile'
    temp_file = Tempfile.new(['test', '.md'])
    temp_file.write("---\ntitle: Test\ndate: 2024-01-01\n---\n\nThis is the content.")
    temp_file.close

    doc = create_doc({ 'path' => temp_file.path }, '/test/')
    doc.path = temp_file.path

    result = @generator.send(:extract_source_content, doc)
    assert_equal "This is the content.", result

    temp_file.unlink
  end

  def test_extract_source_content_handles_missing_file
    doc = create_doc({}, '/missing/')

    result = @generator.send(:extract_source_content, doc)
    assert_equal '', result
  end

  # --- generate_for_collection tests ---

  def test_generate_for_collection_skips_unpublished
    unpublished = create_doc(
      { 'title' => 'Draft', 'path' => 'draft.md', 'published' => false },
      '/draft/'
    )
    published = create_doc(
      { 'title' => 'Published', 'path' => 'pub.md', 'published' => true },
      '/pub/'
    )

    site = create_site

    # Track how many times create_markdown_page is called
    call_count = 0
    @generator.stub :create_markdown_page, ->(_s, _d, _t) { call_count += 1 } do
      @generator.send(:generate_for_collection, site, [unpublished, published], :post)
    end

    # Should only call for the published doc
    assert_equal 1, call_count
  end

  def test_generate_for_collection_handles_nil_published
    # When published is not set (nil), document should be included
    doc_no_published = create_doc(
      { 'title' => 'No Published Field', 'path' => 'test.md' },
      '/test/'
    )

    site = create_site

    call_count = 0
    @generator.stub :create_markdown_page, ->(_s, _d, _t) { call_count += 1 } do
      @generator.send(:generate_for_collection, site, [doc_no_published], :post)
    end

    assert_equal 1, call_count
  end

  # --- render_markdown_content tests ---

  def test_render_markdown_content_combines_frontmatter_and_rendered_content
    doc = create_doc(
      {
        'title' => 'Test Post',
        'date' => Time.new(2024, 3, 15),
        'path' => 'test.md'
      },
      '/blog/test/'
    )

    @generator.stub :extract_source_content, 'source' do
      @generator.stub :render_with_markdown_mode, 'rendered content' do
        result = @generator.send(:render_markdown_content, nil, doc, :post)

        assert result.start_with?("---\n")
        assert result.include?('title: Test Post')
        assert result.include?('rendered content')
      end
    end
  end

end
