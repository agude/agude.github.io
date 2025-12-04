# frozen_string_literal: true

# _tests/plugins/test_display_unreviewed_mentions_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/tags/display_unreviewed_mentions_tag'

# Tests for Jekyll::Books::Ranking::UnreviewedMentions::DisplayUnreviewedMentions::Finder class.
#
# Verifies the data retrieval and filtering logic.
class TestDisplayUnreviewedMentionsFinder < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current.md' }, '/current.html') })

    # Pre-populate the caches for tests
    @site.data['link_cache']['books'] = {
      'existing book' => [{ 'url' => '/books/existing.html', 'title' => 'Existing Book', 'authors' => [] }]
    }
  end

  def test_find_returns_correct_structure
    setup_mention_tracker_data

    finder = Jekyll::Books::Ranking::UnreviewedMentions::DisplayUnreviewedMentions::Finder.new(@context)
    result = finder.find

    assert_instance_of Hash, result
    assert_includes result.keys, :logs
    assert_includes result.keys, :mentions
    assert_instance_of String, result[:logs]
    assert_instance_of Array, result[:mentions]
  end

  def test_find_returns_sorted_mentions
    setup_mention_tracker_data

    finder = Jekyll::Books::Ranking::UnreviewedMentions::DisplayUnreviewedMentions::Finder.new(@context)
    result = finder.find

    mentions = result[:mentions]
    assert_equal 3, mentions.size

    # Should be sorted by count descending
    assert_equal 'Unreviewed Book C', mentions[0][:title]
    assert_equal 5, mentions[0][:count]

    assert_equal 'Unreviewed Book A', mentions[1][:title]
    assert_equal 3, mentions[1][:count]

    assert_equal 'Unreviewed Book B', mentions[2][:title]
    assert_equal 1, mentions[2][:count]
  end

  def test_find_filters_out_existing_books
    setup_mention_tracker_with_existing_book

    finder = Jekyll::Books::Ranking::UnreviewedMentions::DisplayUnreviewedMentions::Finder.new(@context)
    result = finder.find

    mentions = result[:mentions]
    assert_equal 1, mentions.size
    assert_equal 'Unreviewed Book A', mentions[0][:title]
    refute(mentions.any? { |m| m[:title] == 'Existing Book' })
  end

  def test_find_returns_empty_array_when_tracker_is_empty
    @site.data['mention_tracker'] = {}

    finder = Jekyll::Books::Ranking::UnreviewedMentions::DisplayUnreviewedMentions::Finder.new(@context)
    result = finder.find

    assert_equal '', result[:logs]
    assert_equal [], result[:mentions]
  end

  def test_find_returns_empty_array_when_all_mentions_filtered
    @site.data['mention_tracker'] = {
      'existing book' => {
        original_titles: { 'Existing Book' => 2 },
        sources: Set.new(['/src1.html', '/src2.html'])
      }
    }

    finder = Jekyll::Books::Ranking::UnreviewedMentions::DisplayUnreviewedMentions::Finder.new(@context)
    result = finder.find

    assert_equal '', result[:logs]
    assert_equal [], result[:mentions]
  end

  def test_find_logs_error_if_mention_tracker_is_missing
    @site.data.delete('mention_tracker')
    @site.config['plugin_logging']['UNREVIEWED_MENTIONS'] = true

    finder = Jekyll::Books::Ranking::UnreviewedMentions::DisplayUnreviewedMentions::Finder.new(@context)

    capture_io do
      result = finder.find
      assert_match(/ERROR.*UNREVIEWED_MENTIONS/, result[:logs])
      assert_equal [], result[:mentions]
    end
  end

  def test_find_logs_error_if_link_cache_is_missing
    @site.data.delete('link_cache')
    @site.config['plugin_logging']['UNREVIEWED_MENTIONS'] = true

    finder = Jekyll::Books::Ranking::UnreviewedMentions::DisplayUnreviewedMentions::Finder.new(@context)

    capture_io do
      result = finder.find
      assert_match(/ERROR.*UNREVIEWED_MENTIONS/, result[:logs])
      assert_equal [], result[:mentions]
    end
  end

  private

  def setup_mention_tracker_data
    @site.data['mention_tracker'] = {
      'unreviewed book a' => {
        original_titles: { 'Unreviewed Book A' => 2, 'unreviewed book a' => 1 },
        sources: Set.new(['/src1.html', '/src2.html', '/src3.html']) # 3 mentions
      },
      'unreviewed book b' => {
        original_titles: { 'Unreviewed Book B' => 1 },
        sources: Set.new(['/src1.html']) # 1 mention
      },
      'unreviewed book c' => {
        original_titles: { 'Unreviewed Book C' => 5 },
        sources: Set.new(['/src1.html', '/src2.html', '/src3.html', '/src4.html', '/src5.html']) # 5 mentions
      }
    }
  end

  def setup_mention_tracker_with_existing_book
    @site.data['mention_tracker'] = {
      'unreviewed book a' => {
        original_titles: { 'Unreviewed Book A' => 2 },
        sources: Set.new(['/src1.html', '/src2.html']) # 2 mentions
      },
      'existing book' => { # This one should be filtered out
        original_titles: { 'Existing Book' => 5 },
        sources: Set.new(['/src1.html', '/src2.html', '/src3.html', '/src4.html', '/src5.html'])
      }
    }
  end
