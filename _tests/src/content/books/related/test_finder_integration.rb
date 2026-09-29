# frozen_string_literal: true

require_relative '../../../../support/related_book_finder_test_case'

# BacklinkBuilder-to-Finder integration with real Liquid content.
class TestRelatedBooksFinderIntegration < RelatedBookFinderTestCase
  # --- Integration test: full pipeline with Liquid tags ---

  def test_integration_finder_uses_backlink_builder_output
    # This test runs the full pipeline: books with Liquid tags → BacklinkBuilder → Finder
    # Verifies the contract between how BacklinkBuilder stores entries and Finder reads them.
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      "Current book that mentions {% book_link 'Mentioned Book' %}.",
    )
    mentioned = create_doc(
      {
        'title' => 'Mentioned Book',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/mentioned.html',
      'A book that gets mentioned.',
    )
    mentioner = create_doc(
      {
        'title' => 'Mentioner Book',
        'book_authors' => ['Author C'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 3),
      },
      '/books/mentioner.html',
      "This book mentions {% book_link 'Current Book' %}.",
    )

    # create_site runs LinkCacheGenerator which runs BacklinkBuilder
    site = create_site(@site_config_base.dup, { 'books' => [curr, mentioned, mentioner] })

    # Verify BacklinkBuilder populated the caches (guards against test helper changes)
    forward_links = site.data.dig('link_cache', 'forward_links', curr.url)
    backlinks = site.data.dig('link_cache', 'backlinks', curr.url)
    refute_nil forward_links, 'BacklinkBuilder should populate forward_links for curr'
    refute_nil backlinks, 'BacklinkBuilder should populate backlinks for curr'
    assert forward_links.any? { |e| e[:target].url == mentioned.url }, 'forward_links should include mentioned book'
    assert backlinks.any? { |e| e[:source].url == mentioner.url }, 'backlinks should include mentioner book'

    finder = Jekyll::Books::Related::Finder.new(site, curr, 3)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    # Verify Finder correctly reads both forward_links and backlinks
    assert_equal 2, result[:books].length
    urls = result[:books].map(&:url)
    assert_includes urls, '/books/mentioned.html', 'Should include forward-linked book'
    assert_includes urls, '/books/mentioner.html', 'Should include backlinking book'
  end

  # --- End-to-end integration tests (raw content → BacklinkBuilder → Finder) ---

  def test_e2e_capture_usage_count_affects_ranking
    # Full pipeline: captures with different usage counts → BacklinkBuilder → Finder ranking
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      <<~CONTENT,
        {% capture often %}{% book_link "Often Mentioned" %}{% endcapture %}
        {% capture once %}{% book_link "Once Mentioned" %}{% endcapture %}

        I read {{ often }} first. Then {{ often }} again. And {{ often }} a third time.
        Also {{ once }} appeared briefly.
      CONTENT
    )
    often_book = create_doc(
      {
        'title' => 'Often Mentioned',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/often.html',
      'Content.',
    )
    once_book = create_doc(
      {
        'title' => 'Once Mentioned',
        'book_authors' => ['Author C'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/once.html',
      'Content.',
    )

    site = create_site(@site_config_base.dup, { 'books' => [curr, often_book, once_book] })
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Often (count=3) should rank before once (count=1)
    assert_equal '/books/often.html', result[:books][0].url, 'Higher mention count should rank first'
    assert_equal '/books/once.html', result[:books][1].url
  end

  def test_e2e_earlier_position_breaks_tie_before_title
    # The later mention sorts first by title, so only position can put the earlier mention first.
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      <<~CONTENT,
        {% capture early %}{% book_link "Zebra Book" %}{% endcapture %}
        {% capture late %}{% book_link "Alpha Book" %}{% endcapture %}

        {{ early }} is discussed substantively here at the start.
        #{'x' * 1000}
        {{ late }} is just a future-reads mention at the very end.
      CONTENT
    )
    early_book = create_doc(
      {
        'title' => 'Zebra Book',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/early.html',
      'Content.',
    )
    late_book = create_doc(
      {
        'title' => 'Alpha Book',
        'book_authors' => ['Author C'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/late.html',
      'Content.',
    )

    site = create_site(@site_config_base.dup, { 'books' => [curr, early_book, late_book] })
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # The earlier mention wins the position tiebreaker.
    assert_equal '/books/early.html', result[:books][0].url, 'Early mention should rank before penalized late mention'
    assert_equal '/books/late.html', result[:books][1].url
  end

  def test_e2e_unused_capture_ranks_below_used_capture
    # Capture defined but never used in prose → scores 0 → ranks below used captures
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      <<~CONTENT,
        {% capture used %}{% book_link "Used Book" %}{% endcapture %}
        {% capture unused %}{% book_link "Unused Book" %}{% endcapture %}

        I really enjoyed {{ used }}. Great read.
      CONTENT
    )
    used_book = create_doc(
      {
        'title' => 'Used Book',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 20),
      },
      '/books/used.html',
      'Content.',
    )
    unused_book = create_doc(
      {
        'title' => 'Unused Book',
        'book_authors' => ['Author C'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/unused.html',
      'Content.',
    )

    site = create_site(@site_config_base.dup, { 'books' => [curr, used_book, unused_book] })
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Used (count=1, score=1) ranks before unused (count=nil, score=0)
    # Even though unused_book is more recent
    assert_equal '/books/used.html', result[:books][0].url, 'Used capture should rank before unused'
    assert_equal '/books/unused.html', result[:books][1].url
  end

  def test_e2e_multiple_captures_to_same_book_aggregate
    # Two captures pointing to the same book → counts sum → higher score
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      <<~CONTENT,
        {% capture maze %}{% book_link "A Maze of Death" %}{% endcapture %}
        {% capture death %}{% book_link "A Maze of Death" %}{% endcapture %}
        {% capture other %}{% book_link "Other Book" %}{% endcapture %}

        I read {{ maze }} first. Then {{ death }} reference. And {{ maze }} again.
        Also {{ other }} once.
      CONTENT
    )
    maze_book = create_doc(
      {
        'title' => 'A Maze of Death',
        'book_authors' => ['PKD'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/maze.html',
      'Content.',
    )
    other_book = create_doc(
      {
        'title' => 'Other Book',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/other.html',
      'Content.',
    )

    site = create_site(@site_config_base.dup, { 'books' => [curr, maze_book, other_book] })
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Maze (count=3 from {{ maze }}x2 + {{ death }}x1) ranks before other (count=1)
    assert_equal '/books/maze.html', result[:books][0].url, 'Aggregated counts should rank higher'
    assert_equal '/books/other.html', result[:books][1].url
  end

  def test_e2e_direct_link_scores_zero
    # Direct {% book_link %} without capture has no usage scoring → scores 0
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      <<~CONTENT,
        {% capture captured %}{% book_link "Captured Book" %}{% endcapture %}

        I read {{ captured }} via capture.
        Also {% book_link 'Direct Book' %} inline.
      CONTENT
    )
    captured_book = create_doc(
      {
        'title' => 'Captured Book',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 20),
      },
      '/books/captured.html',
      'Content.',
    )
    direct_book = create_doc(
      {
        'title' => 'Direct Book',
        'book_authors' => ['Author C'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/direct.html',
      'Content.',
    )

    site = create_site(@site_config_base.dup, { 'books' => [curr, captured_book, direct_book] })
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Captured (count=1) ranks before direct (count=nil, score=0)
    assert_equal '/books/captured.html', result[:books][0].url, 'Captured link should rank before direct link'
    assert_equal '/books/direct.html', result[:books][1].url
  end

  def test_e2e_forward_link_tier_precedes_backlink_tier
    # Forward links (with scoring) appear before backlinks (alphabetical only)
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      <<~CONTENT,
        {% capture forward %}{% book_link "Forward Book" %}{% endcapture %}

        I discussed {{ forward }} in this review.
      CONTENT
    )
    forward_book = create_doc(
      {
        'title' => 'Forward Book',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 30),
      },
      '/books/forward.html',
      'Content.',
    )
    backlink_book = create_doc(
      {
        'title' => 'AAA Backlink Book',
        'book_authors' => ['Author C'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 1),
      },
      '/books/backlink.html',
      "This book mentions {% book_link 'Current Book' %}.",
    )

    site = create_site(@site_config_base.dup, { 'books' => [curr, forward_book, backlink_book] })
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Forward link tier comes before backlink tier, regardless of date or alphabetical order
    assert_equal '/books/forward.html', result[:books][0].url, 'Forward link should precede backlink'
    assert_equal '/books/backlink.html', result[:books][1].url
  end

  def test_e2e_deduplication_forward_and_backlink_same_book
    # Book appears in both forward and backlink → should only appear once (forward tier wins)
    book_a = create_doc(
      {
        'title' => 'Book A',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/a.html',
      <<~CONTENT,
        {% capture b %}{% book_link "Book B" %}{% endcapture %}

        I mentioned {{ b }} here.
      CONTENT
    )
    book_b = create_doc(
      {
        'title' => 'Book B',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/b.html',
      <<~CONTENT,
        {% capture a %}{% book_link "Book A" %}{% endcapture %}

        I also mentioned {{ a }} in return.
      CONTENT
    )

    site = create_site(@site_config_base.dup, { 'books' => [book_a, book_b] })
    finder = Jekyll::Books::Related::Finder.new(site, book_a, 5)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    # Book B appears in forward_links AND backlinks for Book A
    # Should only appear once
    assert_equal 1, result[:books].length, 'Book B should appear only once despite being in both caches'
    assert_equal '/books/b.html', result[:books][0].url
  end

  def test_e2e_nested_capture_counts_only_prose_usage
    # Nested captures: inner used inside outer, outer used in prose.
    # Only prose-level usage ({{ outer }}) counts, not {{ inner }} inside outer's body.
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      <<~CONTENT,
        {% capture inner %}{% book_link "Nested Book" %}{% endcapture %}
        {% capture outer %}Wrapper: {{ inner }}.{% endcapture %}
        {% capture direct %}{% book_link "Direct Book" %}{% endcapture %}

        I read {{ outer }} and {{ direct }}.
      CONTENT
    )
    nested_book = create_doc(
      {
        'title' => 'Nested Book',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/nested.html',
      'Content.',
    )
    direct_book = create_doc(
      {
        'title' => 'Direct Book',
        'book_authors' => ['Author C'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/direct.html',
      'Content.',
    )

    site = create_site(@site_config_base.dup, { 'books' => [curr, nested_book, direct_book] })
    finder = Jekyll::Books::Related::Finder.new(site, curr, 2)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    assert_equal 2, result[:books].length
    # Both have count=1 (only prose-level {{ outer }} and {{ direct }} count).
    # {{ inner }} inside outer's body is template machinery, not a prose mention.
    # With equal scores, they tie-break by date (same), then alphabetically.
    urls = result[:books].map(&:url)
    assert_includes urls, '/books/nested.html'
    assert_includes urls, '/books/direct.html'
  end

  def test_e2e_raw_block_content_not_parsed
    # Links inside {% raw %} blocks should not create forward links.
    curr = create_doc(
      {
        'title' => 'Current Book',
        'book_authors' => ['Author A'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 10),
      },
      '/books/current.html',
      <<~CONTENT,
        {% capture real %}{% book_link "Real Book" %}{% endcapture %}

        I read {{ real }}.

        Here's example Liquid syntax:
        {% raw %}
        {% capture example %}{% book_link "Example Book" %}{% endcapture %}
        {{ example }}
        {% endraw %}
      CONTENT
    )
    real_book = create_doc(
      {
        'title' => 'Real Book',
        'book_authors' => ['Author B'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/real.html',
      'Content.',
    )
    example_book = create_doc(
      {
        'title' => 'Example Book',
        'book_authors' => ['Author C'],
        'published' => true,
        'date' => @test_time_now - (60 * 60 * 24 * 5),
      },
      '/books/example.html',
      'Content.',
    )

    site = create_site(@site_config_base.dup, { 'books' => [curr, real_book, example_book] })
    # Use max_books=1 to test only forward links tier (not recent tier fallback)
    finder = Jekyll::Books::Related::Finder.new(site, curr, 1)
    result = nil
    Time.stub :now, @test_time_now do
      result = finder.find
    end

    # Only real_book should appear; example_book is inside {% raw %}
    assert_equal 1, result[:books].length, 'Only non-raw links should create forward links'
    assert_equal '/books/real.html', result[:books][0].url
  end
end
