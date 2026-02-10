# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::Infrastructure::LinkCache::ShortStoryBuilder
#
# Verifies that short stories are correctly extracted from anthology books.
class TestShortStoryBuilder < Minitest::Test
  def test_extracts_short_stories_from_anthology
    anthology = create_doc(
      { 'title' => 'Story Collection', 'published' => true, 'is_anthology' => true },
      '/books/collection.html',
      "## {% short_story_title 'The Last Question' %}\n\nStory content."
    )

    site = create_site({}, { 'books' => [anthology] })
    stories = site.data['link_cache']['short_stories']

    refute_nil stories['the last question']
    assert_equal 1, stories['the last question'].length
    assert_equal 'The Last Question', stories['the last question'].first['title']
  end

  def test_stores_parent_book_info
    anthology = create_doc(
      { 'title' => 'Nine Tomorrows', 'published' => true, 'is_anthology' => true },
      '/books/nine-tomorrows.html',
      "## {% short_story_title 'The Last Question' %}"
    )

    site = create_site({}, { 'books' => [anthology] })
    story = site.data['link_cache']['short_stories']['the last question'].first

    assert_equal 'Nine Tomorrows', story['parent_book_title']
    assert_equal '/books/nine-tomorrows.html', story['url']
  end

  def test_generates_slug_for_story
    anthology = create_doc(
      { 'title' => 'Collection', 'published' => true, 'is_anthology' => true },
      '/books/collection.html',
      "## {% short_story_title 'The Last Question' %}"
    )

    site = create_site({}, { 'books' => [anthology] })
    story = site.data['link_cache']['short_stories']['the last question'].first

    assert_equal 'the-last-question', story['slug']
  end

  def test_handles_multiple_stories_in_one_book
    anthology = create_doc(
      { 'title' => 'Collection', 'published' => true, 'is_anthology' => true },
      '/books/collection.html',
      "## {% short_story_title 'Story One' %}\n\n## {% short_story_title 'Story Two' %}"
    )

    site = create_site({}, { 'books' => [anthology] })
    stories = site.data['link_cache']['short_stories']

    refute_nil stories['story one']
    refute_nil stories['story two']
  end

  def test_handles_same_story_in_multiple_books
    anthology_a = create_doc(
      { 'title' => 'Collection A', 'published' => true, 'is_anthology' => true },
      '/books/a.html',
      "## {% short_story_title 'Famous Story' %}"
    )
    anthology_b = create_doc(
      { 'title' => 'Collection B', 'published' => true, 'is_anthology' => true },
      '/books/b.html',
      "## {% short_story_title 'Famous Story' %}"
    )

    site = create_site({}, { 'books' => [anthology_a, anthology_b] })
    stories = site.data['link_cache']['short_stories']['famous story']

    assert_equal 2, stories.length
  end

  def test_ignores_non_anthology_books
    regular_book = create_doc(
      { 'title' => 'Regular Book', 'published' => true },
      '/books/regular.html',
      "## {% short_story_title 'Hidden Story' %}"
    )

    site = create_site({}, { 'books' => [regular_book] })
    stories = site.data['link_cache']['short_stories']

    assert_empty stories
  end

  def test_ignores_unpublished_anthologies
    unpublished = create_doc(
      { 'title' => 'Draft Anthology', 'published' => false, 'is_anthology' => true },
      '/books/draft.html',
      "## {% short_story_title 'Draft Story' %}"
    )

    site = create_site({}, { 'books' => [unpublished] })
    stories = site.data['link_cache']['short_stories']

    assert_empty stories
  end

  def test_handles_double_quoted_titles
    anthology = create_doc(
      { 'title' => 'Collection', 'published' => true, 'is_anthology' => true },
      '/books/collection.html',
      '## {% short_story_title "Double Quoted" %}'
    )

    site = create_site({}, { 'books' => [anthology] })
    stories = site.data['link_cache']['short_stories']

    refute_nil stories['double quoted']
  end

  def test_requires_heading_prefix
    anthology = create_doc(
      { 'title' => 'Collection', 'published' => true, 'is_anthology' => true },
      '/books/collection.html',
      "{% short_story_title 'Not In Heading' %}"
    )

    site = create_site({}, { 'books' => [anthology] })
    stories = site.data['link_cache']['short_stories']

    # Should not match without heading prefix
    assert_empty stories
  end

  def test_ignores_no_id_stories
    anthology = create_doc(
      { 'title' => 'Collection', 'published' => true, 'is_anthology' => true },
      '/books/collection.html',
      "## {% short_story_title 'Skip This' no_id %}"
    )

    site = create_site({}, { 'books' => [anthology] })
    stories = site.data['link_cache']['short_stories']

    assert_empty stories
  end

  def test_handles_various_heading_levels
    anthology = create_doc(
      { 'title' => 'Collection', 'published' => true, 'is_anthology' => true },
      '/books/collection.html',
      "# {% short_story_title 'H1 Story' %}\n### {% short_story_title 'H3 Story' %}"
    )

    site = create_site({}, { 'books' => [anthology] })
    stories = site.data['link_cache']['short_stories']

    refute_nil stories['h1 story']
    refute_nil stories['h3 story']
  end

  def test_handles_missing_books_collection
    site = create_site({}, {}, [])
    stories = site.data['link_cache']['short_stories']

    assert_empty stories
  end

  def test_skips_anthology_without_title
    anthology = create_doc(
      { 'title' => nil, 'published' => true, 'is_anthology' => true },
      '/books/no-title.html',
      "## {% short_story_title 'Orphan Story' %}"
    )

    site = create_site({}, { 'books' => [anthology] })
    stories = site.data['link_cache']['short_stories']

    assert_empty stories
  end
end
