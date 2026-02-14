# frozen_string_literal: true

# _tests/plugins/test_display_previous_reviews_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/tags/display_previous_reviews_tag'

# Tests for Jekyll::Books::Tags::DisplayPreviousReviewsTag Liquid tag.
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

    Jekyll::Books::Reviews::Finder.stub :new, ->(_site, _page) { mock_finder } do
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

    Jekyll::Books::Reviews::Finder.stub :new, ->(_site, _page) { mock_finder } do
      Jekyll::Books::Reviews::Renderer.stub :new, lambda { |_context, reviews|
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

    Jekyll::Books::Reviews::Finder.stub :new, ->(_site, _page) { mock_finder } do
      Jekyll::Books::Reviews::Renderer.stub :new, ->(_context, _reviews) { mock_renderer } do
        output = render_tag

        assert_equal '<!-- Debug log --><aside>HTML</aside>', output
        mock_finder.verify
        mock_renderer.verify
      end
    end
  end

  def test_passes_site_and_page_to_finder
    mock_doc = create_doc({ 'title' => 'Test' }, '/books/test.html')
    test_site = create_site({}, { 'books' => [mock_doc] })
    test_page = create_doc({ 'title' => 'Current' }, '/books/current.html')
    @context = create_context({}, { site: test_site, page: test_page })

    site_passed_to_finder = nil
    page_passed_to_finder = nil

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, { logs: '', reviews: [mock_doc] }

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<aside>HTML</aside>'

    Jekyll::Books::Reviews::Finder.stub :new, lambda { |site, page|
      site_passed_to_finder = site
      page_passed_to_finder = page
      mock_finder
    } do
      Jekyll::Books::Reviews::Renderer.stub :new, lambda { |_context, _reviews|
        mock_renderer
      } do
        render_tag

        assert_equal test_site, site_passed_to_finder
        assert_equal test_page, page_passed_to_finder
      end
    end
  end
end
