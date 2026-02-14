# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/series/series_link_util'

# Tests for Jekyll::Series::SeriesLinkUtils module.
#
# Verifies that the public API correctly delegates to SeriesLinkResolver.
class TestSeriesLinkUtils < Minitest::Test
  def setup
    @context = create_context
  end

  def test_find_series_link_data_delegates_to_resolver
    title = 'Foundation'
    override = 'The Foundation Series'
    mock_data = { status: :found, url: '/series/foundation/', display_text: 'The Foundation Series' }

    mock_resolver = Minitest::Mock.new
    mock_resolver.expect :resolve_data, mock_data, [title, override]

    Jekyll::Series::SeriesLinkResolver.stub :new, mock_resolver do
      result = Jekyll::Series::SeriesLinkUtils.find_series_link_data(title, @context, override)
      assert_equal mock_data, result
      assert_equal :found, result[:status]
    end

    mock_resolver.verify
  end

  def test_render_series_link_delegates_to_resolver
    title = 'Foundation'
    override = 'The Foundation Series'
    mock_output = '<a>Foundation</a>'

    # Create a mock resolver instance
    mock_resolver = Minitest::Mock.new
    mock_resolver.expect :resolve, mock_output, [title, override]

    # Stub .new to return the mock
    Jekyll::Series::SeriesLinkResolver.stub :new, mock_resolver do
      result = Jekyll::Series::SeriesLinkUtils.render_series_link(title, @context, override)
      assert_equal mock_output, result
    end

    mock_resolver.verify
  end
end
