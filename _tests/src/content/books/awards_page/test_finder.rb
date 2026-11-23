# frozen_string_literal: true

require_relative '../../../../test_helper'

# Exercises the combined data consumed by both awards page renderers.
class TestAwardsPageFinder < Minitest::Test
  def test_combines_award_groups_and_favorite_lists
    book = create_doc({ 'title' => 'Example Book', 'awards' => ['Hugo'], 'date' => Time.utc(2024) }, '/books/example.html')
    post = create_doc(
      { 'title' => 'Favorites', 'is_favorites_list' => 2024 },
      '/favorites.html',
      '{% book_card_lookup title="Example Book" date="2024-01-01" %}',
    )
    site = create_site({}, { 'books' => [book] }, [], [post])
    context = create_context({}, { site: site })

    assert_equal(
      {
        awards_groups: [{ award_name: 'Hugo Award', award_slug: 'hugo-award', books: [book] }],
        favorites_lists: [{ post: post, books: [book] }],
        log_messages: '',
      },
      Jekyll::Books::AwardsPage::Finder.new(site: site, context: context).find,
    )
  end
end
