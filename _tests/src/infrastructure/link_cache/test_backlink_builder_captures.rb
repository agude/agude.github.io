# frozen_string_literal: true

require_relative '../../../support/backlink_builder_test_support'

# Capture usage, positions, and link score behavior.
class TestBacklinkBuilderCaptures < BacklinkBuilderTestCase
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

  def test_captures_with_no_targets_do_not_inflate_subsequent_capture_counts
    # Regression test: captures that resolve to nothing (self-referential, unreviewed books)
    # should not have their prose usages attributed to the next valid capture.
    #
    # Bug scenario: {% capture this_book %}{% book_link page.title %}{% endcapture %}
    # resolves to self (excluded), but {{ this_book }} usages were counted against
    # the next capture that DID have valid targets.
    book_with_captures = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture this_book %}{% book_link "Review" %}{% endcapture %}
        {% capture other %}{% book_link "Other Book" %}{% endcapture %}

        I mention {{ this_book }} many times. Like {{ this_book }} here.
        And {{ this_book }} again. But {{ other }} only once.
      CONTENT
    )
    other_book = create_doc(
      { 'title' => 'Other Book', 'published' => true },
      '/books/other.html',
      'Content.',
    )

    # NOTE: "Review" book_link resolves to the current doc (self-referential, excluded)
    site = create_site({}, { 'books' => [book_with_captures, other_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    other_link = forward_links.find { |l| l[:target].url == '/books/other.html' }
    refute_nil other_link

    # The 3 usages of {{ this_book }} should NOT inflate {{ other }}'s count
    assert_equal(
      1,
      other_link[:count],
      'Usages of captures with no targets should not inflate other captures',
    )
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

  def test_book_link_and_short_story_link_without_from_book_merge_counts
    # Reproduces real scenario: Neuromancer links to both "Hyperion" (book_link)
    # AND "The Detective's Tale" (short_story_link without from_book).
    # Both resolve to Hyperion's URL and should merge: type=book, counts summed.
    hyperion = create_doc(
      { 'title' => 'Hyperion', 'published' => true },
      '/books/hyperion.html',
      'An anthology.',
    )
    review = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}
        {% capture detectives_tale %}{% short_story_link "The Detective's Tale" %}{% endcapture %}

        I mention {{ hyperion }} here.
        And {{ detectives_tale }} there.
      CONTENT
    )

    # Short story without from_book resolves when all locs have same URL
    site = create_site_with_short_stories(
      [hyperion, review],
      { "the detective's tale" => [{ 'url' => '/books/hyperion.html', 'parent_book_title' => 'Hyperion' }] },
    )
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    hyperion_link = forward_links.find { |l| l[:target].url == '/books/hyperion.html' }
    refute_nil hyperion_link, 'Should have forward link to Hyperion'

    # book_link (priority 4) > short_story (priority 2), so type should be 'book'
    assert_equal 'book', hyperion_link[:type], 'Direct book_link should set type to book'

    # Counts should merge: 1 from {{ hyperion }} + 1 from {{ detectives_tale }} = 2
    assert_equal 2, hyperion_link[:count], 'Should merge counts from book_link and short_story_link'
  end

  def test_book_link_resolves_to_canonical_not_archived_review
    # Book families: "Hyperion" has a canonical page and an archived re-review.
    # book_link should resolve to the canonical URL, not the archived one.
    canonical = create_doc(
      { 'title' => 'Hyperion', 'published' => true },
      '/books/hyperion.html',
      'Canonical review.',
    )
    archived = create_doc(
      {
        'title' => 'Hyperion',
        'published' => true,
        'canonical_url' => '/books/hyperion.html',
      },
      '/books/hyperion/review-2023.html',
      'Older review.',
    )
    review = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      'I read {% book_link "Hyperion" %}.',
    )

    site = create_site({}, { 'books' => [canonical, archived, review] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    hyperion_link = forward_links.find { |l| l[:target].url == '/books/hyperion.html' }
    archived_link = forward_links.find { |l| l[:target].url == '/books/hyperion/review-2023.html' }

    refute_nil hyperion_link, 'Should link to canonical Hyperion page'
    assert_nil archived_link, 'Should NOT link to archived review'
  end

  def test_book_family_book_link_and_short_story_merge_to_canonical
    # Full book-family scenario: canonical anthology + archived re-review.
    # book_link and short_story_link should both resolve to the canonical URL
    # and merge their counts.
    canonical = create_doc(
      { 'title' => 'Hyperion', 'published' => true, 'is_anthology' => true },
      '/books/hyperion.html',
      "## {% short_story_title \"The Detective's Tale\" %}\n\nStory content.",
    )
    archived = create_doc(
      {
        'title' => 'Hyperion',
        'published' => true,
        'is_anthology' => true,
        'canonical_url' => '/books/hyperion.html',
      },
      '/books/hyperion/review-2023.html',
      "## {% short_story_title \"The Detective's Tale\" %}\n\nOlder review.",
    )
    review = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture hyperion %}{% book_link "Hyperion" %}{% endcapture %}
        {% capture detectives_tale %}{% short_story_link "The Detective's Tale" %}{% endcapture %}

        I mention {{ hyperion }} here.
        And {{ detectives_tale }} there.
      CONTENT
    )

    # Don't inject short_stories manually — let the real ShortStoryBuilder run
    # so we test the full pipeline including canonical_url filtering.
    site = create_site({}, { 'books' => [canonical, archived, review] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    hyperion_link = forward_links.find { |l| l[:target].url == '/books/hyperion.html' }
    refute_nil hyperion_link, 'Should have forward link to canonical Hyperion'

    assert_equal 'book', hyperion_link[:type], 'book_link priority should win'
    assert_equal 2,
                 hyperion_link[:count],
                 'Should merge counts: 1 from book_link + 1 from short_story_link'

    archived_link = forward_links.find { |l| l[:target].url == '/books/hyperion/review-2023.html' }
    assert_nil archived_link, 'Should NOT have forward link to archived review'
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

  def test_backlink_entries_accumulate_usage_scoring
    # Backlinks include scoring data (count/min_position) so they can be ranked
    # by how much the source talks about the target.
    source_book = create_doc(
      { 'title' => 'Source Book', 'published' => true },
      '/books/source.html',
      <<~CONTENT,
        {% capture target %}{% book_link "Target Book" %}{% endcapture %}

        I mentioned {{ target }} here. And {{ target }} again.
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
    assert backlink_entry.key?(:count), 'Backlink entries should have :count key'
    assert backlink_entry.key?(:min_position), 'Backlink entries should have :min_position key'
    assert_equal 2, backlink_entry[:count], 'Should accumulate usages from source'
  end

  def test_backlink_scores_merge_across_multiple_captures
    # When Source has multiple captures pointing to Target (e.g., book_link and
    # author_link both resolving to the same book), scores should merge.
    source_book = create_doc(
      { 'title' => 'Source Book', 'published' => true },
      '/books/source.html',
      <<~CONTENT,
        {% capture via_book %}{% book_link "Target Book" %}{% endcapture %}
        {% capture via_series %}{% series_link "Target Series" %}{% endcapture %}

        First {{ via_book }}. Then {{ via_series }}. And {{ via_book }} again.
      CONTENT
    )
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true, 'series' => 'Target Series' },
      '/books/target.html',
      'Content.',
    )
    series_page = create_doc(
      { 'title' => 'Target Series', 'layout' => 'series_page' },
      '/series/target.html',
    )

    site = create_site({}, { 'books' => [source_book, target_book] }, [series_page])
    backlinks = site.data['link_cache']['backlinks']['/books/target.html']

    refute_nil backlinks
    assert_equal 1, backlinks.length, 'Should deduplicate to single backlink entry'

    backlink_entry = backlinks.first
    # via_book used twice (idx 0, 2), via_series used once (idx 1) → total 3
    assert_equal 3, backlink_entry[:count], 'Should merge counts from both captures'
    # book_link (priority 4) > series_link (priority 1)
    assert_equal 'book', backlink_entry[:type], 'Should use highest priority type'
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
end
