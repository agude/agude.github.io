# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/core/book_card_utils'

# Tests delegation from BookCardUtils module to BookCardRenderer class.
class TestBookCardUtils < Minitest::Test
  def setup
    @context = create_context
    @book = create_doc
  end

  def test_render_delegates_to_renderer
    title_override = 'Custom Title'
    subtitle = 'A Subtitle'
    mock_output = '<div>Card</div>'

    # Create a mock renderer instance
    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, mock_output

    # Stub .new to return the mock
    Jekyll::Books::Core::BookCardRenderer.stub :new, mock_renderer do
      result = Jekyll::Books::Core::BookCardUtils.render(@book, @context, display_title_override: title_override, subtitle: subtitle)
      assert_equal mock_output, result
    end

    # Verify arguments passed to .new
    # Note: Minitest::Mock doesn't easily verify constructor args on the class stub,
    # but the fact that the mock was returned and called proves delegation happened.
    mock_renderer.verify
  end
end
