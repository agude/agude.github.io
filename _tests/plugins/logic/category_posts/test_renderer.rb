# frozen_string_literal: true

# _tests/plugins/logic/category_posts/test_renderer.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/posts/category/renderer'

# Tests for Jekyll::CategoryPosts::Renderer.
#
# Verifies that the Renderer correctly generates HTML structure.
class TestCategoryPostsRenderer < Minitest::Test
  def setup
    @context = create_context({}, {})
    @post1 = create_doc({ 'title' => 'Post Alpha' }, '/posts/alpha.html')
    @post2 = create_doc({ 'title' => 'Post Beta' }, '/posts/beta.html')
  end

  def test_returns_empty_string_when_posts_empty
    renderer = Jekyll::CategoryPosts::Renderer.new(@context, [])
    output = renderer.render

    assert_equal '', output
  end

  def test_generates_correct_html_structure
    ArticleCardUtils.stub :render, ->(_post, _ctx) { '<div>Card</div>' } do
      renderer = Jekyll::CategoryPosts::Renderer.new(@context, [@post1])
      output = renderer.render

      assert_match(/<div class="card-grid">/, output)
      assert_match(%r{</div>}, output)
    end
  end

  def test_calls_article_card_utils_with_correct_parameters
    captured_args = []
    ArticleCardUtils.stub :render, lambda { |post, ctx|
      captured_args << { post: post, ctx: ctx }
      '<div>Card</div>'
    } do
      renderer = Jekyll::CategoryPosts::Renderer.new(@context, [@post1])
      renderer.render

      assert_equal 1, captured_args.length
      assert_equal @post1, captured_args[0][:post]
      assert_equal @context, captured_args[0][:ctx]
    end
  end

  def test_renders_multiple_posts_in_given_order
    ArticleCardUtils.stub :render, lambda { |post, _ctx|
      "<div>Card for #{post.data['title']}</div>"
    } do
      renderer = Jekyll::CategoryPosts::Renderer.new(@context, [@post1, @post2])
      output = renderer.render

      # Verify both posts are present
      assert_match(/Card for Post Alpha/, output)
      assert_match(/Card for Post Beta/, output)

      # Verify order
      idx_alpha = output.index('Post Alpha')
      idx_beta = output.index('Post Beta')
      assert idx_alpha < idx_beta, 'Post Alpha should appear before Post Beta'
    end
  end

  def test_includes_all_rendered_cards_in_output
    ArticleCardUtils.stub :render, lambda { |post, _ctx|
      "<article class=\"card\">#{post.data['title']}</article>"
    } do
      renderer = Jekyll::CategoryPosts::Renderer.new(@context, [@post1, @post2])
      output = renderer.render

      assert_includes output, '<article class="card">Post Alpha</article>'
      assert_includes output, '<article class="card">Post Beta</article>'
    end
  end

  def test_wraps_all_cards_in_single_card_grid
    ArticleCardUtils.stub :render, ->(_post, _ctx) { '<div>Card</div>' } do
      renderer = Jekyll::CategoryPosts::Renderer.new(@context, [@post1, @post2])
      output = renderer.render

      # Count occurrences of card-grid opening and closing
      opening_count = output.scan('<div class="card-grid">').length
      closing_count = output.scan(%r{</div>}).length

      assert_equal 1, opening_count, 'Should have exactly one card-grid opening tag'
      assert opening_count <= closing_count, 'Should have at least one closing div tag'
    end
  end
end
