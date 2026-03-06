# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/core/book_awards_formatter'

# Tests for BookAwardsFormatter.
class TestBookAwardsFormatter < Minitest::Test
  def setup
    @mention_2024 = create_doc({ 'title' => 'Favorites 2024', 'is_favorites_list' => 2024 }, '/fav-2024.html')
    @mention_2023 = create_doc({ 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 }, '/fav-2023.html')
  end

  def test_empty_returns_nil
    result = render(nil, nil)
    assert_nil result
  end

  def test_empty_arrays_returns_nil
    result = render([], [])
    assert_nil result
  end

  def test_awards_only
    result = render(%w[nebula hugo], nil)
    assert_equal 'Awards: [Hugo](/books/by-award/#hugo-award), [Nebula](/books/by-award/#nebula-award)', result
  end

  def test_mentions_only
    result = render(nil, [@mention_2023, @mention_2024])
    assert_equal 'Awards: [2024 Favorites](/fav-2024.html), [2023 Favorites](/fav-2023.html)', result
  end

  def test_awards_and_mentions
    result = render(%w[hugo], [@mention_2024])
    assert_equal 'Awards: [Hugo](/books/by-award/#hugo-award), [2024 Favorites](/fav-2024.html)', result
  end

  def test_multi_word_capitalization
    result = render(['locus fantasy'], nil)
    assert_equal 'Awards: [Locus Fantasy](/books/by-award/#locus-fantasy-award)', result
  end

  private

  def render(awards, mentions)
    Jekyll::Books::Core::BookAwardsFormatter.new(awards, mentions).render
  end
end
