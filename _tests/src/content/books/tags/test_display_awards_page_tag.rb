# frozen_string_literal: true

# _tests/plugins/test_display_awards_page_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/tags/display_awards_page_tag'

# Tests for Jekyll::Books::Tags::DisplayAwardsPageTag Liquid tag.
#
# Verifies that the tag correctly displays books grouped by award type.
class TestDisplayAwardsPageTag < Minitest::Test
  def setup
    create_test_data
    @site = create_site({ 'url' => 'http://example.com' })
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current.html' }, '/current.html') })
    @silent_logger_stub = create_silent_logger_stub
  end

  def render_tag(
    context = @context,
    awards_data = @mock_awards_data_hash,
    favorites_data = @mock_favorites_data_hash
  )
    output = ''
    # Stub the ByAwardFinder instance
    mock_award_finder = Minitest::Mock.new
    mock_award_finder.expect :find, awards_data

    # Stub the FavoritesListsFinder instance
    mock_favorites_finder = Minitest::Mock.new
    mock_favorites_finder.expect :find, favorites_data

    Jekyll::Books::Lists::ByAwardFinder.stub :new, ->(_args) { mock_award_finder } do
      Jekyll::Books::Lists::FavoritesListsFinder.stub :new, ->(_args) { mock_favorites_finder } do
        Jekyll::Books::Core::BookCardUtils.stub :render, ->(book, _ctx) { "<!-- Card for: #{book.data['title']} -->\n" } do
          Jekyll.stub :logger, @silent_logger_stub do
            output = Liquid::Template.parse('{% display_awards_page %}').render!(context)
          end
        end
      end
    end
    mock_award_finder.verify
    mock_favorites_finder.verify
    output
  end

  def test_renders_unified_nav_and_both_sections
    output = render_tag

    assert_unified_navigation(output)
    assert_major_awards_section(output)
    assert_favorites_section(output)
    assert_section_order(output)
  end

  def test_renders_correctly_with_only_awards_data
    empty_favorites = { favorites_lists: [], log_messages: '' }
    output = render_tag(@context, @mock_awards_data_hash, empty_favorites)

    assert_match(/<nav class="alpha-jump-links">/, output)
    expected_awards_nav =
      '<div class="nav-row"><a href="#hugo-award">Hugo</a> &middot; <a href="#nebula-award">Nebula</a></div>'
    assert_includes output, expected_awards_nav
    refute_match(/My Favorite Books/, output) # No favorites links or sections

    assert_match %r{<h2>Major Awards</h2>}, output
    refute_match %r{<h2>My Favorite Books Lists</h2>}, output
  end

  def test_renders_correctly_with_only_favorites_data
    empty_awards = { awards_data: [], log_messages: '' }
    output = render_tag(@context, empty_awards, @mock_favorites_data_hash)

    assert_match(/<nav class="alpha-jump-links">/, output)
    expected_favorites_nav =
      '<div class="nav-row"><a href="#my-favorite-books-of-2024">My Favorite Books of 2024</a> &middot; <a href="#my-favorite-books-of-2023">My Favorite Books of 2023</a></div>'
    assert_includes output, expected_favorites_nav
    refute_match(/<a href="#hugo-award">/, output) # No award links

    refute_match %r{<h2>Major Awards</h2>}, output
    assert_match %r{<h2>My Favorite Books Lists</h2>}, output
  end

  def test_renders_only_logs_if_both_data_sources_are_empty
    empty_awards = { awards_data: [], log_messages: '<!-- Awards Log -->' }
    empty_favorites = { favorites_lists: [], log_messages: '<!-- Favorites Log -->' }
    output = render_tag(@context, empty_awards, empty_favorites)

    assert_match '<!-- Awards Log --><!-- Favorites Log -->', output
    refute_match(/<nav class="alpha-jump-links">/, output)
    refute_match(/<h2>/, output)
  end

  def test_syntax_error_with_arguments
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_awards_page some_arg %}')
    end
    assert_match 'This tag does not accept any arguments', err.message
  end

  private

  # Creates test data for awards and favorites
  def create_test_data
    create_awards_data
    create_favorites_data
  end

  # Creates mock data for awards section
  def create_awards_data
    @award_book_hugo = create_doc({ 'title' => 'Hugo Book', 'awards' => ['Hugo'] }, '/hugo-book.html')
    @award_book_nebula = create_doc({ 'title' => 'Nebula Book', 'awards' => ['Nebula'] }, '/nebula-book.html')
    @mock_awards_data_hash = {
      awards_data: [
        { award_name: 'Hugo Award', award_slug: 'hugo-award', books: [@award_book_hugo] },
        { award_name: 'Nebula Award', award_slug: 'nebula-award', books: [@award_book_nebula] }
      ],
      log_messages: ''
    }
  end

  # Creates mock data for favorites section
  def create_favorites_data
    @fav_post_year_2024 = create_doc({ 'title' => 'My Favorite Books of 2024' }, '/fav24.html')
    @fav_post_year_2023 = create_doc({ 'title' => 'My Favorite Books of 2023' }, '/fav23.html')
    @fav_book_alpha = create_doc({ 'title' => 'Fav Book A' }, '/books/a.html')
    @fav_book_beta = create_doc({ 'title' => 'Fav Book B' }, '/books/b.html')
    @mock_favorites_data_hash = {
      favorites_lists: [
        { post: @fav_post_year_2024, books: [@fav_book_alpha] },
        { post: @fav_post_year_2023, books: [@fav_book_beta] }
      ],
      log_messages: ''
    }
  end

  # Creates a silent logger stub
  def create_silent_logger_stub
    Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
  end

  # Asserts unified navigation bar is present
  def assert_unified_navigation(output)
    assert_match(/<nav class="alpha-jump-links">/, output)
    # Check for the full, structured nav rows
    expected_awards_nav =
      '<div class="nav-row"><a href="#hugo-award">Hugo</a> &middot; <a href="#nebula-award">Nebula</a></div>'
    assert_includes output, expected_awards_nav
    expected_favorites_nav =
      '<div class="nav-row"><a href="#my-favorite-books-of-2024">My Favorite Books of 2024</a> &middot; <a href="#my-favorite-books-of-2023">My Favorite Books of 2023</a></div>'
    assert_includes output, expected_favorites_nav
  end

  # Asserts "Major Awards" section is present and correct
  def assert_major_awards_section(output)
    assert_match %r{<h2>Major Awards</h2>}, output
    assert_match %r{<h3 class="book-list-headline" id="hugo-award">Hugo Award</h3>}, output
    assert_match %r{<div class="card-grid">\s*<!-- Card for: Hugo Book -->\s*</div>}m, output
    assert_match %r{<h3 class="book-list-headline" id="nebula-award">Nebula Award</h3>}, output
    assert_match %r{<div class="card-grid">\s*<!-- Card for: Nebula Book -->\s*</div>}m, output
  end

  # Asserts "My Favorite Books Lists" section is present and correct
  def assert_favorites_section(output)
    assert_match %r{<h2>My Favorite Books Lists</h2>}, output
    expected_h3_2024 =
      %r{<h3 class="book-list-headline" id="my-favorite-books-of-2024"><a href="/fav24.html">My Favorite Books of 2024</a></h3>}
    assert_match expected_h3_2024, output
    assert_match %r{<div class="card-grid">\s*<!-- Card for: Fav Book A -->\s*</div>}m, output
    expected_h3_2023 =
      %r{<h3 class="book-list-headline" id="my-favorite-books-of-2023"><a href="/fav23.html">My Favorite Books of 2023</a></h3>}
    assert_match expected_h3_2023, output
    assert_match %r{<div class="card-grid">\s*<!-- Card for: Fav Book B -->\s*</div>}m, output
  end

  # Asserts section order is correct
  def assert_section_order(output)
    idx_major_awards = output.index('<h2>Major Awards</h2>')
    idx_favorites = output.index('<h2>My Favorite Books Lists</h2>')
    refute_nil idx_major_awards
    refute_nil idx_favorites
    assert idx_major_awards < idx_favorites, 'Major Awards section should come before Favorites section'
  end
end
