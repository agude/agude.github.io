# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/authors/author_link_util'

# Tests for Jekyll::Authors::AuthorLinkUtils delegation.
#
# Verifies that the utility module correctly delegates to AuthorLinkResolver.
class TestAuthorLinkUtils < Minitest::Test
  def setup
    @context = create_context
  end

  def test_render_author_link_delegates_to_resolver
    name = 'Isaac Asimov'
    override = 'The Good Doctor'
    possessive = true
    mock_output = "<a>Isaac Asimov</a>'s"

    # Create a mock resolver instance
    mock_resolver = Minitest::Mock.new
    mock_resolver.expect :resolve, mock_output, [name, override, possessive]

    # Stub .new to return the mock
    Jekyll::Authors::AuthorLinkResolver.stub :new, mock_resolver do
      result = Jekyll::Authors::AuthorLinkUtils.render_author_link(name, @context, override, possessive)
      assert_equal mock_output, result
    end

    mock_resolver.verify
  end
end
