# frozen_string_literal: true

require_relative '../../../support/backlink_builder_test_support'

# Direct book, series, and short-story link behavior.
class TestBacklinkBuilder < BacklinkBuilderTestCase
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

  def test_direct_min_position_set_for_book_links
    # When a book is linked via both series_link and book_link, direct_min_position
    # should track the book_link position separately from min_position.
    review = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture series %}{% series_link "Test Series" %}{% endcapture %}
        {% capture book1 %}{% book_link "Book One" %}{% endcapture %}
        {% capture book2 %}{% book_link "Book Two" %}{% endcapture %}

        The {{ series }} is great.
        I especially liked {{ book1 }}.
        And later {{ book2 }}.
      CONTENT
    )
    book1 = create_doc(
      { 'title' => 'Book One', 'published' => true, 'series' => 'Test Series' },
      '/books/book1.html',
      'First.',
    )
    book2 = create_doc(
      { 'title' => 'Book Two', 'published' => true, 'series' => 'Test Series' },
      '/books/book2.html',
      'Second.',
    )
    series_page = create_doc(
      { 'title' => 'Test Series', 'layout' => 'series_page' },
      '/series/test.html',
    )

    site = create_site({}, { 'books' => [review, book1, book2] }, [series_page])
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    book1_link = forward_links.find { |l| l[:target].url == '/books/book1.html' }
    book2_link = forward_links.find { |l| l[:target].url == '/books/book2.html' }

    # Both books have same min_position (from series link which appears first)
    assert_equal(
      book1_link[:min_position],
      book2_link[:min_position],
      'Series link should give both books the same min_position',
    )

    # But direct_min_position differs based on individual book_link positions
    refute_nil book1_link[:direct_min_position]
    refute_nil book2_link[:direct_min_position]
    assert_operator(
      book1_link[:direct_min_position],
      :<,
      book2_link[:direct_min_position],
      'Book One direct position should be earlier than Book Two',
    )
  end

  def test_short_story_link_sets_direct_min_position
    # Short story links should also set direct_min_position since they're direct references.
    review = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture story %}{% short_story_link "Test Story" from_book="Anthology" %}{% endcapture %}

        I loved {{ story }}.
      CONTENT
    )
    anthology = create_doc(
      { 'title' => 'Anthology', 'published' => true },
      '/books/anthology.html',
      'Stories.',
    )

    site = create_site_with_short_stories(
      [review, anthology],
      { 'test story' => [{ 'url' => '/books/anthology.html', 'parent_book_title' => 'Anthology' }] },
    )
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    story_link = forward_links.find { |l| l[:target].url == '/books/anthology.html' }
    refute_nil story_link[:direct_min_position],
               'Short story links should set direct_min_position'
  end

  def test_multiple_link_types_to_same_target
    # When book_link, series_link, and short_story_link all point to the same book,
    # they should merge correctly: type=book (highest priority), counts add up,
    # and direct_min_position comes from book/short_story links only.
    review = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture series %}{% series_link "Anthology Series" %}{% endcapture %}
        {% capture book %}{% book_link "Anthology" %}{% endcapture %}
        {% capture story %}{% short_story_link "Featured Story" from_book="Anthology" %}{% endcapture %}

        First {{ series }} mention.
        Then {{ book }} directly.
        And {{ story }} too.
        Back to {{ series }} again.
      CONTENT
    )
    anthology = create_doc(
      { 'title' => 'Anthology', 'published' => true, 'series' => 'Anthology Series' },
      '/books/anthology.html',
      'Stories.',
    )
    series_page = create_doc(
      { 'title' => 'Anthology Series', 'layout' => 'series_page' },
      '/series/anthology.html',
    )

    site = create_site_with_short_stories(
      [review, anthology],
      { 'featured story' => [{ 'url' => '/books/anthology.html', 'parent_book_title' => 'Anthology' }] },
      [series_page],
    )
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    anthology_link = forward_links.find { |l| l[:target].url == '/books/anthology.html' }
    refute_nil anthology_link

    # Type should be 'book' (highest priority)
    assert_equal 'book', anthology_link[:type]

    # Count should include all: 2 series + 1 book + 1 short_story = 4
    assert_equal 4, anthology_link[:count]

    # min_position from series (earliest), direct_min_position from book link
    refute_nil anthology_link[:min_position]
    refute_nil anthology_link[:direct_min_position]
    assert_operator(
      anthology_link[:min_position],
      :<,
      anthology_link[:direct_min_position],
      'Series appears first, so min_position < direct_min_position',
    )
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

  def test_double_quoted_title_with_apostrophe
    # The old regex /['"]([^'"]+)['"]/ treated apostrophes as closing quotes,
    # truncating "Ender's Game" to "Ender". The fix uses separate patterns
    # for single and double quotes so internal apostrophes are preserved.
    target = create_doc(
      { 'title' => "Ender's Game", 'published' => true },
      '/books/enders-game.html',
      'Content.',
    )
    review = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      'I read {% book_link "Ender\'s Game" %}.',
    )

    site = create_site({}, { 'books' => [target, review] })
    backlinks = site.data['link_cache']['backlinks']

    assert_equal 1,
                 (backlinks['/books/enders-game.html'] || []).length,
                 'Apostrophe in double-quoted title should not break quote parsing'
  end

  def test_apostrophe_in_short_story_title_resolves
    anthology = create_doc(
      { 'title' => 'Anthology', 'published' => true },
      '/books/anthology.html',
      'Stories.',
    )
    review = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      %q(I read {% short_story_link "The Priest's Tale" from_book="Anthology" %}.),
    )

    site = create_site_with_short_stories(
      [anthology, review],
      { "the priest's tale" => [{ 'url' => '/books/anthology.html', 'parent_book_title' => 'Anthology' }] },
    )
    backlinks = site.data['link_cache']['backlinks']

    assert_equal 1,
                 (backlinks['/books/anthology.html'] || []).length,
                 'Apostrophe in short story title should resolve correctly'
  end

  def test_apostrophe_in_series_name_resolves
    series_book = create_doc(
      { 'title' => 'First Book', 'published' => true, 'series' => "The King's War" },
      '/books/first.html',
      'Content.',
    )
    review = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      %q(I love {% series_link "The King's War" %}.),
    )
    series_page = create_doc(
      { 'title' => "The King's War", 'layout' => 'series_page' },
      '/series/the-kings-war.html',
    )

    site = create_site({}, { 'books' => [series_book, review] }, [series_page])
    backlinks = site.data['link_cache']['backlinks']

    assert_equal 1,
                 (backlinks['/books/first.html'] || []).length,
                 'Apostrophe in series name should not break quote parsing'
  end

  def test_apostrophe_in_author_name_resolves
    author_page = create_doc(
      { 'title' => "Patrick O'Brian", 'layout' => 'author_page' },
      "/authors/patrick-o'brian.html",
    )
    review = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      %q(By {% author_link "Patrick O'Brian" %}.),
    )

    site = create_site({}, { 'books' => [review] }, [author_page])
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    author_link = forward_links&.find { |l| l[:target]&.url == "/authors/patrick-o'brian.html" }
    refute_nil author_link, 'Apostrophe in author name should resolve correctly'
    assert_equal 'author', author_link[:type]
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
end
