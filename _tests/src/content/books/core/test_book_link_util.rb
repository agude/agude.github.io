# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/core/book_link_util'

# Tests for Jekyll::Books::Core::BookLinkUtils delegation.
#
# Verifies that the utility module correctly delegates to BookLinkResolver.
class TestBookLinkUtils < Minitest::Test
  def setup
    @context = create_context
  end

  def test_render_book_link_delegates_to_resolver
    title = 'Dune'
    override = 'The Dune Book'
    author = 'Frank Herbert'
    date_filter = nil
    mock_output = '<a>Dune</a>'

    # Create a mock resolver instance
    mock_resolver = Minitest::Mock.new
    mock_resolver.expect :resolve, mock_output, [title, override, author, date_filter]

    # Stub .new to return the mock
    Jekyll::Books::Core::BookLinkResolver.stub :new, mock_resolver do
      result = Jekyll::Books::Core::BookLinkUtils.render_book_link(title, @context, override, author)
      assert_equal mock_output, result
    end

    mock_resolver.verify
  end

  def test_track_unreviewed_mention_delegates_to_resolver
    title = 'Unreviewed Book'
    mock_resolver = Minitest::Mock.new
    mock_resolver.expect :track_unreviewed_mention_explicit, nil, [title]

    Jekyll::Books::Core::BookLinkResolver.stub :new, mock_resolver do
      Jekyll::Books::Core::BookLinkUtils._track_unreviewed_mention(@context, title)
    end

    mock_resolver.verify
  end
end