end

# Tests for Jekyll::Books::Ranking::UnreviewedMentions::DisplayUnreviewedMentions::Renderer class.
#
# Verifies the HTML generation logic.
class TestDisplayUnreviewedMentionsRenderer < Minitest::Test
  def test_render_generates_ordered_list_for_populated_array
    mentions = [
      { title: 'Book C', count: 5 },
      { title: 'Book A', count: 3 },
      { title: 'Book B', count: 1 }
    ]

    renderer = Jekyll::Books::Ranking::UnreviewedMentions::DisplayUnreviewedMentions::Renderer.new(mentions)
    output = renderer.render

    assert_match(/<ol class="ranked-list">/, output)
    assert_match(%r{<li><cite>Book C</cite> <span class="mention-count">\(5 mentions\)</span></li>}, output)
    assert_match(%r{<li><cite>Book A</cite> <span class="mention-count">\(3 mentions\)</span></li>}, output)
    assert_match(%r{<li><cite>Book B</cite> <span class="mention-count">\(1 mention\)</span></li>}, output)
  end

  def test_render_handles_singular_mention_correctly
    mentions = [{ title: 'Solo Book', count: 1 }]

    renderer = Jekyll::Books::Ranking::UnreviewedMentions::DisplayUnreviewedMentions::Renderer.new(mentions)
    output = renderer.render

    assert_match(/1 mention\)/, output)
    refute_match(/1 mentions\)/, output)
  end

  def test_render_handles_plural_mentions_correctly
    mentions = [{ title: 'Popular Book', count: 42 }]

    renderer = Jekyll::Books::Ranking::UnreviewedMentions::DisplayUnreviewedMentions::Renderer.new(mentions)
    output = renderer.render

    assert_match(/42 mentions\)/, output)
  end

  def test_render_escapes_html_in_titles
    mentions = [{ title: '<script>alert("xss")</script>', count: 1 }]

    renderer = Jekyll::Books::Ranking::UnreviewedMentions::DisplayUnreviewedMentions::Renderer.new(mentions)
    output = renderer.render

    refute_match(/<script>/, output)
    assert_match(/&lt;script&gt;/, output)
  end

  def test_render_returns_no_mentions_message_for_empty_array
    renderer = Jekyll::Books::Ranking::UnreviewedMentions::DisplayUnreviewedMentions::Renderer.new([])
    output = renderer.render

    assert_equal '<p>No unreviewed works have been mentioned yet.</p>', output
  end
end

# Integration test for Jekyll::Books::Tags::DisplayUnreviewedMentionsTag Liquid tag.
#
# Verifies that the tag correctly orchestrates Finder and Renderer.
class TestDisplayUnreviewedMentionsTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current.md' }, '/current.html') })

    # Pre-populate the caches for tests
    @site.data['link_cache']['books'] = {
      'existing book' => [{ 'url' => '/books/existing.html', 'title' => 'Existing Book', 'authors' => [] }]
    }
  end

  # Helper to render the tag
  def render_tag(context = @context)
    Liquid::Template.parse('{% display_unreviewed_mentions %}').render!(context)
  end

  def test_tag_orchestrates_finder_and_renderer_correctly
    @site.data['mention_tracker'] = {
      'unreviewed book a' => {
        original_titles: { 'Unreviewed Book A' => 2 },
        sources: Set.new(['/src1.html', '/src2.html'])
      }
    }

    output = render_tag

    # Should have both found the data and rendered it
    assert_match(/<ol class="ranked-list">/, output)
    assert_match(%r{<li><cite>Unreviewed Book A</cite> <span class="mention-count">\(2 mentions\)</span></li>}, output)
  end

  def test_tag_returns_empty_message_when_no_mentions
    @site.data['mention_tracker'] = {}
    output = render_tag
    assert_equal '<p>No unreviewed works have been mentioned yet.</p>', output
  end

  def test_tag_includes_error_logs_when_prerequisites_missing
    @site.data.delete('mention_tracker')
    @site.config['plugin_logging']['UNREVIEWED_MENTIONS'] = true

    output = ''
    capture_io do
      output = render_tag
    end

    expected_error = /<!-- \[ERROR\] UNREVIEWED_MENTIONS_FAILURE: Reason='Prerequisites missing: /
    assert_match(expected_error, output)
  end
end
