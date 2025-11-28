# frozen_string_literal: true

# _tests/plugins/test_display_previous_reviews_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_previous_reviews_tag'

# Tests for DisplayPreviousReviewsTag Liquid tag.
#
# Verifies that the tag correctly orchestrates between Finder and Renderer.
class TestDisplayPreviousReviewsTag < Minitest::Test
  def setup
    @context = create_context({}, {})
  end

  def render_tag
    Liquid::Template.parse('{% display_previous_reviews %}').render!(@context)
  end

  def test_syntax_error_with_arguments
    assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_previous_reviews some_arg %}')
    end
  end

  def test_calls_finder_and_returns_logs_when_no_reviews
    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, { logs: '<!-- Log message -->', reviews: [] }

    Jekyll::PreviousReviews::Finder.stub :new, ->(_context) { mock_finder } do
      output = render_tag

      assert_equal '<!-- Log message -->', output
      mock_finder.verify
    end
  end

  def test_calls_finder_and_renderer_when_reviews_found
    mock_doc = create_doc({ 'title' => 'Test' }, '/books/test.html')

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, { logs: '', reviews: [mock_doc] }

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<aside>HTML output</aside>'

    Jekyll::PreviousReviews::Finder.stub :new, ->(_context) { mock_finder } do
      Jekyll::PreviousReviews::Renderer.stub :new, lambda { |_context, reviews|
        assert_equal [mock_doc], reviews
        mock_renderer
      } do
        output = render_tag

        assert_equal '<aside>HTML output</aside>', output
        mock_finder.verify
        mock_renderer.verify
      end
    end
  end

  def test_concatenates_logs_and_html_when_both_present
    mock_doc = create_doc({ 'title' => 'Test' }, '/books/test.html')

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, { logs: '<!-- Debug log -->', reviews: [mock_doc] }

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<aside>HTML</aside>'

    Jekyll::PreviousReviews::Finder.stub :new, ->(_context) { mock_finder } do
      Jekyll::PreviousReviews::Renderer.stub :new, ->(_context, _reviews) { mock_renderer } do
        output = render_tag

        assert_equal '<!-- Debug log --><aside>HTML</aside>', output
        mock_finder.verify
        mock_renderer.verify
      end
    end
  end

  def test_passes_context_to_finder_and_renderer
    mock_doc = create_doc({ 'title' => 'Test' }, '/books/test.html')
    context_passed_to_finder = nil
    context_passed_to_renderer = nil

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, { logs: '', reviews: [mock_doc] }

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<aside>HTML</aside>'

    Jekyll::PreviousReviews::Finder.stub :new, lambda { |context|
      context_passed_to_finder = context
      mock_finder
    } do
      Jekyll::PreviousReviews::Renderer.stub :new, lambda { |context, _reviews|
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
