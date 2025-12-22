# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::Infrastructure::LinkCache::FavoritesValidator
#
# Verifies that the validator correctly identifies book_card_lookup tags
# missing the required date parameter in favorites list posts.
class TestFavoritesValidator < Minitest::Test
  def setup
    @validator = Jekyll::Infrastructure::LinkCache::FavoritesValidator.new
  end

  # --- Unit tests for check_tag ---

  def test_tag_with_date_parameter_passes_validation
    post = create_favorites_post('2023', 'content does not matter for unit test')
    tag_content = 'title="Blindsight" date="2023-12-15"'

    @validator.check_tag(post, tag_content)

    # Should not raise - no errors accumulated
    @validator.raise_if_errors!
  end

  def test_tag_with_date_parameter_single_quotes_passes_validation
    post = create_favorites_post('2023', 'content')
    tag_content = "title='Blindsight' date='2023-12-15'"

    @validator.check_tag(post, tag_content)

    @validator.raise_if_errors!
  end

  def test_tag_with_date_parameter_no_spaces_passes_validation
    post = create_favorites_post('2023', 'content')
    tag_content = 'title="Blindsight" date="2023-12-15"'

    @validator.check_tag(post, tag_content)

    @validator.raise_if_errors!
  end

  def test_tag_with_date_parameter_extra_spaces_passes_validation
    post = create_favorites_post('2023', 'content')
    tag_content = 'title="Blindsight"   date = "2023-12-15"'

    @validator.check_tag(post, tag_content)

    @validator.raise_if_errors!
  end

  def test_tag_missing_date_parameter_fails_validation
    post = create_favorites_post('2023', 'content')
    tag_content = 'title="Blindsight"'

    @validator.check_tag(post, tag_content)

    error = assert_raises(RuntimeError) { @validator.raise_if_errors! }
    assert_includes error.message, 'Missing date parameter'
  end

  def test_multiple_tags_missing_date_in_same_post_all_captured
    post = create_favorites_post('2023', 'content')

    @validator.check_tag(post, 'title="Blindsight"')
    @validator.check_tag(post, 'title="Echopraxia"')

    error = assert_raises(RuntimeError) { @validator.raise_if_errors! }
    assert_includes error.message, 'Blindsight'
    assert_includes error.message, 'Echopraxia'
  end

  def test_multiple_posts_with_violations_all_captured
    post_2023 = create_favorites_post('2023', 'content', '/posts/fav-2023.html')
    post_2024 = create_favorites_post('2024', 'content', '/posts/fav-2024.html')

    @validator.check_tag(post_2023, 'title="Blindsight"')
    @validator.check_tag(post_2024, 'title="Echopraxia"')

    error = assert_raises(RuntimeError) { @validator.raise_if_errors! }
    assert_includes error.message, 'fav-2023.html'
    assert_includes error.message, 'fav-2024.html'
  end

  def test_mixed_valid_and_invalid_tags_only_invalid_reported
    post = create_favorites_post('2023', 'content')

    @validator.check_tag(post, 'title="Valid Book" date="2023-01-01"')
    @validator.check_tag(post, 'title="Invalid Book"')

    error = assert_raises(RuntimeError) { @validator.raise_if_errors! }
    assert_includes error.message, 'Invalid Book'
    refute_includes error.message, 'Valid Book'
  end

  def test_no_errors_does_not_raise
    # No check_tag calls - no errors
    @validator.raise_if_errors!
    # If we get here without raising, test passes
  end

  def test_error_message_includes_helpful_header
    post = create_favorites_post('2023', 'content')
    @validator.check_tag(post, 'title="Some Book"')

    error = assert_raises(RuntimeError) { @validator.raise_if_errors! }
    assert_includes error.message, 'FavoritesValidator'
    assert_includes error.message, 'date parameter'
  end

  # --- Unit tests for check_date_match ---

  def test_date_mismatch_raises_error
    post = create_favorites_post('2023', 'content')

    @validator.check_date_match(post, 'Some Book', '2099-01-01')

    error = assert_raises(RuntimeError) { @validator.raise_if_errors! }
    assert_includes error.message, 'No matching review'
    assert_includes error.message, 'Some Book'
    assert_includes error.message, '2099-01-01'
  end

  def test_multiple_date_mismatches_all_captured
    post = create_favorites_post('2023', 'content')

    @validator.check_date_match(post, 'Book A', '2099-01-01')
    @validator.check_date_match(post, 'Book B', '2099-02-01')

    error = assert_raises(RuntimeError) { @validator.raise_if_errors! }
    assert_includes error.message, 'Book A'
    assert_includes error.message, 'Book B'
  end

  def test_both_error_types_reported_together
    post = create_favorites_post('2023', 'content')

    @validator.check_tag(post, 'title="Missing Date Book"')
    @validator.check_date_match(post, 'Wrong Date Book', '2099-01-01')

    error = assert_raises(RuntimeError) { @validator.raise_if_errors! }
    assert_includes error.message, 'Missing date parameter'
    assert_includes error.message, 'Missing Date Book'
    assert_includes error.message, 'No matching review'
    assert_includes error.message, 'Wrong Date Book'
  end

  # --- Integration tests through FavoritesManager ---

  def test_integration_favorites_manager_raises_on_missing_date
    book = create_doc({ 'title' => 'Blindsight' }, '/books/blindsight.html')
    favorites_post = create_doc(
      { 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 },
      '/posts/fav23.html',
      '{% book_card_lookup title="Blindsight" %}'
    )

    error = assert_raises(RuntimeError) do
      create_site(
        {},
        { 'books' => [book] },
        [],
        [favorites_post]
      )
    end

    assert_includes error.message, 'Missing date parameter'
    assert_includes error.message, 'Blindsight'
  end

  def test_integration_favorites_manager_passes_with_date
    book = create_doc(
      { 'title' => 'Blindsight', 'date' => Time.parse('2023-12-15') },
      '/books/blindsight.html'
    )
    favorites_post = create_doc(
      { 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 },
      '/posts/fav23.html',
      '{% book_card_lookup title="Blindsight" date="2023-12-15" %}'
    )

    # Should not raise
    site = create_site(
      {},
      { 'books' => [book] },
      [],
      [favorites_post]
    )

    refute_nil site.data['link_cache']['favorites_mentions']
  end

  def test_integration_regular_post_without_date_does_not_raise
    book = create_doc({ 'title' => 'Blindsight' }, '/books/blindsight.html')
    regular_post = create_doc(
      { 'title' => 'Regular Post' },
      '/posts/regular.html',
      '{% book_card_lookup title="Blindsight" %}'
    )

    # Should not raise - regular posts are not validated
    site = create_site(
      {},
      { 'books' => [book] },
      [],
      [regular_post]
    )

    refute_nil site.data['link_cache']
  end

  def test_integration_multiple_violations_all_reported
    book_a = create_doc({ 'title' => 'Book A' }, '/books/a.html')
    book_b = create_doc({ 'title' => 'Book B' }, '/books/b.html')

    favorites_post = create_doc(
      { 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 },
      '/posts/fav23.html',
      '{% book_card_lookup title="Book A" %} and {% book_card_lookup title="Book B" %}'
    )

    error = assert_raises(RuntimeError) do
      create_site(
        {},
        { 'books' => [book_a, book_b] },
        [],
        [favorites_post]
      )
    end

    assert_includes error.message, 'Book A'
    assert_includes error.message, 'Book B'
  end

  def test_integration_some_valid_some_invalid_only_invalid_reported
    book_a = create_doc(
      { 'title' => 'Book A', 'date' => Time.parse('2023-01-01') },
      '/books/a.html'
    )
    book_b = create_doc({ 'title' => 'Book B' }, '/books/b.html')

    favorites_post = create_doc(
      { 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 },
      '/posts/fav23.html',
      '{% book_card_lookup title="Book A" date="2023-01-01" %} and {% book_card_lookup title="Book B" %}'
    )

    error = assert_raises(RuntimeError) do
      create_site(
        {},
        { 'books' => [book_a, book_b] },
        [],
        [favorites_post]
      )
    end

    refute_includes error.message, 'Book A'
    assert_includes error.message, 'Book B'
  end

  private

  def create_favorites_post(year, content, url = '/posts/favorites.html')
    create_doc(
      { 'title' => "Favorites #{year}", 'is_favorites_list' => year.to_i },
      url,
      content
    )
  end
end
