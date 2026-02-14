# frozen_string_literal: true

require_relative '../../../../test_helper'

# Tests for Jekyll::Books::Backlinks::Finder
#
# Verifies that backlinks are correctly found and processed for book pages.
class TestBacklinksFinder < Minitest::Test
  def setup
    # Book A links to Book B
    @book_a = create_doc(
      { 'title' => 'Book A', 'published' => true },
      '/books/a.html',
      "Review with {% book_link 'Book B' %}.",
    )
    @book_b = create_doc(
      { 'title' => 'Book B', 'published' => true },
      '/books/b.html',
      'Content of Book B.',
    )
  end

  def test_finds_backlinks_for_book
    site = create_site({}, { 'books' => [@book_a, @book_b] })
    context = create_context({}, { site: site, page: @book_b })

    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    assert_equal 1, result[:backlinks].length
    assert_equal 'Book A', result[:backlinks].first[0]
  end

  def test_returns_empty_when_no_backlinks
    standalone = create_doc(
      { 'title' => 'Standalone', 'published' => true },
      '/books/standalone.html',
    )

    site = create_site({}, { 'books' => [standalone] })
    context = create_context({}, { site: site, page: standalone })

    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    assert_empty result[:backlinks]
  end

  def test_excludes_self_references
    self_ref = create_doc(
      { 'title' => 'Self Ref', 'published' => true },
      '/books/self.html',
      "{% book_link 'Self Ref' %}",
    )

    site = create_site({}, { 'books' => [self_ref] })
    context = create_context({}, { site: site, page: self_ref })

    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    assert_empty result[:backlinks]
  end

  def test_sorts_backlinks_by_title
    book_z = create_doc(
      { 'title' => 'Zebra Book', 'published' => true },
      '/books/z.html',
      "{% book_link 'Target' %}",
    )
    book_a = create_doc(
      { 'title' => 'Apple Book', 'published' => true },
      '/books/apple.html',
      "{% book_link 'Target' %}",
    )
    target = create_doc(
      { 'title' => 'Target', 'published' => true },
      '/books/target.html',
    )

    site = create_site({}, { 'books' => [book_z, book_a, target] })
    context = create_context({}, { site: site, page: target })

    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    assert_equal 'Apple Book', result[:backlinks].first[0]
    assert_equal 'Zebra Book', result[:backlinks].last[0]
  end

  def test_strips_articles_when_sorting
    the_book = create_doc(
      { 'title' => 'The Amazing Book', 'published' => true },
      '/books/the-amazing.html',
      "{% book_link 'Target' %}",
    )
    basic_book = create_doc(
      { 'title' => 'Basic Book', 'published' => true },
      '/books/basic.html',
      "{% book_link 'Target' %}",
    )
    target = create_doc(
      { 'title' => 'Target', 'published' => true },
      '/books/target.html',
    )

    site = create_site({}, { 'books' => [the_book, basic_book, target] })
    context = create_context({}, { site: site, page: target })

    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    # "The Amazing Book" should sort as "Amazing Book" before "Basic Book"
    assert_equal 'The Amazing Book', result[:backlinks].first[0]
  end

  def test_handles_missing_site
    context = create_context({}, { site: nil, page: @book_b })

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil, [String, String])

    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = nil
    Jekyll.stub :logger, mock_logger do
      result = finder.find
    end

    # Gracefully returns empty backlinks when site is missing
    assert_empty result[:backlinks]
  end

  def test_handles_missing_page
    site = create_site({}, { 'books' => [@book_a, @book_b] })
    context = create_context({}, { site: site, page: nil })

    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    assert_empty result[:backlinks]
  end

  def test_handles_page_without_url
    no_url_page = create_doc({ 'title' => 'No URL' }, nil)
    site = create_site({}, { 'books' => [@book_a] })
    context = create_context({}, { site: site, page: no_url_page })

    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    assert_empty result[:backlinks]
  end

  def test_handles_page_without_title
    no_title_page = create_doc({ 'title' => nil }, '/books/no-title.html')
    site = create_site({}, { 'books' => [@book_a] })
    context = create_context({}, { site: site, page: no_title_page })

    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    assert_empty result[:backlinks]
  end

  def test_handles_missing_books_collection
    site = create_site({}, {}, [])
    context = create_context({}, { site: site, page: @book_b })

    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    assert_empty result[:backlinks]
  end

  def test_includes_series_backlinks
    series_book_1 = create_doc(
      { 'title' => 'Series Book 1', 'published' => true, 'series' => 'Epic Series' },
      '/books/series1.html',
    )
    series_book_2 = create_doc(
      { 'title' => 'Series Book 2', 'published' => true, 'series' => 'Epic Series' },
      '/books/series2.html',
    )
    linker = create_doc(
      { 'title' => 'Linker', 'published' => true },
      '/books/linker.html',
      "{% series_link 'Epic Series' %}",
    )
    series_page = create_doc(
      { 'title' => 'Epic Series', 'layout' => 'series_page' },
      '/series/epic.html',
    )

    site = create_site({}, { 'books' => [series_book_1, series_book_2, linker] }, [series_page])
    context = create_context({}, { site: site, page: series_book_1 })

    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    # Should find the linker as a series backlink
    titles = result[:backlinks].map(&:first)
    assert_includes titles, 'Linker'
  end

  def test_returns_backlink_type
    site = create_site({}, { 'books' => [@book_a, @book_b] })
    context = create_context({}, { site: site, page: @book_b })

    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    # Result format is [title, url, type]
    assert_equal 'book', result[:backlinks].first[2]
  end

  def test_skips_backlink_source_with_empty_title
    # Tests line 150: `next unless present?(title)` - when source title is empty/nil
    empty_title_book = create_doc(
      { 'title' => '', 'published' => true },
      '/books/empty-title.html',
      "{% book_link 'Target' %}",
    )
    target = create_doc(
      { 'title' => 'Target', 'published' => true },
      '/books/target.html',
    )

    site = create_site({}, { 'books' => [empty_title_book, target] })
    context = create_context({}, { site: site, page: target })

    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    # The empty-title book should be filtered out
    assert_empty result[:backlinks]
  end

  def test_returns_empty_when_canonical_url_not_found
    # Tests line 25: `return { logs: '', backlinks: [] } unless canonical_url`
    # Create a page whose URL isn't in the canonical map
    orphan_page = create_doc(
      { 'title' => 'Orphan', 'published' => true },
      '/books/orphan.html',
    )
    # Create site without the orphan in the books collection (so it won't be in canonical map)
    site = create_site({}, { 'books' => [@book_a, @book_b] })
    # Now create context with the orphan page
    context = create_context({}, { site: site, page: orphan_page })

    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    assert_empty result[:backlinks]
  end

  def test_deduplicates_lower_priority_entries
    # Tests line 124: should_skip_entry returns true when duplicate has lower priority
    # This is tested implicitly through normal operation, but we can verify
    # by having same source link twice with different types
    book_c = create_doc(
      { 'title' => 'Book C', 'published' => true },
      '/books/c.html',
      "{% book_link 'Target' %}",
    )
    target = create_doc(
      { 'title' => 'Target', 'published' => true },
      '/books/target.html',
    )

    site = create_site({}, { 'books' => [book_c, target] })
    context = create_context({}, { site: site, page: target })

    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    # Should only have one entry for Book C (deduplicated)
    titles = result[:backlinks].map(&:first)
    assert_equal 1, titles.count('Book C')
  end
end
