# _tests/plugins/test_display_awards_page_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_awards_page_tag'

class TestDisplayAwardsPageTag < Minitest::Test
  def setup
    # --- Mock Data for Awards Section ---
    @award_book_hugo = create_doc({ 'title' => 'Hugo Book', 'awards' => ['Hugo'] }, '/hugo-book.html')
    @award_book_nebula = create_doc({ 'title' => 'Nebula Book', 'awards' => ['Nebula'] }, '/nebula-book.html')
    @mock_awards_data_hash = {
      awards_data: [
        { award_name: 'Hugo Award', award_slug: 'hugo-award', books: [@award_book_hugo] },
        { award_name: 'Nebula Award', award_slug: 'nebula-award', books: [@award_book_nebula] }
      ],
      log_messages: ""
    }

    # --- Mock Data for Favorites Section ---
    @fav_post_2024 = create_doc({ 'title' => 'My Favorite Books of 2024' }, '/fav24.html')
    @fav_post_2023 = create_doc({ 'title' => 'My Favorite Books of 2023' }, '/fav23.html')
    @fav_book_a = create_doc({ 'title' => 'Fav Book A' }, '/books/a.html')
    @fav_book_b = create_doc({ 'title' => 'Fav Book B' }, '/books/b.html')
    @mock_favorites_data_hash = {
      favorites_lists: [
        { post: @fav_post_2024, books: [@fav_book_a] },
        { post: @fav_post_2023, books: [@fav_book_b] }
      ],
      log_messages: ""
    }

    @site = create_site({ 'url' => 'http://example.com' })
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current.html' }, '/current.html') })

    @silent_logger_stub = Object.new.tap do |l|
      def l.warn(p,m);end; def l.error(p,m);end; def l.info(p,m);end; def l.debug(p,m);end
    end
  end

  def render_tag(context = @context, awards_data = @mock_awards_data_hash, favorites_data = @mock_favorites_data_hash)
    output = ""
    BookListUtils.stub :get_data_for_all_books_by_award_display, ->(args) { awards_data } do
      BookListUtils.stub :get_data_for_favorites_lists, ->(args) { favorites_data } do
        BookCardUtils.stub :render, ->(book, _ctx) { "<!-- Card for: #{book.data['title']} -->\n" } do
          Jekyll.stub :logger, @silent_logger_stub do
            output = Liquid::Template.parse("{% display_awards_page %}").render!(context)
          end
        end
      end
    end
    output
  end

  def test_renders_unified_nav_and_both_sections
    output = render_tag

    # --- Assert Unified Navigation Bar ---
    assert_match %r{<nav class="alpha-jump-links">}, output
    # Award links (shortened)
    assert_match %r{<a href="#hugo-award">Hugo</a>}, output
    assert_match %r{<a href="#nebula-award">Nebula</a>}, output
    # Favorites links (full title)
    assert_match %r{<a href="#my-favorite-books-of-2024">My Favorite Books of 2024</a>}, output
    assert_match %r{<a href="#my-favorite-books-of-2023">My Favorite Books of 2023</a>}, output

    # --- Assert "Major Awards" Section ---
    assert_match %r{<h2>Major Awards</h2>}, output
    assert_match %r{<h3 class="book-list-headline" id="hugo-award">Hugo Award</h3>}, output
    assert_match %r{<div class="card-grid">\s*<!-- Card for: Hugo Book -->\s*</div>}m, output
    assert_match %r{<h3 class="book-list-headline" id="nebula-award">Nebula Award</h3>}, output
    assert_match %r{<div class="card-grid">\s*<!-- Card for: Nebula Book -->\s*</div>}m, output

    # --- Assert "My Favorite Books Lists" Section ---
    assert_match %r{<h2>My Favorite Books Lists</h2>}, output
    assert_match %r{<h3 class="book-list-headline" id="my-favorite-books-of-2024"><a href="/fav24.html">My Favorite Books of 2024</a></h3>}, output
    assert_match %r{<div class="card-grid">\s*<!-- Card for: Fav Book A -->\s*</div>}m, output
    assert_match %r{<h3 class="book-list-headline" id="my-favorite-books-of-2023"><a href="/fav23.html">My Favorite Books of 2023</a></h3>}, output
    assert_match %r{<div class="card-grid">\s*<!-- Card for: Fav Book B -->\s*</div>}m, output

    # --- Assert Section Order ---
    idx_major_awards = output.index('<h2>Major Awards</h2>')
    idx_favorites = output.index('<h2>My Favorite Books Lists</h2>')
    refute_nil idx_major_awards
    refute_nil idx_favorites
    assert idx_major_awards < idx_favorites, "Major Awards section should come before Favorites section"
  end

  def test_renders_correctly_with_only_awards_data
    empty_favorites = { favorites_lists: [], log_messages: "" }
    output = render_tag(@context, @mock_awards_data_hash, empty_favorites)

    assert_match %r{<nav class="alpha-jump-links">}, output
    assert_match %r{<a href="#hugo-award">Hugo</a>}, output
    refute_match %r{My Favorite Books}, output # No favorites links or sections

    assert_match %r{<h2>Major Awards</h2>}, output
    refute_match %r{<h2>My Favorite Books Lists</h2>}, output
  end

  def test_renders_correctly_with_only_favorites_data
    empty_awards = { awards_data: [], log_messages: "" }
    output = render_tag(@context, empty_awards, @mock_favorites_data_hash)

    assert_match %r{<nav class="alpha-jump-links">}, output
    assert_match %r{<a href="#my-favorite-books-of-2024">My Favorite Books of 2024</a>}, output
    refute_match %r{<a href="#hugo-award">}, output # No award links

    refute_match %r{<h2>Major Awards</h2>}, output
    assert_match %r{<h2>My Favorite Books Lists</h2>}, output
  end

  def test_renders_only_logs_if_both_data_sources_are_empty
    empty_awards = { awards_data: [], log_messages: "<!-- Awards Log -->" }
    empty_favorites = { favorites_lists: [], log_messages: "<!-- Favorites Log -->" }
    output = render_tag(@context, empty_awards, empty_favorites)

    assert_match "<!-- Awards Log --><!-- Favorites Log -->", output
    refute_match %r{<nav class="alpha-jump-links">}, output
    refute_match %r{<h2>}, output
  end

  def test_syntax_error_with_arguments
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_awards_page some_arg %}")
    end
    assert_match "This tag does not accept any arguments", err.message
  end
end
