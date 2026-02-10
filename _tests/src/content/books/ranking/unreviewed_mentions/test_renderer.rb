# frozen_string_literal: true

require_relative '../../../../../test_helper'

# Tests for Jekyll::Books::Ranking::UnreviewedMentions::Renderer
#
# Verifies that unreviewed mentions are correctly rendered to HTML.
class TestUnreviewedMentionsRenderer < Minitest::Test
  def test_returns_no_mentions_message_when_empty
    renderer = Jekyll::Books::Ranking::UnreviewedMentions::Renderer.new([])
    result = renderer.render

    assert_includes result, 'No unreviewed works have been mentioned yet.'
    assert_includes result, '<p>'
  end

  def test_renders_ordered_list
    mentions = [{ title: 'Book One', count: 3 }]
    renderer = Jekyll::Books::Ranking::UnreviewedMentions::Renderer.new(mentions)
    result = renderer.render

    assert_includes result, '<ol class="ranked-list">'
    assert_includes result, '</ol>'
  end

  def test_renders_cite_element
    mentions = [{ title: 'Book One', count: 2 }]
    renderer = Jekyll::Books::Ranking::UnreviewedMentions::Renderer.new(mentions)
    result = renderer.render

    assert_includes result, '<cite>Book One</cite>'
  end

  def test_renders_mention_count
    mentions = [{ title: 'Book One', count: 5 }]
    renderer = Jekyll::Books::Ranking::UnreviewedMentions::Renderer.new(mentions)
    result = renderer.render

    assert_includes result, '<span class="mention-count">(5 mentions)</span>'
  end

  def test_uses_singular_for_one_mention
    mentions = [{ title: 'Book One', count: 1 }]
    renderer = Jekyll::Books::Ranking::UnreviewedMentions::Renderer.new(mentions)
    result = renderer.render

    assert_includes result, '(1 mention)'
    refute_includes result, '(1 mentions)'
  end

  def test_uses_plural_for_multiple_mentions
    mentions = [{ title: 'Book One', count: 2 }]
    renderer = Jekyll::Books::Ranking::UnreviewedMentions::Renderer.new(mentions)
    result = renderer.render

    assert_includes result, '(2 mentions)'
  end

  def test_renders_multiple_items
    mentions = [
      { title: 'First Book', count: 10 },
      { title: 'Second Book', count: 5 },
      { title: 'Third Book', count: 1 }
    ]
    renderer = Jekyll::Books::Ranking::UnreviewedMentions::Renderer.new(mentions)
    result = renderer.render

    assert_includes result, 'First Book'
    assert_includes result, 'Second Book'
    assert_includes result, 'Third Book'
    assert_equal 3, result.scan('<li>').length
  end

  def test_escapes_html_in_title
    mentions = [{ title: 'Book <script>alert("xss")</script>', count: 1 }]
    renderer = Jekyll::Books::Ranking::UnreviewedMentions::Renderer.new(mentions)
    result = renderer.render

    refute_includes result, '<script>'
    assert_includes result, '&lt;script&gt;'
  end

  def test_list_item_structure
    mentions = [{ title: 'Test Book', count: 3 }]
    renderer = Jekyll::Books::Ranking::UnreviewedMentions::Renderer.new(mentions)
    result = renderer.render

    assert_includes result, '<li><cite>Test Book</cite> <span class="mention-count">(3 mentions)</span></li>'
  end
end
