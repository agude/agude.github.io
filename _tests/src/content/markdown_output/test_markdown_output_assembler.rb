# frozen_string_literal: true

require_relative '../../../test_helper'

# Wrapper that mimics real Jekyll::Document behavior: doc['url'] returns
# data['url'] (nil) instead of MockDocument's special url field. This
# catches bugs where code assumes page['url'] works on raw documents.
class RealDocLike
  attr_reader :data, :url

  def initialize(mock_doc)
    @data = mock_doc.data.dup
    @data.delete('url')
    @url = mock_doc.url
  end

  def [](key)
    @data[key.to_s]
  end
end

# Tests for Jekyll::MarkdownOutput::MarkdownOutputAssembler.
#
# Verifies header generation and markdown assembly for different page types.
class TestMarkdownOutputAssembler < Minitest::Test
  Assembler = Jekyll::MarkdownOutput::MarkdownOutputAssembler

  # --- Header builders ---

  def test_header_post_includes_title_and_date
    doc = create_doc(
      {
        'layout' => 'post',
        'title' => 'My Post',
        'date' => Time.new(2026, 2, 13),
        'categories' => %w[tech ai],
        'markdown_body' => 'Body content',
      },
      '/blog/my-post/',
    )
    header = Assembler.build_header(doc)
    assert_includes header, '# My Post'
    assert_includes header, '*February 13, 2026*'
    assert_includes header, '#tech, #ai'
  end

  def test_header_book_includes_authors_and_rating
    doc = create_doc(
      {
        'layout' => 'book',
        'title' => 'Dune',
        'book_authors' => ['Frank Herbert'],
        'series' => 'Dune',
        'book_number' => 1,
        'rating' => 5,
        'markdown_body' => 'Review body',
      },
      '/books/dune/',
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
      {
        'layout' => 'book',
        'title' => 'Good Omens',
        'book_authors' => ['Terry Pratchett', 'Neil Gaiman'],
        'rating' => 4,
        'markdown_body' => 'Body',
      },
      '/books/good-omens/',
    )
    header = Assembler.build_header(doc)
    assert_includes header, 'by Terry Pratchett and Neil Gaiman'
  end

  def test_header_author_page
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Dan Simmons', 'markdown_body' => '' },
      '/books/authors/dan-simmons/',
    )
    header = Assembler.build_header(doc)
    assert_equal '# Dan Simmons', header
  end

  def test_header_series_page
    doc = create_doc(
      { 'layout' => 'series_page', 'title' => 'Culture', 'markdown_body' => '' },
      '/books/series/culture/',
    )
    header = Assembler.build_header(doc)
    assert_equal '# Culture', header
  end

  def test_header_category_page
    doc = create_doc(
      {
        'layout' => 'category',
        'category-title' => 'Machine Learning',
        'markdown_body' => '',
      },
      '/topics/machine-learning/',
    )
    header = Assembler.build_header(doc)
    assert_equal '# Topic: Machine Learning', header
  end

  def test_header_category_page_falls_back_to_title
    doc = create_doc(
      { 'layout' => 'category', 'title' => 'Fallback Title', 'markdown_body' => '' },
      '/topics/test/',
    )
    header = Assembler.build_header(doc)
    assert_equal '# Topic: Fallback Title', header
  end

  def test_header_generic_page
    doc = create_doc(
      { 'layout' => 'page', 'title' => 'Papers', 'markdown_body' => '' },
      '/papers/',
    )
    header = Assembler.build_header(doc)
    assert_equal '# Papers', header
  end

  # --- Assembly ---

  def test_body_content_preserved
    doc = create_doc(
      {
        'layout' => 'page',
        'title' => 'Test',
        'markdown_body' => "Some **bold** content\n\nWith paragraphs.",
        'markdown_alternate_href' => '/test.md',
      },
      '/test/',
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
      {
        'layout' => 'page',
        'title' => 'Test',
        'markdown_body' => 'content',
        'markdown_alternate_href' => '/papers.md',
      },
      '/papers/',
    )
    site = create_site
    site.define_singleton_method(:static_files) { @static_files ||= [] }
    Assembler.process_items(site, [doc])
    assert_equal 1, site.static_files.length
    file = site.static_files.first
    assert_equal 'papers.md', file.generated_name
  end

  # --- Book footer: related books ---

  def test_related_books_section_renders_markdown_list
    books, site = setup_book_with_related
    current = books.first

    result = Assembler.build_related_books_section(site, current)
    assert_includes result, '## Related Books'
    # Should contain links to the other books
    books[1..].each do |book|
      assert_includes result, "[#{book.data['title']}](#{book.url})"
    end
  end

  def test_related_books_section_nil_when_no_related
    site = create_site({}, {})
    doc = create_doc(
      {
        'layout' => 'book',
        'title' => 'Solo Book',
        'book_authors' => ['Author'],
        'rating' => 3,
      },
      '/books/solo/',
    )
    result = Assembler.build_related_books_section(site, doc)
    assert_nil result
  end

  # --- Book footer: backlinks ---

  def test_backlinks_section_renders_markdown_list
    site, current = setup_book_with_backlinks
    result = Assembler.build_backlinks_section(site, current)
    assert_includes result, '## Mentioned In'
    assert_includes result, '[Mentioning Post](/blog/mention/)'
  end

  def test_backlinks_section_nil_when_no_backlinks
    site = create_site({}, {})
    doc = create_doc(
      { 'layout' => 'book', 'title' => 'No Links', 'book_authors' => ['Auth'] },
      '/books/no-links/',
    )
    result = Assembler.build_backlinks_section(site, doc)
    assert_nil result
  end

  # --- Book footer: previous reviews ---

  def test_previous_reviews_section_renders_markdown_list
    site, current, archived = setup_book_with_previous_reviews
    result = Assembler.build_previous_reviews_section(site, current)
    assert_includes result, '## Previous Reviews'
    assert_includes result, "[#{archived.data['title']}](#{archived.url})"
  end

  def test_previous_reviews_section_nil_when_no_reviews
    coll = MockCollection.new([], 'books')
    doc = create_doc(
      {
        'layout' => 'book',
        'title' => 'First Review',
        'book_authors' => ['Auth'],
        'rating' => 4,
      },
      '/books/first/',
      'Content',
      nil,
      coll,
    )
    coll.docs = [doc]
    site = create_site({}, { 'books' => coll.docs })
    result = Assembler.build_previous_reviews_section(site, doc)
    assert_nil result
  end

  # --- Book footer: full assembly integration ---

  def test_book_assembly_includes_footer_sections
    books, site = setup_book_with_related
    current = books.first
    current.data['markdown_body'] = 'Great book review.'
    result = Assembler.assemble_markdown(current, site: site)
    assert_includes result, '# S1B1'
    assert_includes result, 'Great book review.'
    assert_includes result, '## Related Books'
  end

  # --- Post footer: related posts ---

  def test_related_posts_section_renders_markdown_list
    posts, site = setup_post_with_related
    current = posts.first
    result = Assembler.build_related_posts_section(site, current)
    assert_includes result, '## Related Posts'
    posts[1..].each do |post|
      assert_includes result, "[#{post.data['title']}](#{post.url})"
    end
  end

  def test_related_posts_section_nil_when_no_related
    site = create_site({}, {}, [], [])
    doc = create_doc(
      {
        'layout' => 'post',
        'title' => 'Solo Post',
        'date' => Time.new(2026, 1, 1),
        'categories' => ['unique'],
      },
      '/blog/solo/',
    )
    result = Assembler.build_related_posts_section(site, doc)
    assert_nil result
  end

  def test_post_assembly_includes_related_section
    posts, site = setup_post_with_related
    current = posts.first
    current.data['markdown_body'] = 'Article content here.'
    result = Assembler.assemble_markdown(current, site: site)
    assert_includes result, '# Post A'
    assert_includes result, 'Article content here.'
    assert_includes result, '## Related Posts'
  end

  # Regression: verify footer methods work when doc['url'] returns nil
  # (real Jekyll::Document behavior), not MockDocument's special handling.
  def test_book_footer_works_without_url_in_data
    books, site = setup_book_with_related
    current = RealDocLike.new(books.first)
    result = Assembler.build_book_footer(site, current)
    assert_includes result, '## Related Books'
  end

  def test_post_footer_works_without_url_in_data
    posts, site = setup_post_with_related
    current = RealDocLike.new(posts.first)
    result = Assembler.build_post_footer(site, current)
    assert_includes result, '## Related Posts'
  end

  def test_related_books_section_respects_limit
    max = Jekyll::Books::Related::Finder::DEFAULT_MAX_BOOKS
    books, site = setup_book_with_many_related(max + 4)
    current = books.first
    result = Assembler.build_related_books_section(site, current)
    book_links = result.lines.count { |l| l.start_with?('- [') }
    assert_equal max, book_links, "Expected #{max} related books, got #{book_links}"
  end

  def test_related_posts_section_respects_limit
    max = Jekyll::Posts::Related::Finder::DEFAULT_MAX_POSTS
    posts, site = setup_post_with_many_related(max + 4)
    current = posts.first
    result = Assembler.build_related_posts_section(site, current)
    post_links = result.lines.count { |l| l.start_with?('- [') }
    assert_equal max, post_links, "Expected #{max} related posts, got #{post_links}"
  end

  # --- Assembly: layout-driven pages ---

  def test_author_page_assembly_has_title_and_body
    doc = create_doc(
      {
        'layout' => 'author_page',
        'title' => 'Dan Simmons',
        'markdown_body' => "### Hyperion Cantos\n- [Hyperion](/books/hyperion.html) by Dan Simmons --- 5 stars",
      },
      '/books/authors/dan-simmons/',
    )
    result = Assembler.assemble_markdown(doc)
    assert_includes result, '# Dan Simmons'
    assert_includes result, '[Hyperion](/books/hyperion.html)'
  end

  def test_series_page_assembly_has_title_and_body
    doc = create_doc(
      {
        'layout' => 'series_page',
        'title' => 'Dune',
        'markdown_body' => '1. [Dune](/books/dune.html) by Frank Herbert --- 5 stars',
      },
      '/books/series/dune/',
    )
    result = Assembler.assemble_markdown(doc)
    assert_includes result, '# Dune'
    assert_includes result, '1. [Dune](/books/dune.html)'
  end

  def test_category_page_assembly_has_title_intro_and_body
    doc = create_doc(
      {
        'layout' => 'category',
        'category-title' => 'Machine Learning',
        'markdown_body' => "Intro paragraph.\n\n- [My Post](/blog/my-post/) (January 1, 2026)",
      },
      '/topics/machine-learning/',
    )
    result = Assembler.assemble_markdown(doc)
    assert_includes result, '# Topic: Machine Learning'
    assert_includes result, 'Intro paragraph.'
    assert_includes result, '[My Post](/blog/my-post/)'
  end

  def test_non_book_assembly_has_no_footer
    doc = create_doc(
      {
        'layout' => 'post',
        'title' => 'Blog Post',
        'date' => Time.new(2026, 1, 1),
        'markdown_body' => 'Post body.',
      },
      '/blog/post/',
    )
    site = create_site
    result = Assembler.assemble_markdown(doc, site: site)
    refute_includes result, '## Related Books'
    refute_includes result, '## Mentioned In'
    refute_includes result, '## Previous Reviews'
  end

  private

  def setup_post_with_many_related(count)
    test_time = Time.parse('2026-01-15 10:00:00 EST')
    posts = (0...count).map do |i|
      create_doc(
        {
          'layout' => 'post',
          'title' => "Post #{('A'.ord + i).chr}",
          'categories' => ['tech'],
          'date' => test_time - (60 * 60 * 24 * i),
        },
        "/blog/post-#{i}/",
      )
    end
    site = create_site({}, {}, [], posts)
    [posts, site]
  end

  def setup_book_with_many_related(count)
    test_time = Time.parse('2024-03-15 10:00:00 EST')
    coll = MockCollection.new([], 'books')
    books = (1..count).map do |i|
      create_doc(
        {
          'layout' => 'book',
          'title' => "S1B#{i}",
          'series' => 'Series 1',
          'book_number' => i,
          'book_authors' => ['Auth'],
          'rating' => 4,
          'date' => test_time - (60 * 60 * 24 * (count + 1 - i)),
        },
        "/books/s1b#{i}.html",
        "Content #{i}",
        nil,
        coll,
      )
    end
    coll.docs = books
    site = create_site({}, { 'books' => coll.docs })
    [books, site]
  end

  def setup_post_with_related
    test_time = Time.parse('2026-01-15 10:00:00 EST')
    posts = %w[A B C].each_with_index.map do |letter, i|
      create_doc(
        {
          'layout' => 'post',
          'title' => "Post #{letter}",
          'categories' => ['tech'],
          'date' => test_time - (60 * 60 * 24 * i),
        },
        "/blog/post-#{letter.downcase}/",
      )
    end
    site = create_site({}, {}, [], posts)
    [posts, site]
  end

  def setup_book_with_related
    test_time = Time.parse('2024-03-15 10:00:00 EST')
    coll = MockCollection.new([], 'books')
    books = (1..4).map do |i|
      create_doc(
        {
          'layout' => 'book',
          'title' => "S1B#{i}",
          'series' => 'Series 1',
          'book_number' => i,
          'book_authors' => ['Auth'],
          'rating' => 4,
          'date' => test_time - (60 * 60 * 24 * (10 - i)),
        },
        "/books/s1b#{i}.html",
        "Content #{i}",
        nil,
        coll,
      )
    end
    coll.docs = books
    site = create_site({}, { 'books' => coll.docs })
    [books, site]
  end

  def setup_book_with_backlinks
    coll = MockCollection.new([], 'books')
    current = create_doc(
      {
        'layout' => 'book',
        'title' => 'Target Book',
        'book_authors' => ['Auth'],
        'rating' => 5,
      },
      '/books/target.html',
      'Content',
      nil,
      coll,
    )
    mentioning = create_doc(
      { 'layout' => 'post', 'title' => 'Mentioning Post' },
      '/blog/mention/',
    )
    coll.docs = [current]
    # Wire up the link_cache with backlinks
    site = create_site({}, { 'books' => coll.docs })
    site.data['link_cache']['url_to_canonical_map'] = { '/books/target.html' => '/books/target.html' }
    site.data['link_cache']['book_families'] = { '/books/target.html' => ['/books/target.html'] }
    site.data['link_cache']['backlinks'] = {
      '/books/target.html' => [{ source: mentioning, type: 'direct' }],
    }
    [site, current]
  end

  def setup_book_with_previous_reviews
    coll = MockCollection.new([], 'books')
    current = create_doc(
      {
        'layout' => 'book',
        'title' => 'Dune (2024)',
        'book_authors' => ['Frank Herbert'],
        'rating' => 5,
      },
      '/books/dune-2024/',
      'Current review',
      nil,
      coll,
    )
    archived = create_doc(
      {
        'layout' => 'book',
        'title' => 'Dune (2020)',
        'book_authors' => ['Frank Herbert'],
        'rating' => 4,
        'canonical_url' => '/books/dune-2024/',
      },
      '/books/dune-2020/',
      'Old review',
      '2020-01-01',
      coll,
    )
    coll.docs = [current, archived]
    site = create_site({}, { 'books' => coll.docs })
    [site, current, archived]
  end
end
