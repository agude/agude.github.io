# frozen_string_literal: true

# _tests/plugins/logic/ranked_by_backlinks/test_renderer.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/books/ranking/renderer'

# Tests for Jekyll::RankedByBacklinks::Renderer.
#
# Verifies that the Renderer correctly generates HTML structure and content.
class TestRankedByBacklinksRenderer < Minitest::Test
  def setup
    @context = create_context({}, {})
  end

  def test_returns_no_books_message_when_list_empty
    renderer = Jekyll::RankedByBacklinks::Renderer.new(@context, [])
    output = renderer.render

    assert_equal '<p>No books have been mentioned yet.</p>', output
  end

  def test_generates_correct_html_structure
    ranked_list = [
      { title: 'Book A', url: '/a.html', count: 2 }
    ]

    BookLinkUtils.stub :render_book_link_from_data, ->(_title, _url, _ctx) { '<a>Link</a>' } do
      renderer = Jekyll::RankedByBacklinks::Renderer.new(@context, ranked_list)
      output = renderer.render

      assert_match(/<ol class="ranked-list">/, output)
      assert_match(%r{</ol>}, output)
    end
  end

  def test_calls_book_link_utils_with_correct_parameters
    ranked_list = [
      { title: 'Book A', url: '/a.html', count: 2 }
    ]

    captured_args = []
    BookLinkUtils.stub :render_book_link_from_data, lambda { |title, url, ctx|
      captured_args << { title: title, url: url, ctx: ctx }
      '<a>Link</a>'
    } do
      renderer = Jekyll::RankedByBacklinks::Renderer.new(@context, ranked_list)
      renderer.render

      assert_equal 1, captured_args.length
      assert_equal 'Book A', captured_args[0][:title]
      assert_equal '/a.html', captured_args[0][:url]
      assert_equal @context, captured_args[0][:ctx]
    end
  end

  def test_renders_singular_mention_text_correctly
    ranked_list = [
      { title: 'Book A', url: '/a.html', count: 1 }
    ]

    BookLinkUtils.stub :render_book_link_from_data, ->(_title, _url, _ctx) { '<a>Book A</a>' } do
      renderer = Jekyll::RankedByBacklinks::Renderer.new(@context, ranked_list)
      output = renderer.render

      assert_match(/\(1 mention\)/, output)
      refute_match(/\(1 mentions\)/, output)
    end
  end

  def test_renders_plural_mention_text_correctly
    ranked_list = [
      { title: 'Book A', url: '/a.html', count: 5 }
    ]

    BookLinkUtils.stub :render_book_link_from_data, ->(_title, _url, _ctx) { '<a>Book A</a>' } do
      renderer = Jekyll::RankedByBacklinks::Renderer.new(@context, ranked_list)
      output = renderer.render

      assert_match(/\(5 mentions\)/, output)
      refute_match(/\(5 mention\)/, output)
    end
  end

  def test_renders_multiple_items_in_given_order
    ranked_list = [
      { title: 'Book B', url: '/b.html', count: 3 },
      { title: 'Book A', url: '/a.html', count: 2 },
      { title: 'Book C', url: '/c.html', count: 1 }
    ]

    BookLinkUtils.stub :render_book_link_from_data, lambda { |title, _url, _ctx|
      "<a>#{title}</a>"
    } do
      renderer = Jekyll::RankedByBacklinks::Renderer.new(@context, ranked_list)
      output = renderer.render

      # Verify all items are present
      assert_match(%r{<a>Book B</a>.*\(3 mentions\)}, output)
      assert_match(%r{<a>Book A</a>.*\(2 mentions\)}, output)
      assert_match(%r{<a>Book C</a>.*\(1 mention\)}, output)

      # Verify order
      idx_b = output.index('Book B')
      idx_a = output.index('Book A')
      idx_c = output.index('Book C')

      assert idx_b < idx_a, 'Book B should appear before Book A'
      assert idx_a < idx_c, 'Book A should appear before Book C'
    end
  end

  def test_renders_list_items_with_correct_structure
    ranked_list = [
      { title: 'Book A', url: '/a.html', count: 2 }
    ]

    BookLinkUtils.stub :render_book_link_from_data, lambda { |title, url, _ctx|
      "<a href=\"#{url}\">#{title}</a>"
    } do
      renderer = Jekyll::RankedByBacklinks::Renderer.new(@context, ranked_list)
      output = renderer.render

      expected = %r{<li><a href="/a.html">Book A</a> <span class="mention-count">\(2 mentions\)</span></li>}
      assert_match expected, output
    end
  end
end
