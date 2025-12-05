# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/short_stories/short_story_link_util'

# Tests for Jekyll::ShortStories::ShortStoryLinkUtils module.
#
# Verifies that the public API correctly delegates to ShortStoryResolver.
class TestShortStoryLinkUtils < Minitest::Test
  def setup
    @context = create_context
  end

  def test_render_short_story_link_delegates_to_resolver
    title = 'The Last Question'
    from_book = 'Robot Dreams'
    mock_output = '<a>The Last Question</a>'

    # Create a mock resolver instance
    mock_resolver = Minitest::Mock.new
    mock_resolver.expect :resolve, mock_output, [title, from_book]

    # Stub .new to return the mock
    Jekyll::ShortStories::ShortStoryResolver.stub :new, mock_resolver do
      result = Jekyll::ShortStories::ShortStoryLinkUtils.render_short_story_link(title, @context, from_book)
      assert_equal mock_output, result
    end

    mock_resolver.verify
  end
end
