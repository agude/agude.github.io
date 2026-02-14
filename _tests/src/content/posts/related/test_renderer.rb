# frozen_string_literal: true

require_relative '../../../../test_helper'

# Tests for Jekyll::Posts::Related::Renderer
#
# Verifies that related posts are correctly rendered to HTML.
class TestRelatedPostsRenderer < Minitest::Test
  def setup
    @post = create_doc(
      { 'title' => 'Test Post', 'published' => true },
      '/posts/test.html',
    )
    @site = create_site({}, {})
    @context = create_context({}, { site: @site, page: @post })
  end

  def test_returns_empty_when_no_posts
    renderer = Jekyll::Posts::Related::Renderer.new(@context, [], false)

    assert_equal '', renderer.render
  end

  def test_renders_aside_container
    renderer = Jekyll::Posts::Related::Renderer.new(@context, [@post], false)
    result = renderer.render

    assert_includes result, '<aside class="related">'
    assert_includes result, '</aside>'
  end

  def test_renders_related_posts_heading_when_found_by_category
    renderer = Jekyll::Posts::Related::Renderer.new(@context, [@post], true)
    result = renderer.render

    assert_includes result, '<h2>Related Posts</h2>'
  end

  def test_renders_recent_posts_heading_when_not_found_by_category
    renderer = Jekyll::Posts::Related::Renderer.new(@context, [@post], false)
    result = renderer.render

    assert_includes result, '<h2>Recent Posts</h2>'
  end

  def test_renders_card_grid
    renderer = Jekyll::Posts::Related::Renderer.new(@context, [@post], false)
    result = renderer.render

    assert_includes result, '<div class="card-grid">'
  end

  def test_renders_multiple_posts
    post_a = create_doc(
      { 'title' => 'Post A', 'published' => true },
      '/posts/a.html',
    )
    post_b = create_doc(
      { 'title' => 'Post B', 'published' => true },
      '/posts/b.html',
    )

    renderer = Jekyll::Posts::Related::Renderer.new(@context, [post_a, post_b], true)
    result = renderer.render

    # Should have one aside with one grid containing multiple cards
    assert_equal 1, result.scan('card-grid').length
    assert_equal 1, result.scan('<aside').length
  end

  def test_structure_with_related_posts
    renderer = Jekyll::Posts::Related::Renderer.new(@context, [@post], true)
    result = renderer.render

    # Verify nested structure
    assert_includes result, '<aside class="related">'
    assert_includes result, '<h2>Related Posts</h2>'
    assert_includes result, '<div class="card-grid">'
    assert_includes result, '</div>'
    assert_includes result, '</aside>'
  end

  def test_structure_with_recent_posts
    renderer = Jekyll::Posts::Related::Renderer.new(@context, [@post], false)
    result = renderer.render

    # Verify nested structure
    assert_includes result, '<aside class="related">'
    assert_includes result, '<h2>Recent Posts</h2>'
  end
end
