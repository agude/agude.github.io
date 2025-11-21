# frozen_string_literal: true

# _tests/plugins/test_display_unreviewed_mentions_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_unreviewed_mentions_tag'

class TestDisplayUnreviewedMentionsTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current.md' }, '/current.html') })

    # --- Pre-populate the caches for tests ---
    # Book that exists, to test filtering
    @site.data['link_cache']['books'] = {
      'existing book' => [{ 'url' => '/books/existing.html', 'title' => 'Existing Book', 'authors' => [] }]
    }
  end

  # Helper to render the tag
  def render_tag(context = @context)
    Liquid::Template.parse('{% display_unreviewed_mentions %}').render!(context)
  end

  def test_renders_ranked_list_correctly_sorted
    setup_mention_tracker_data

    output = render_tag

    assert_match(/<ol class="ranked-list">/, output)
    assert_list_items_present(output)
    assert_correct_book_order(output)
  end

  def test_filters_out_mentions_that_have_reviews
    setup_mention_tracker_with_existing_book

    output = render_tag

    expected_unreviewed = %r{<li><cite>Unreviewed Book A</cite> <span class="mention-count">\(2 mentions\)</span></li>}
    assert_match expected_unreviewed, output
    refute_match(/Existing Book/, output)
  end

  def test_renders_message_when_tracker_is_empty
    @site.data['mention_tracker'] = {}
    output = render_tag
    assert_equal '<p>No unreviewed works have been mentioned yet.</p>', output
  end

  def test_renders_message_when_all_mentions_are_filtered_out
    @site.data['mention_tracker'] = {
      'existing book' => {
        original_titles: { 'Existing Book' => 2 },
        sources: Set.new(['/src1.html', '/src2.html'])
      }
    }
    output = render_tag
    assert_equal '<p>No unreviewed works have been mentioned yet.</p>', output
  end

  def test_logs_error_if_mention_tracker_is_missing
    @site.data.delete('mention_tracker')
    @site.config['plugin_logging']['UNREVIEWED_MENTIONS'] = true

    output = ''
    capture_io do
      output = render_tag
    end

    # FIXED: Account for HTML escaping of single quotes
    expected_error = /<!-- \[ERROR\] UNREVIEWED_MENTIONS_FAILURE: Reason='Prerequisites missing: /
    assert_match(expected_error, output)
  end

  def test_logs_error_if_link_cache_is_missing
    @site.data.delete('link_cache')
    @site.config['plugin_logging']['UNREVIEWED_MENTIONS'] = true

    output = ''
    capture_io do
      output = render_tag
    end

    # FIXED: Account for HTML escaping of single quotes
    expected_error = /<!-- \[ERROR\] UNREVIEWED_MENTIONS_FAILURE: Reason='Prerequisites missing: /
    assert_match(expected_error, output)
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

  def assert_list_items_present(output)
    book_c_pattern = %r{<li><cite>Unreviewed Book C</cite> <span class="mention-count">\(5 mentions\)</span></li>}
    book_a_pattern = %r{<li><cite>Unreviewed Book A</cite> <span class="mention-count">\(3 mentions\)</span></li>}
    book_b_pattern = %r{<li><cite>Unreviewed Book B</cite> <span class="mention-count">\(1 mention\)</span></li>}

    assert_match book_c_pattern, output
    assert_match book_a_pattern, output
    assert_match book_b_pattern, output
  end

  def assert_correct_book_order(output)
    idx_c = output.index('Unreviewed Book C')
    idx_a = output.index('Unreviewed Book A')
    idx_b = output.index('Unreviewed Book B')

    assert idx_c < idx_a, 'Book C (5 mentions) should appear before Book A (3 mentions)'
    assert idx_a < idx_b, 'Book A (3 mentions) should appear before Book B (1 mention)'
  end
end
