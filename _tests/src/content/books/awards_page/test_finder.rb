# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/awards_page/finder'

# Tests shared awards-page data retrieval.
class TestAwardsPageFinder < Minitest::Test
  def test_fetches_each_source_once_and_combines_logs
    context = create_context({}, { site: create_site })
    awards = Minitest::Mock.new
    awards.expect :find, { awards_data: [:award], log_messages: 'award log' }
    favorites = Minitest::Mock.new
    favorites.expect :find, { favorites_lists: [:favorite], log_messages: 'favorite log' }

    result = Jekyll::Books::Lists::ByAwardFinder.stub(:new, ->(**) { awards }) do
      Jekyll::Books::Lists::FavoritesListsFinder.stub(:new, ->(**) { favorites }) do
        Jekyll::Books::AwardsPage::Finder.new(context).find
      end
    end

    assert_equal [:award], result[:awards_groups]
    assert_equal [:favorite], result[:favorites_lists]
    assert_equal 'award logfavorite log', result[:log_messages]
    awards.verify
    favorites.verify
  end
end
