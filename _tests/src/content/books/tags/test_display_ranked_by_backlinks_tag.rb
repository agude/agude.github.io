# frozen_string_literal: true

# _tests/plugins/test_display_ranked_by_backlinks_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/tags/display_ranked_by_backlinks_tag'

# Tests for Jekyll::Books::Tags::DisplayRankedByBacklinksTag Liquid tag.
#
# Verifies that the tag correctly orchestrates between Finder and Renderer.
class TestDisplayRankedByBacklinksTag < Minitest::Test
  def setup
    @context = create_context({}, {})
  end

  def render_tag
    Liquid::Template.parse('{% display_ranked_by_backlinks %}').render!(@context)
  end

  def test_calls_finder_and_returns_logs_when_no_ranked_list
    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, { logs: '<!-- Log message -->', ranked_list: [] }

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<p>No books have been mentioned yet.</p>'

    Jekyll::Books::Ranking::RankedByBacklinks::Finder.stub :new, ->(_context) { mock_finder } do
      Jekyll::Books::Ranking::RankedByBacklinks::Renderer.stub :new, lambda { |_context, ranked_list|
        assert_equal [], ranked_list
        mock_renderer
      } do
        output = render_tag

        assert_equal '<!-- Log message --><p>No books have been mentioned yet.</p>', output
        mock_finder.verify
        mock_renderer.verify
      end
    end
  end

  def test_calls_finder_and_renderer_when_ranked_list_found
    mock_ranked_list = [
      { title: 'Book A', url: '/a.html', count: 2 }
    ]

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, { logs: '', ranked_list: mock_ranked_list }

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<ol>HTML output</ol>'

    Jekyll::Books::Ranking::RankedByBacklinks::Finder.stub :new, ->(_context) { mock_finder } do
      Jekyll::Books::Ranking::RankedByBacklinks::Renderer.stub :new, lambda { |_context, ranked_list|
        assert_equal mock_ranked_list, ranked_list
        mock_renderer
      } do
        output = render_tag

        assert_equal '<ol>HTML output</ol>', output
        mock_finder.verify
        mock_renderer.verify
      end
    end
  end

  def test_concatenates_logs_and_html_when_both_present
    mock_ranked_list = [
      { title: 'Book A', url: '/a.html', count: 2 }
    ]

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, { logs: '<!-- Debug log -->', ranked_list: mock_ranked_list }

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<ol>HTML</ol>'

    Jekyll::Books::Ranking::RankedByBacklinks::Finder.stub :new, ->(_context) { mock_finder } do
      Jekyll::Books::Ranking::RankedByBacklinks::Renderer.stub :new, ->(_context, _ranked_list) { mock_renderer } do
        output = render_tag

        assert_equal '<!-- Debug log --><ol>HTML</ol>', output
        mock_finder.verify
        mock_renderer.verify
      end
    end
  end

  def test_passes_context_to_finder_and_renderer
    mock_ranked_list = [{ title: 'Book A', url: '/a.html', count: 2 }]
    context_passed_to_finder = nil
    context_passed_to_renderer = nil

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, { logs: '', ranked_list: mock_ranked_list }

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<ol>HTML</ol>'

    Jekyll::Books::Ranking::RankedByBacklinks::Finder.stub :new, lambda { |context|
      context_passed_to_finder = context
      mock_finder
    } do
      Jekyll::Books::Ranking::RankedByBacklinks::Renderer.stub :new, lambda { |context, _ranked_list|
        context_passed_to_renderer = context
        mock_renderer
      } do
        render_tag

        assert_equal @context, context_passed_to_finder
        assert_equal @context, context_passed_to_renderer
      end
    end
  end
end
