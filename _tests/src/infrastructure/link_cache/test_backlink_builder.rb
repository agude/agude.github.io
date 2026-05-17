# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::Infrastructure::LinkCache::BacklinkBuilder
#
# Verifies that backlinks are correctly built by scanning book content
# for book_link, series_link, and short_story_link tags.
class TestBacklinkBuilder < Minitest::Test
  def setup
    @book_a = create_doc(
      { 'title' => 'Book A', 'published' => true },
      '/books/book-a.html',
      "Review of Book A with {% book_link 'Book B' %} reference.",
    )
    @book_b = create_doc(
      { 'title' => 'Book B', 'published' => true },
      '/books/book-b.html',
      'Book B content with no links.',
    )
    @book_c = create_doc(
      { 'title' => 'Book C', 'published' => true },
      '/books/book-c.html',
      "Book C references {% book_link \"Book A\" %} and {% book_link 'Book B' %}.",
    )
  end

  def test_builds_backlinks_from_book_links
    site = create_site({}, { 'books' => [@book_a, @book_b, @book_c] })
    backlinks = site.data['link_cache']['backlinks']

    # Book B should have backlinks from Book A and Book C
    assert_equal 2, backlinks['/books/book-b.html'].length

    # Book A should have backlink from Book C
    assert_equal 1, backlinks['/books/book-a.html'].length
    assert_equal '/books/book-c.html', backlinks['/books/book-a.html'].first[:source].url
  end

  def test_no_self_referential_backlinks
    self_ref_book = create_doc(
      { 'title' => 'Self Ref', 'published' => true },
      '/books/self-ref.html',
      "This book references itself: {% book_link 'Self Ref' %}.",
    )

    site = create_site({}, { 'books' => [self_ref_book] })
    backlinks = site.data['link_cache']['backlinks']

    # Should not create a backlink to itself
    assert_empty backlinks['/books/self-ref.html'] || []
  end

  def test_handles_empty_content
    empty_book = create_doc(
      { 'title' => 'Empty', 'published' => true },
      '/books/empty.html',
      '',
    )

    site = create_site({}, { 'books' => [empty_book, @book_b] })
    # Should not raise an error
    refute_nil site.data['link_cache']['backlinks']
  end

  def test_handles_nil_content
    nil_book = create_doc(
      { 'title' => 'Nil Content', 'published' => true },
      '/books/nil.html',
      nil,
    )

    site = create_site({}, { 'books' => [nil_book, @book_b] })
    # Should not raise an error
    refute_nil site.data['link_cache']['backlinks']
  end

  def test_handles_missing_books_collection
    site = create_site({}, {}, [])
    backlinks = site.data['link_cache']['backlinks']

    assert_empty backlinks
  end

  def test_handles_empty_books_collection
    site = create_site({}, { 'books' => [] })
    backlinks = site.data['link_cache']['backlinks']

    assert_empty backlinks
  end

  def test_book_link_priority_over_series_link
    # Book that links via both book_link and series_link to same target
    dual_link_book = create_doc(
      { 'title' => 'Dual Linker', 'published' => true },
      '/books/dual.html',
      "{% series_link 'Test Series' %} and {% book_link 'Series Book' %}.",
    )
    series_book = create_doc(
      { 'title' => 'Series Book', 'published' => true, 'series' => 'Test Series' },
      '/books/series-book.html',
      'Part of test series.',
    )
    series_page = create_doc(
      { 'title' => 'Test Series', 'layout' => 'series_page' },
      '/series/test-series.html',
    )

    site = create_site(
      {},
      { 'books' => [dual_link_book, series_book] },
      [series_page],
    )
    backlinks = site.data['link_cache']['backlinks']

    # Series book should have only one backlink (deduplicated)
    # and it should be type 'book' (higher priority)
    target_backlinks = backlinks['/books/series-book.html']
    refute_nil target_backlinks
    assert_equal 1, target_backlinks.length
    assert_equal 'book', target_backlinks.first[:type]
  end

  def test_series_link_creates_backlinks_to_all_series_books
    series_book_1 = create_doc(
      { 'title' => 'Foundation', 'published' => true, 'series' => 'Foundation Series' },
      '/books/foundation.html',
      'First book.',
    )
    series_book_2 = create_doc(
      { 'title' => 'Foundation and Empire', 'published' => true, 'series' => 'Foundation Series' },
      '/books/foundation-empire.html',
      'Second book.',
    )
    referencing_book = create_doc(
      { 'title' => 'Review Collection', 'published' => true },
      '/books/reviews.html',
      "I love the {% series_link 'Foundation Series' %}!",
    )
    series_page = create_doc(
      { 'title' => 'Foundation Series', 'layout' => 'series_page' },
      '/series/foundation.html',
    )

    site = create_site(
      {},
      { 'books' => [series_book_1, series_book_2, referencing_book] },
      [series_page],
    )
    backlinks = site.data['link_cache']['backlinks']

    # Both series books should have backlinks from the referencing book
    assert_equal 1, (backlinks['/books/foundation.html'] || []).length
    assert_equal 1, (backlinks['/books/foundation-empire.html'] || []).length
  end

  def test_short_story_link_without_from_book_resolves_when_unique_url
    story_book = create_doc(
      { 'title' => 'Only Collection', 'published' => true },
      '/books/only.html',
      'Contains short stories.',
    )
    referencing_book = create_doc(
      { 'title' => 'Reviewer', 'published' => true },
      '/books/reviewer.html',
      "I enjoyed {% short_story_link 'Unique Story' %}.",
    )

    # All locations share the same URL, so no from_book is needed
    site = create_site_with_short_stories(
      [story_book, referencing_book],
      { 'unique story' => [{ 'url' => '/books/only.html', 'parent_book_title' => 'Only Collection' }] },
    )
    backlinks = site.data['link_cache']['backlinks']

    target_backlinks = backlinks['/books/only.html'] || []
    assert_equal 1, target_backlinks.length
    assert_equal 'short_story', target_backlinks.first[:type]
  end

  def test_short_story_link_creates_backlinks
    story_book = create_doc(
      { 'title' => 'Story Collection', 'published' => true },
      '/books/collection.html',
      'Contains short stories.',
    )
    referencing_book = create_doc(
      { 'title' => 'Analysis', 'published' => true },
      '/books/analysis.html',
      "Analysis of {% short_story_link 'The Last Question' from_book='Story Collection' %}.",
    )

    # Set up link_cache with short story data
    site = create_site_with_short_stories(
      [story_book, referencing_book],
      { 'the last question' => [{ 'url' => '/books/collection.html', 'parent_book_title' => 'Story Collection' }] },
    )
    backlinks = site.data['link_cache']['backlinks']

    # Story collection should have backlink from analysis
    target_backlinks = backlinks['/books/collection.html'] || []
    assert_equal 1, target_backlinks.length
    assert_equal 'short_story', target_backlinks.first[:type]
  end

  def test_double_quoted_book_links
    double_quoted = create_doc(
      { 'title' => 'Double Quoted', 'published' => true },
      '/books/double.html',
      'Uses {% book_link "Book B" %} with double quotes.',
    )

    site = create_site({}, { 'books' => [double_quoted, @book_b] })
    backlinks = site.data['link_cache']['backlinks']

    assert_equal 1, (backlinks['/books/book-b.html'] || []).length
  end

  def test_series_text_with_quoted_string_creates_backlinks
    series_book_1 = create_doc(
      { 'title' => 'On Basilisk Station', 'published' => true, 'series' => 'Honor Harrington' },
      '/books/basilisk.html',
      'First book.',
    )
    series_book_2 = create_doc(
      { 'title' => 'The Honor of the Queen', 'published' => true, 'series' => 'Honor Harrington' },
      '/books/honor-queen.html',
      'Second book.',
    )
    referencing_book = create_doc(
      { 'title' => 'Some Review', 'published' => true },
      '/books/review.html',
      'I love the {% series_text "Honor Harrington" %} series!',
    )
    series_page = create_doc(
      { 'title' => 'Honor Harrington', 'layout' => 'series_page' },
      '/series/honor-harrington.html',
    )

    site = create_site(
      {},
      { 'books' => [series_book_1, series_book_2, referencing_book] },
      [series_page],
    )
    backlinks = site.data['link_cache']['backlinks']

    assert_equal 1, (backlinks['/books/basilisk.html'] || []).length
    assert_equal 1, (backlinks['/books/honor-queen.html'] || []).length
  end

  def test_series_text_with_page_series_variable_creates_backlinks
    series_book_1 = create_doc(
      { 'title' => 'Foundation', 'published' => true, 'series' => 'Foundation Series' },
      '/books/foundation.html',
      'First book.',
    )
    series_book_2 = create_doc(
      { 'title' => 'Foundation and Empire', 'published' => true, 'series' => 'Foundation Series' },
      '/books/foundation-empire.html',
      'Second book.',
    )
    # Uses series_text with page.series variable (link defaults to true)
    referencing_book = create_doc(
      { 'title' => 'Second Foundation', 'published' => true, 'series' => 'Foundation Series' },
      '/books/second-foundation.html',
      'Third in {% series_text page.series %}. Great series.',
    )
    series_page = create_doc(
      { 'title' => 'Foundation Series', 'layout' => 'series_page' },
      '/series/foundation.html',
    )

    site = create_site(
      {},
      { 'books' => [series_book_1, series_book_2, referencing_book] },
      [series_page],
    )
    backlinks = site.data['link_cache']['backlinks']

    # Both other series books should have backlinks from the referencing book
    assert_equal 1, (backlinks['/books/foundation.html'] || []).length
    assert_equal 1, (backlinks['/books/foundation-empire.html'] || []).length
  end

  def test_series_text_link_false_with_quoted_string_skips_backlinks
    series_book = create_doc(
      { 'title' => 'On Basilisk Station', 'published' => true, 'series' => 'Honor Harrington' },
      '/books/basilisk.html',
      'First book.',
    )
    referencing_book = create_doc(
      { 'title' => 'Some Review', 'published' => true },
      '/books/review.html',
      'I read {% series_text "Honor Harrington" link=false %} books.',
    )
    series_page = create_doc(
      { 'title' => 'Honor Harrington', 'layout' => 'series_page' },
      '/series/honor-harrington.html',
    )

    site = create_site(
      {},
      { 'books' => [series_book, referencing_book] },
      [series_page],
    )
    backlinks = site.data['link_cache']['backlinks']

    # link=false means no link is rendered, so no backlink
    assert_empty backlinks['/books/basilisk.html'] || []
  end

  def test_series_text_link_false_with_page_series_variable_skips_backlinks
    series_book_1 = create_doc(
      { 'title' => 'Foundation', 'published' => true, 'series' => 'Foundation Series' },
      '/books/foundation.html',
      'First book.',
    )
    series_book_2 = create_doc(
      { 'title' => 'Foundation and Empire', 'published' => true, 'series' => 'Foundation Series' },
      '/books/foundation-empire.html',
      'Second book.',
    )
    # Uses series_text with page.series and link=false — no link rendered
    referencing_book = create_doc(
      { 'title' => 'Second Foundation', 'published' => true, 'series' => 'Foundation Series' },
      '/books/second-foundation.html',
      'Third in {% series_text page.series link=false %}. Great series.',
    )
    series_page = create_doc(
      { 'title' => 'Foundation Series', 'layout' => 'series_page' },
      '/series/foundation.html',
    )

    site = create_site(
      {},
      { 'books' => [series_book_1, series_book_2, referencing_book] },
      [series_page],
    )
    backlinks = site.data['link_cache']['backlinks']

    assert_empty backlinks['/books/foundation.html'] || []
    assert_empty backlinks['/books/foundation-empire.html'] || []
  end

  def test_series_link_with_page_series_variable_creates_backlinks
    series_book_1 = create_doc(
      { 'title' => 'Dune', 'published' => true, 'series' => 'Dune' },
      '/books/dune.html',
      'First book.',
    )
    series_book_2 = create_doc(
      { 'title' => 'Dune Messiah', 'published' => true, 'series' => 'Dune' },
      '/books/dune-messiah.html',
      'Second book.',
    )
    # Uses series_link with page.series variable
    referencing_book = create_doc(
      { 'title' => 'Children of Dune', 'published' => true, 'series' => 'Dune' },
      '/books/children-dune.html',
      'Third in {% series_link page.series %}. Still great.',
    )
    series_page = create_doc(
      { 'title' => 'Dune', 'layout' => 'series_page' },
      '/series/dune.html',
    )

    site = create_site(
      {},
      { 'books' => [series_book_1, series_book_2, referencing_book] },
      [series_page],
    )
    backlinks = site.data['link_cache']['backlinks']

    assert_equal 1, (backlinks['/books/dune.html'] || []).length
    assert_equal 1, (backlinks['/books/dune-messiah.html'] || []).length
  end

  def test_page_series_variable_with_nil_series_skips_backlinks
    series_book = create_doc(
      { 'title' => 'Foundation', 'published' => true, 'series' => 'Foundation Series' },
      '/books/foundation.html',
      'First book.',
    )
    # No series in front matter — page.series is nil
    referencing_book = create_doc(
      { 'title' => 'Some Review', 'published' => true },
      '/books/review.html',
      'I read {% series_text page.series %}.',
    )
    series_page = create_doc(
      { 'title' => 'Foundation Series', 'layout' => 'series_page' },
      '/series/foundation.html',
    )

    site = create_site(
      {},
      { 'books' => [series_book, referencing_book] },
      [series_page],
    )
    backlinks = site.data['link_cache']['backlinks']

    assert_empty backlinks['/books/foundation.html'] || []
  end

  def test_page_series_variable_with_empty_series_skips_backlinks
    series_book = create_doc(
      { 'title' => 'Foundation', 'published' => true, 'series' => 'Foundation Series' },
      '/books/foundation.html',
      'First book.',
    )
    # Empty string series in front matter
    referencing_book = create_doc(
      { 'title' => 'Some Review', 'published' => true, 'series' => '' },
      '/books/review.html',
      'I read {% series_link page.series %}.',
    )
    series_page = create_doc(
      { 'title' => 'Foundation Series', 'layout' => 'series_page' },
      '/series/foundation.html',
    )

    site = create_site(
      {},
      { 'books' => [series_book, referencing_book] },
      [series_page],
    )
    backlinks = site.data['link_cache']['backlinks']

    assert_empty backlinks['/books/foundation.html'] || []
  end

  def test_link_false_with_mixed_quoting_skips_backlinks
    series_book = create_doc(
      { 'title' => 'On Basilisk Station', 'published' => true, 'series' => 'Honor Harrington' },
      '/books/basilisk.html',
      'First book.',
    )
    # Single-quoted series name with double-quoted "false" — uses series_text which supports link=false
    referencing_book = create_doc(
      { 'title' => 'Some Review', 'published' => true },
      '/books/review.html',
      "I read {% series_text 'Honor Harrington' link=\"false\" %} books.",
    )
    series_page = create_doc(
      { 'title' => 'Honor Harrington', 'layout' => 'series_page' },
      '/series/honor-harrington.html',
    )

    site = create_site(
      {},
      { 'books' => [series_book, referencing_book] },
      [series_page],
    )
    backlinks = site.data['link_cache']['backlinks']

    assert_empty backlinks['/books/basilisk.html'] || []
  end

  def test_multiple_links_to_same_target_deduplicated
    multi_linker = create_doc(
      { 'title' => 'Multi Linker', 'published' => true },
      '/books/multi.html',
      "{% book_link 'Book B' %} is great. Did I mention {% book_link 'Book B' %}?",
    )

    site = create_site({}, { 'books' => [multi_linker, @book_b] })
    backlinks = site.data['link_cache']['backlinks']

    # Should only have one backlink despite two references
    assert_equal 1, (backlinks['/books/book-b.html'] || []).length
  end

  def test_book_link_priority_over_series_link_multi_book_series
    # Reproduces real scenario: Accelerando links to both "Hyperion Cantos" (series)
    # AND "Hyperion" (book). The backlink to Hyperion should be type 'book'.
    series_book_1 = create_doc(
      { 'title' => 'Hyperion', 'published' => true, 'series' => 'Hyperion Cantos' },
      '/books/hyperion.html',
      'First book in series.',
    )
    series_book_2 = create_doc(
      { 'title' => 'Fall of Hyperion', 'published' => true, 'series' => 'Hyperion Cantos' },
      '/books/fall-of-hyperion.html',
      'Second book in series.',
    )
    # Links to both the series AND a specific book in the series
    dual_linker = create_doc(
      { 'title' => 'Accelerando', 'published' => true },
      '/books/accelerando.html',
      "I compare this to {% series_link 'Hyperion Cantos' %} and specifically to {% book_link 'Hyperion' %}.",
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
    backlinks = site.data['link_cache']['backlinks']

    # Hyperion should have backlink from Accelerando with type 'book' (direct link)
    hyperion_backlinks = backlinks['/books/hyperion.html']
    refute_nil hyperion_backlinks
    accelerando_backlink = hyperion_backlinks.find { |b| b[:source].data['title'] == 'Accelerando' }
    refute_nil accelerando_backlink, 'Should find backlink from Accelerando'
    assert_equal 'book', accelerando_backlink[:type], 'Direct book_link should override series_link'

    # Fall of Hyperion should have backlink from Accelerando with type 'series' (no direct link)
    fall_backlinks = backlinks['/books/fall-of-hyperion.html']
    refute_nil fall_backlinks
    fall_accelerando = fall_backlinks.find { |b| b[:source].data['title'] == 'Accelerando' }
    refute_nil fall_accelerando, 'Should find backlink from Accelerando to Fall of Hyperion'
    assert_equal 'series', fall_accelerando[:type], 'Series-only link should be type series'
  end

  def test_priority_upgrade_from_separate_documents
    # Two separate source documents link to the same target via different link types.
    # Verifies priority upgrade works regardless of document scan order.
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true, 'series' => 'Test Series' },
      '/books/target.html',
      'The target of multiple links.',
    )
    # First source: only links via series
    series_linker = create_doc(
      { 'title' => 'Series Linker', 'published' => true },
      '/books/series-linker.html',
      "I mention {% series_link 'Test Series' %}.",
    )
    # Second source: links via both series AND direct book_link
    dual_linker = create_doc(
      { 'title' => 'Dual Linker', 'published' => true },
      '/books/dual-linker.html',
      "I mention {% series_link 'Test Series' %} and {% book_link 'Target Book' %}.",
    )
    series_page = create_doc(
      { 'title' => 'Test Series', 'layout' => 'series_page' },
      '/series/test-series.html',
    )

    site = create_site(
      {},
      { 'books' => [target_book, series_linker, dual_linker] },
      [series_page],
    )
    backlinks = site.data['link_cache']['backlinks']

    target_backlinks = backlinks['/books/target.html']
    refute_nil target_backlinks

    # Series linker should have type 'series' (only way it linked)
    series_only = target_backlinks.find { |b| b[:source].data['title'] == 'Series Linker' }
    refute_nil series_only
    assert_equal 'series', series_only[:type]

    # Dual linker should have type 'book' (upgraded from series)
    dual = target_backlinks.find { |b| b[:source].data['title'] == 'Dual Linker' }
    refute_nil dual
    assert_equal 'book', dual[:type], 'book_link should upgrade priority over series_link'
  end

  # --- Capture parsing and variable usage scoring tests ---

  def test_parses_capture_definitions_for_book_links
    # Book with captures defined at top, used in prose
    book_with_captures = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture maze %}{% book_link "A Maze of Death" %}{% endcapture %}
        {% capture androids %}{% book_link 'Do Androids Dream?' %}{% endcapture %}

        I read {{ maze }} last week. It was interesting. Later I found {{ androids }}.
      CONTENT
    )
    maze_book = create_doc(
      { 'title' => 'A Maze of Death', 'published' => true },
      '/books/maze.html',
      'Content.',
    )
    androids_book = create_doc(
      { 'title' => 'Do Androids Dream?', 'published' => true },
      '/books/androids.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_captures, maze_book, androids_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    refute_nil forward_links
    assert_equal 2, forward_links.length

    maze_link = forward_links.find { |l| l[:target].url == '/books/maze.html' }
    androids_link = forward_links.find { |l| l[:target].url == '/books/androids.html' }

    refute_nil maze_link, 'Should have forward link to maze book'
    refute_nil androids_link, 'Should have forward link to androids book'
  end

  def test_parses_capture_definitions_for_series_links
    # Series links resolve to books in the series, not to the series page.
    # This matches how backlinks work — series_link creates backlinks to all books in the series.
    book_with_captures = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture foundation %}{% series_link "Foundation Series" %}{% endcapture %}

        The {{ foundation }} is a classic.
      CONTENT
    )
    series_book_1 = create_doc(
      { 'title' => 'Foundation', 'published' => true, 'series' => 'Foundation Series' },
      '/books/foundation.html',
      'First book.',
    )
    series_book_2 = create_doc(
      { 'title' => 'Foundation and Empire', 'published' => true, 'series' => 'Foundation Series' },
      '/books/foundation-empire.html',
      'Second book.',
    )
    series_page = create_doc(
      { 'title' => 'Foundation Series', 'layout' => 'series_page' },
      '/series/foundation.html',
    )

    site = create_site(
      {},
      { 'books' => [book_with_captures, series_book_1, series_book_2] },
      [series_page],
    )
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    refute_nil forward_links
    # Forward links point to books, not series page
    assert_equal 2, forward_links.length, 'Should have forward links to both series books'

    book_1_link = forward_links.find { |l| l[:target].url == '/books/foundation.html' }
    book_2_link = forward_links.find { |l| l[:target].url == '/books/foundation-empire.html' }
    series_page_link = forward_links.find { |l| l[:target]&.url == '/series/foundation.html' }

    refute_nil book_1_link, 'Should have forward link to first series book'
    refute_nil book_2_link, 'Should have forward link to second series book'
    assert_nil series_page_link, 'Should NOT have forward link to series page'

    assert_equal 'series', book_1_link[:type]
    assert_equal 'series', book_2_link[:type]
  end

  def test_series_text_with_link_false_in_capture_creates_no_forward_link
    # series_text with link=false should not create forward links even when in a capture.
    # This tests the AST path handles LINK_FALSE_PATTERN correctly.
    book_with_capture = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture series_name %}{% series_text "Foundation Series" link=false %}{% endcapture %}

        I read the {{ series_name }} books.
      CONTENT
    )
    series_book = create_doc(
      { 'title' => 'Foundation', 'published' => true, 'series' => 'Foundation Series' },
      '/books/foundation.html',
      'First book.',
    )
    series_page = create_doc(
      { 'title' => 'Foundation Series', 'layout' => 'series_page' },
      '/series/foundation.html',
    )

    site = create_site(
      {},
      { 'books' => [book_with_capture, series_book] },
      [series_page],
    )
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    # link=false means no link rendered, so no forward link should be created
    assert(
      forward_links.nil? || forward_links.empty?,
      'series_text with link=false should not create forward links',
    )
  end

  def test_counts_variable_usages_in_prose
    book_with_captures = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture maze %}{% book_link "A Maze of Death" %}{% endcapture %}

        I read {{ maze }} first. Then I reread {{ maze }}. Finally, {{ maze }} again.
      CONTENT
    )
    maze_book = create_doc(
      { 'title' => 'A Maze of Death', 'published' => true },
      '/books/maze.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_captures, maze_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    maze_link = forward_links.find { |l| l[:target].url == '/books/maze.html' }
    refute_nil maze_link

    assert_equal 3, maze_link[:count], 'Should count 3 usages of {{ maze }}'
  end

  def test_calculates_position_by_occurrence_order
    # Position is based on occurrence order among all prose variables, not character position.
    # This avoids regex-based position tracking which can drift with markdown code blocks.
    book_with_captures = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture early %}{% book_link "Early Book" %}{% endcapture %}
        {% capture late %}{% book_link "Late Book" %}{% endcapture %}

        {{ early }} appears first.
        Some filler text here.
        {{ late }} appears second.
      CONTENT
    )
    early_book = create_doc(
      { 'title' => 'Early Book', 'published' => true },
      '/books/early.html',
      'Content.',
    )
    late_book = create_doc(
      { 'title' => 'Late Book', 'published' => true },
      '/books/late.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_captures, early_book, late_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    early_link = forward_links.find { |l| l[:target].url == '/books/early.html' }
    late_link = forward_links.find { |l| l[:target].url == '/books/late.html' }

    refute_nil early_link
    refute_nil late_link

    # With 2 prose variables: first is 0%, second is 50%
    assert_equal 0.0, early_link[:min_position], 'First variable should be at 0%'
    assert_equal 50.0, late_link[:min_position], 'Second of 2 variables should be at 50%'
  end

  def test_single_prose_variable_is_at_zero_percent
    # With only one prose variable, its position is 0% (first of 1 = 0/1 * 100).
    # Capture definitions don't count as variables — only {{ var }} in prose matters.
    book_with_captures = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture target %}{% book_link "Target Book" %}{% endcapture %}

        Some filler text.
        {{ target }} is the only variable in prose.
      CONTENT
    )
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true },
      '/books/target.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_captures, target_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    target_link = forward_links.find { |l| l[:target].url == '/books/target.html' }
    refute_nil target_link

    # Single variable is at 0%
    assert_equal 0.0, target_link[:min_position], 'Single prose variable should be at 0%'
  end

  def test_handles_unused_captures
    # Capture defined but never used in prose — link exists but no scoring data
    book_with_captures = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture unused %}{% book_link "Unused Book" %}{% endcapture %}

        This prose never uses the captured variable.
      CONTENT
    )
    unused_book = create_doc(
      { 'title' => 'Unused Book', 'published' => true },
      '/books/unused.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_captures, unused_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    # Forward link exists from the capture definition (for backlink symmetry)
    # but has no usage scoring — count and min_position are nil
    unused_link = forward_links.find { |l| l[:target].url == '/books/unused.html' }
    refute_nil unused_link, 'Forward link should exist from capture definition'
    assert_nil unused_link[:count], 'Unused capture should have nil count'
    assert_nil unused_link[:min_position], 'Unused capture should have nil min_position'
  end

  def test_direct_link_tags_have_no_usage_scoring
    # Direct {% book_link %} without capture creates forward link but has no usage scoring.
    # The link exists (needed for backlink symmetry) but count/min_position are nil
    # because there's no captured variable to track in prose.
    book_with_direct = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      "I read {% book_link 'Target Book' %} directly.",
    )
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true },
      '/books/target.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_direct, target_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    target_link = forward_links.find { |l| l[:target].url == '/books/target.html' }
    refute_nil target_link, 'Direct link tag should create forward link'
    assert_nil target_link[:count], 'Direct link has no capture-based count'
    assert_nil target_link[:min_position], 'Direct link has no capture-based position'
  end

  def test_mixed_captures_and_direct_links
    # Mix of captured and direct link tags
    book_mixed = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture captured %}{% book_link "Captured Book" %}{% endcapture %}

        I read {{ captured }} via capture. Also {% book_link 'Direct Book' %} inline.
      CONTENT
    )
    captured_book = create_doc(
      { 'title' => 'Captured Book', 'published' => true },
      '/books/captured.html',
      'Content.',
    )
    direct_book = create_doc(
      { 'title' => 'Direct Book', 'published' => true },
      '/books/direct.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_mixed, captured_book, direct_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    captured_link = forward_links.find { |l| l[:target].url == '/books/captured.html' }
    direct_link = forward_links.find { |l| l[:target].url == '/books/direct.html' }

    refute_nil captured_link, 'Captured link should exist'
    refute_nil direct_link, 'Direct link should exist'

    # Captured link should have count from usage
    assert_equal 1, captured_link[:count], 'Captured should have count 1'
  end

  def test_non_link_captures_not_counted
    # Captures that don't contain link tags should not affect forward links
    book_with_text_capture = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture the_beatles %}<span class="band">The Beatles</span>{% endcapture %}
        {% capture target %}{% book_link "Target Book" %}{% endcapture %}

        I like {{ the_beatles }} and also read {{ target }}.
      CONTENT
    )
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true },
      '/books/target.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_text_capture, target_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    # Should only have forward link to target, not to "The Beatles"
    assert_equal 1, forward_links.length, 'Should only have one forward link (to book, not band)'
    assert_equal '/books/target.html', forward_links.first[:target].url
  end

  def test_short_story_link_in_capture
    story_book = create_doc(
      { 'title' => 'Story Collection', 'published' => true },
      '/books/collection.html',
      'Contains short stories.',
    )
    book_with_capture = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture story %}{% short_story_link "The Last Question" from_book="Story Collection" %}{% endcapture %}

        I loved {{ story }}. It's a classic.
      CONTENT
    )

    site = create_site_with_short_stories(
      [story_book, book_with_capture],
      { 'the last question' => [{ 'url' => '/books/collection.html', 'parent_book_title' => 'Story Collection' }] },
    )
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    story_link = forward_links.find { |l| l[:target].url == '/books/collection.html' }
    refute_nil story_link, 'Should have forward link via short story capture'
    assert_equal 'short_story', story_link[:type]
    assert_equal 1, story_link[:count], 'Should count the {{ story }} usage'
  end

  def test_forward_reference_ignored_in_usage_count
    # Liquid renders {{ var }} as empty string when var isn't yet defined.
    # We only count usages that appear AFTER the capture definition,
    # matching Liquid's actual semantics (forward refs render as nothing).
    book_with_forward_ref = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        I read {{ maze }} first (forward reference, renders empty).

        {% capture maze %}{% book_link "A Maze of Death" %}{% endcapture %}

        Then I read {{ maze }} again (this should count).
      CONTENT
    )
    maze_book = create_doc(
      { 'title' => 'A Maze of Death', 'published' => true },
      '/books/maze.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_forward_ref, maze_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    maze_link = forward_links.find { |l| l[:target].url == '/books/maze.html' }
    refute_nil maze_link
    # Only the usage after the capture should count
    assert_equal 1, maze_link[:count], 'Forward reference should not count'
  end

  def test_backlink_entries_lack_scoring_keys
    # Backlinks are sorted alphabetically, not by score.
    # Entries should NOT have count/min_position keys to avoid confusion.
    source_book = create_doc(
      { 'title' => 'Source Book', 'published' => true },
      '/books/source.html',
      <<~CONTENT,
        {% capture target %}{% book_link "Target Book" %}{% endcapture %}

        I mentioned {{ target }} here.
      CONTENT
    )
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true },
      '/books/target.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [source_book, target_book] })
    backlinks = site.data['link_cache']['backlinks']['/books/target.html']

    refute_nil backlinks
    assert_equal 1, backlinks.length

    backlink_entry = backlinks.first
    refute backlink_entry.key?(:count), 'Backlink entries should not have :count key'
    refute backlink_entry.key?(:min_position), 'Backlink entries should not have :min_position key'
  end

  def test_capture_referencing_nonexistent_book_creates_no_forward_link
    # If a capture references a book that doesn't exist, no forward link is created
    book_with_bad_ref = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture ghost %}{% book_link "Nonexistent Book" %}{% endcapture %}

        I tried to reference {{ ghost }} but it doesn't exist.
      CONTENT
    )

    site = create_site({}, { 'books' => [book_with_bad_ref] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    # Should be nil or empty — no valid target to link to
    assert(
      forward_links.nil? || forward_links.empty?,
      'Forward links to nonexistent books should not be created',
    )
  end

  def test_multiple_captures_to_same_book_sums_counts
    # Two different captures pointing to the same book — counts should sum
    book_with_captures = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture maze %}{% book_link "A Maze of Death" %}{% endcapture %}
        {% capture death_book %}{% book_link "A Maze of Death" %}{% endcapture %}

        I read {{ maze }} first. Then {{ death_book }} again. And {{ maze }} once more.
      CONTENT
    )
    maze_book = create_doc(
      { 'title' => 'A Maze of Death', 'published' => true },
      '/books/maze.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_captures, maze_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    # Should have one forward link entry with summed counts
    maze_links = forward_links.select { |l| l[:target].url == '/books/maze.html' }
    assert_equal 1, maze_links.length, 'Should deduplicate to single forward link'

    maze_link = maze_links.first
    assert_equal 3, maze_link[:count], 'Should sum counts from both captures (2 + 1)'
  end

  def test_multiple_captures_to_same_book_uses_earliest_position
    # Two captures to same book — min_position should be from earliest usage
    book_with_captures = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture early %}{% book_link "Target Book" %}{% endcapture %}
        {% capture late %}{% book_link "Target Book" %}{% endcapture %}

        {{ early }} appears first.
        #{'x' * 500}
        {{ late }} appears later.
      CONTENT
    )
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true },
      '/books/target.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_captures, target_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    target_link = forward_links.find { |l| l[:target].url == '/books/target.html' }
    refute_nil target_link
    # min_position should be from the early usage, not the late one
    assert target_link[:min_position] < 30, "min_position #{target_link[:min_position]} should be < 30% (early)"
  end

  # --- Liquid AST parsing tests ---
  # These tests verify behavior that relies on Liquid's AST parser rather than
  # regex. The AST handles multiline, nesting, escaping, and scoping correctly.

  def test_capture_with_conditional_walks_ast_children
    # Liquid AST walks into If nodes to find nested tags.
    # The link exists in the AST regardless of runtime condition.
    book_with_conditional = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture maybe %}{% if page.show_link %}{% book_link "Target Book" %}{% endif %}{% endcapture %}

        I might have read {{ maybe }}.
      CONTENT
    )
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true },
      '/books/target.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_conditional, target_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    target_link = forward_links.find { |l| l[:target].url == '/books/target.html' }
    refute_nil target_link, 'AST should walk into conditionals to find link tags'
    assert_equal 1, target_link[:count]
  end

  def test_nested_capture_extracts_inner_link
    # Nested captures: outer capture contains inner capture with a link.
    # AST naturally handles this — inner capture's link is still found.
    book_with_nested = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture outer %}
          {% capture inner %}{% book_link "Target Book" %}{% endcapture %}
          Wrapper around {{ inner }}.
        {% endcapture %}

        {{ outer }}
      CONTENT
    )
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true },
      '/books/target.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_nested, target_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    target_link = forward_links.find { |l| l[:target].url == '/books/target.html' }
    refute_nil target_link, 'AST should find links in nested captures'
    # Only prose-level usages count. {{ inner }} inside outer's body is template
    # machinery, not a prose mention. Only {{ outer }} in prose counts.
    assert_equal 1, target_link[:count], 'Only prose-level usage should count'
  end

  def test_raw_block_not_parsed_for_captures
    # {% raw %} blocks are not parsed — they render literally.
    # A capture inside raw should NOT create a forward link.
    book_with_raw = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        Here's how to use captures in Liquid:

        {% raw %}
        {% capture example %}{% book_link "Example Book" %}{% endcapture %}
        {{ example }}
        {% endraw %}

        That was just documentation.
      CONTENT
    )
    example_book = create_doc(
      { 'title' => 'Example Book', 'published' => true },
      '/books/example.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_raw, example_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    # Should be nil or empty — raw block content is not parsed
    assert(
      forward_links.nil? || forward_links.empty?,
      'Links inside {% raw %} blocks should not create forward links',
    )
  end

  def test_assign_tag_not_treated_as_capture
    # {% assign %} creates a variable but doesn't contain a block body.
    # Only {% capture %}...{% endcapture %} should be scanned for links.
    book_with_assign = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% assign book_title = "Target Book" %}
        {% capture link %}{% book_link "Target Book" %}{% endcapture %}

        I read {{ link }} (title: {{ book_title }}).
      CONTENT
    )
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true },
      '/books/target.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_assign, target_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    target_link = forward_links.find { |l| l[:target].url == '/books/target.html' }
    refute_nil target_link, 'Capture should create forward link'
    # Only {{ link }} should count, not {{ book_title }}
    assert_equal 1, target_link[:count], 'Only capture variable usage should count'
  end

  def test_variable_with_filters_still_counted
    # {{ var | upcase }} should count as a usage of var.
    # Liquid::Variable nodes have a name and optional filters.
    book_with_filters = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture link %}{% book_link "Target Book" %}{% endcapture %}

        I read {{ link | strip }}.
      CONTENT
    )
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true },
      '/books/target.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_filters, target_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    target_link = forward_links.find { |l| l[:target].url == '/books/target.html' }
    refute_nil target_link
    assert_equal 1, target_link[:count], 'Variable with filters should still count'
  end

  def test_capture_redefinition_uses_latest
    # If a capture is redefined, usages after the redefinition refer to the new value.
    # This matches Liquid semantics — we track the latest definition.
    book_with_redef = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture target %}{% book_link "First Book" %}{% endcapture %}
        {{ target }}

        {% capture target %}{% book_link "Second Book" %}{% endcapture %}
        {{ target }}
      CONTENT
    )
    first_book = create_doc(
      { 'title' => 'First Book', 'published' => true },
      '/books/first.html',
      'Content.',
    )
    second_book = create_doc(
      { 'title' => 'Second Book', 'published' => true },
      '/books/second.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_redef, first_book, second_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    first_link = forward_links.find { |l| l[:target].url == '/books/first.html' }
    second_link = forward_links.find { |l| l[:target].url == '/books/second.html' }

    # Both books should have forward links with count=1 each
    refute_nil first_link, 'First capture definition should create link'
    refute_nil second_link, 'Second capture definition should create link'
    assert_equal 1, first_link[:count], 'First usage before redefinition'
    assert_equal 1, second_link[:count], 'Second usage after redefinition'
  end

  def test_author_link_in_capture
    # Author links should work in captures like book links.
    # Author links point to author pages, not expanded to books like series.
    author_page = create_doc(
      { 'title' => 'Philip K. Dick', 'layout' => 'author_page' },
      '/authors/philip-k-dick.html',
    )
    book_with_author_capture = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture pkd %}{% author_link "Philip K. Dick" %}{% endcapture %}

        {{ pkd }} wrote many great books.
      CONTENT
    )

    site = create_site({}, { 'books' => [book_with_author_capture] }, [author_page])
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    author_link = forward_links&.find { |l| l[:target]&.url == '/authors/philip-k-dick.html' }
    refute_nil author_link, 'Author link in capture should create forward link'
    assert_equal 'author', author_link[:type]
    assert_equal 1, author_link[:count]
  end

  # --- Error handling tests ---
  # Malformed Liquid fails loudly — a broken build is better than silently
  # shipping incomplete backlink data.

  def test_malformed_liquid_raises_fatal_exception
    malformed_book = create_doc(
      { 'title' => 'Malformed', 'published' => true },
      '/books/malformed.html',
      '{% capture unclosed This is broken Liquid.',
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [malformed_book] })
    end

    assert_includes error.message, '/books/malformed.html'
    assert_includes error.message, 'malformed Liquid'
  end

  def test_malformed_liquid_unclosed_if_raises_fatal_exception
    malformed_book = create_doc(
      { 'title' => 'Malformed', 'published' => true },
      '/books/malformed.html',
      "{% if unclosed %}{% book_link 'Target' %}",
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [malformed_book] })
    end

    assert_includes error.message, '/books/malformed.html'
  end

  def test_malformed_liquid_error_includes_syntax_details
    malformed_book = create_doc(
      { 'title' => 'Malformed', 'published' => true },
      '/books/malformed.html',
      '{% for item in %}broken{% endfor %}',
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [malformed_book] })
    end

    # Error message should include Liquid's syntax error details
    assert_includes error.message, 'BacklinkBuilder'
  end

  # --- Liquid internals contract tests ---
  # These tests verify assumptions about Liquid's internal structure.
  # If Liquid changes its ivars in a future version, these tests fail fast.

  def test_liquid_capture_exposes_variable_name
    # BacklinkBuilder accesses @to to get the capture variable name.
    template = Liquid::Template.parse('{% capture foo %}bar{% endcapture %}')
    capture_node = template.root.nodelist.find { |n| n.is_a?(Liquid::Capture) }

    var_name = capture_node.instance_variable_get(:@to)
    assert_equal 'foo',
                 var_name,
                 'Liquid::Capture @to ivar changed — update BacklinkBuilder.process_capture_node'
  end

  def test_liquid_tag_exposes_markup
    # BacklinkBuilder accesses @markup to parse tag arguments.
    Jekyll::Infrastructure::LinkCache::BacklinkBuilder.ensure_stub_tags_registered
    template = Liquid::Template.parse("{% book_link 'Test Title' %}")
    tag_node = template.root.nodelist.find { |n| n.is_a?(Liquid::Tag) && n.tag_name == 'book_link' }

    markup = tag_node.instance_variable_get(:@markup)
    assert_includes markup,
                    'Test Title',
                    'Liquid::Tag @markup ivar changed — update BacklinkBuilder.extract_link_from_tag'
  end

  def test_liquid_variable_exposes_name
    # BacklinkBuilder accesses @name to identify variable usages.
    template = Liquid::Template.parse('{{ my_var }}')
    var_node = template.root.nodelist.find { |n| n.is_a?(Liquid::Variable) }

    name_obj = var_node.instance_variable_get(:@name)
    # @name can be a VariableLookup or String depending on Liquid version
    actual_name = name_obj.is_a?(Liquid::VariableLookup) ? name_obj.name : name_obj
    assert_equal 'my_var',
                 actual_name,
                 'Liquid::Variable @name ivar changed — update BacklinkBuilder.extract_variable_name'
  end

  private

  def rebuild_backlinks(site)
    link_cache = site.data['link_cache']
    maps = Jekyll::Infrastructure::LinkCache::CacheMaps.new(link_cache)
    Jekyll::Infrastructure::LinkCache::BacklinkBuilder.new(site, link_cache, maps).build
  end

  def create_site_with_short_stories(books, short_stories_cache)
    site = create_site({}, { 'books' => books })
    site.data['link_cache']['short_stories'] = short_stories_cache
    rebuild_backlinks(site)
    site
  end
end
