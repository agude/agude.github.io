# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/posts/article_card_utils'

# Tests delegation from ArticleCardUtils module to ArticleCardRenderer class.
class TestArticleCardUtils < Minitest::Test
  def setup
    @context = create_context
    @post = create_doc
  end

  def test_render_delegates_to_renderer
    mock_output = '<div>Article Card</div>'

    # Create a mock renderer instance
    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, mock_output

    # Stub .new to return the mock
    Jekyll::Posts::ArticleCardRenderer.stub :new, mock_renderer do
      result = Jekyll::Posts::ArticleCardUtils.render(@post, @context)
      assert_equal mock_output, result
    end

    mock_renderer.verify
  end
end
