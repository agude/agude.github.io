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

  def test_book_link_overrides_series_link_in_multi_book_series
    # Bug reproduction: When a book links to both a series AND a specific book
    # in that series, the Finder should return the direct book link type.
    series_book_1 = create_doc(
      { 'title' => 'Hyperion', 'published' => true, 'series' => 'Hyperion Cantos' },
      '/books/hyperion.html',
      'First book.',
    )
    series_book_2 = create_doc(
      { 'title' => 'Fall of Hyperion', 'published' => true, 'series' => 'Hyperion Cantos' },
      '/books/fall-of-hyperion.html',
      'Second book.',
    )
    dual_linker = create_doc(
      { 'title' => 'Accelerando', 'published' => true },
      '/books/accelerando.html',
      "{% series_link 'Hyperion Cantos' %} and {% book_link 'Hyperion' %}.",
    )
    series_page = create_doc(
      { 'title' => 'Hyperion Cantos', 'layout' => 'series_page' },
      '/series/hyperion-cantos.html',
    )

    site = create_site(
      {},
      { 'books' => [series_book_1, series_book_2, dual_linker] },
      [series_page],
    )

    # Test Hyperion's backlinks - should show 'book' type for Accelerando
    context = create_context({}, { site: site, page: series_book_1 })
    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    accelerando_backlink = result[:backlinks].find { |b| b[0] == 'Accelerando' }
    refute_nil accelerando_backlink, 'Should find Accelerando in backlinks'
    assert_equal 'book', accelerando_backlink[2], 'Direct book_link should override series_link'
  end

  def test_book_link_overrides_series_link_with_multiple_reviews
    # Bug reproduction: Hyperion has two reviews (book family). Accelerando links to
    # "Hyperion Cantos" (series) which creates backlinks to BOTH reviews with type='series'.
    # Accelerando also has book_link "Hyperion" which creates a backlink to ONE review
    # with type='book'. When merging backlinks from the book family, the book type
    # should be preserved, not overwritten by the series type from the other review.
    hyperion_new = create_doc(
      { 'title' => 'Hyperion', 'published' => true, 'series' => 'Hyperion Cantos' },
      '/books/hyperion/',
      'Newer review.',
    )
    hyperion_old = create_doc(
      {
        'title' => 'Hyperion',
        'published' => true,
        'series' => 'Hyperion Cantos',
        'canonical_url' => '/books/hyperion/',
      },
      '/books/hyperion/review-2023-10-17/',
      'Older review.',
    )
    accelerando = create_doc(
      { 'title' => 'Accelerando', 'published' => true },
      '/books/accelerando/',
      "{% series_link 'Hyperion Cantos' %} and {% book_link 'Hyperion' %}.",
    )
    series_page = create_doc(
      { 'title' => 'Hyperion Cantos', 'layout' => 'series_page' },
      '/series/hyperion-cantos/',
    )

    site = create_site(
      {},
      { 'books' => [hyperion_new, hyperion_old, accelerando] },
      [series_page],
    )

    # Test from the newer Hyperion review's perspective
    context = create_context({}, { site: site, page: hyperion_new })
    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    accelerando_backlink = result[:backlinks].find { |b| b[0] == 'Accelerando' }
    refute_nil accelerando_backlink, 'Should find Accelerando in backlinks'
    assert_equal 'book', accelerando_backlink[2],
                 'Direct book_link should override series_link even with multiple reviews in family'
  end

  def test_series_backlinks_only_include_series_type_links
    # add_series_links should only propagate series-type backlinks from other books
    # in the series. If Book A links directly to Fall of Hyperion (book_link, not
    # series_link), that should NOT appear on Hyperion's page.
    hyperion = create_doc(
      { 'title' => 'Hyperion', 'published' => true, 'series' => 'Hyperion Cantos' },
      '/books/hyperion/',
      'First book.',
    )
    fall_of_hyperion = create_doc(
      { 'title' => 'Fall of Hyperion', 'published' => true, 'series' => 'Hyperion Cantos' },
      '/books/fall-of-hyperion/',
      'Second book.',
    )
    # This book only links to Fall of Hyperion directly, NOT to the series
    direct_linker = create_doc(
      { 'title' => 'Direct Linker', 'published' => true },
      '/books/direct-linker/',
      "{% book_link 'Fall of Hyperion' %}.",
    )
    series_page = create_doc(
      { 'title' => 'Hyperion Cantos', 'layout' => 'series_page' },
      '/series/hyperion-cantos/',
    )

    site = create_site(
      {},
      { 'books' => [hyperion, fall_of_hyperion, direct_linker] },
      [series_page],
    )

    # Hyperion should NOT show Direct Linker - it only linked to another book in the series
    context = create_context({}, { site: site, page: hyperion })
    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    titles = result[:backlinks].map(&:first)
    refute_includes titles, 'Direct Linker',
                    'Direct book links to OTHER series books should not appear as backlinks'

    # But Fall of Hyperion SHOULD show Direct Linker
    context2 = create_context({}, { site: site, page: fall_of_hyperion })
    finder2 = Jekyll::Books::Backlinks::Finder.new(context2.registers[:site], context2.registers[:page])
    result2 = finder2.find

    titles2 = result2[:backlinks].map(&:first)
    assert_includes titles2, 'Direct Linker',
                    'Direct book link should appear on the target book page'
  end

  def test_deduplicates_source_with_multiple_reviews
    # If the SOURCE of a backlink has multiple reviews, they should be deduplicated
    # by canonical URL, keeping the highest priority type.
    target = create_doc(
      { 'title' => 'Target Book', 'published' => true, 'series' => 'Test Series' },
      '/books/target/',
      'Target.',
    )
    # Source book has two reviews - one links via series, one via book
    source_new = create_doc(
      { 'title' => 'Source Book', 'published' => true },
      '/books/source/',
      "{% book_link 'Target Book' %}.",
    )
    source_old = create_doc(
      {
        'title' => 'Source Book',
        'published' => true,
        'canonical_url' => '/books/source/',
      },
      '/books/source/old-review/',
      "{% series_link 'Test Series' %}.",
    )
    series_page = create_doc(
      { 'title' => 'Test Series', 'layout' => 'series_page' },
      '/series/test/',
    )

    site = create_site(
      {},
      { 'books' => [target, source_new, source_old] },
      [series_page],
    )

    context = create_context({}, { site: site, page: target })
    finder = Jekyll::Books::Backlinks::Finder.new(context.registers[:site], context.registers[:page])
    result = finder.find

    # Should only have ONE entry for Source Book (deduplicated by canonical URL)
    source_backlinks = result[:backlinks].select { |b| b[0] == 'Source Book' }
    assert_equal 1, source_backlinks.length, 'Source with multiple reviews should be deduplicated'
    # And it should be type 'book' (higher priority than 'series')
    assert_equal 'book', source_backlinks.first[2],
                 'Deduplication should keep higher priority type'
  end
end
