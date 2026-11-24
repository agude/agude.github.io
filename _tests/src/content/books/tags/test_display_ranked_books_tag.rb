# frozen_string_literal: true

require_relative '../../../../test_helper'

# Exercises ranked-book validation and both formats through Liquid.
class TestDisplayRankedBooksTag < Minitest::Test
  def setup
    books = [
      create_doc({ 'title' => 'Book A (5 Stars)', 'rating' => 5 }, '/b5a.html'),
      create_doc({ 'title' => 'Book B (5 Stars)', 'rating' => '5' }, '/b5b.html'),
      create_doc({ 'title' => 'Book C (4 Stars)', 'rating' => 4 }, '/b4a.html'),
      create_doc({ 'title' => 'Book D (1 Star)', 'rating' => 1 }, '/b1a.html'),
    ]
    titles = books.map { |book| book.data['title'] }
    books << create_doc({ 'title' => 'Book Invalid Rating', 'rating' => 'five_stars' }, '/bir.html')

    @non_existent_title_list = [titles[0], 'Non Existent Book', titles[2]]
    @invalid_rating_list = [titles[0], 'Book Invalid Rating', titles[2]]
    @monotonic_violation_list = [titles[2], titles[0]]
    @context_dev = ranked_context(books, titles, environment: 'development')
    @context_prod = ranked_context(books, titles, environment: 'production')
  end

  def test_processor_rejects_missing_book_in_production_mode
    @context_prod['page']['ranked_list'] = @non_existent_title_list
    processor = Jekyll::Books::Ranking::RankedBooks::Processor.new(@context_prod, 'page.ranked_list')

    error = assert_raises(Jekyll::Errors::FatalException) { processor.process }
    assert_match 'Non Existent Book', error.message
  end

  def test_processor_rejects_invalid_rating_in_production_mode
    @context_prod['page']['ranked_list'] = @invalid_rating_list
    processor = Jekyll::Books::Ranking::RankedBooks::Processor.new(@context_prod, 'page.ranked_list')

    error = assert_raises(Jekyll::Errors::FatalException) { processor.process }
    assert_match 'invalid non-integer rating', error.message
  end

  def test_syntax_error_missing_list_variable
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_ranked_books %}')
    end
    assert_match 'A variable name holding the list must be provided', err.message
  end

  def test_runtime_error_if_list_variable_not_an_array
    @context_dev['page']['ranked_list'] = 'not_an_array'
    err = assert_raises Jekyll::Errors::FatalException do
      render_tag('page.ranked_list', @context_dev)
    end
    assert_match "Input 'page.ranked_list' is not a valid list (Array)", err.message
  end

  def test_runtime_error_if_books_collection_missing
    @context_dev.registers[:site].collections.delete('books')
    err = assert_raises Jekyll::Errors::FatalException do
      render_tag('page.ranked_list', @context_dev)
    end
    assert_match "Collection 'books' not found", err.message
  end

  def test_dev_mode_raises_error_for_non_existent_title_in_list
    @context_dev['page']['ranked_list'] = @non_existent_title_list
    err = assert_raises Jekyll::Errors::FatalException do
      render_tag('page.ranked_list', @context_dev)
    end
    assert_match "Title 'Non Existent Book' (position 2 in 'page.ranked_list') not found", err.message
  end

  def test_dev_mode_raises_error_for_invalid_rating_in_list
    @context_dev['page']['ranked_list'] = @invalid_rating_list
    err = assert_raises Jekyll::Errors::FatalException do
      render_tag('page.ranked_list', @context_dev)
    end
    assert_match "Title 'Book Invalid Rating' (position 2 in 'page.ranked_list') has invalid non-integer rating: '\"five_stars\"'",
                 err.message
  end

  def test_dev_mode_raises_error_for_monotonic_violation
    @context_dev['page']['ranked_list'] = @monotonic_violation_list
    err = assert_raises Jekyll::Errors::FatalException do
      render_tag('page.ranked_list', @context_dev)
    end
    assert_match "Monotonicity violation in 'page.ranked_list'", err.message
    assert_match "Title 'Book A (5 Stars)' (Rating: 5) at position 2", err.message
    assert_match "cannot appear after \n  Title 'Book C (4 Stars)' (Rating: 4) at position 1", err.message
  end

  def test_prod_mode_stops_build_for_non_existent_title
    @context_prod['page']['ranked_list'] = @non_existent_title_list

    error = assert_raises(Jekyll::Errors::FatalException) do
      render_tag('page.ranked_list', @context_prod)
    end
    assert_match 'Non Existent Book', error.message
  end

  def test_prod_mode_stops_build_for_invalid_rating
    @context_prod['page']['ranked_list'] = @invalid_rating_list

    error = assert_raises(Jekyll::Errors::FatalException) do
      render_tag('page.ranked_list', @context_prod)
    end
    assert_match 'invalid non-integer rating', error.message
  end

  def test_renderer_keeps_grid_for_rating_group_without_books
    output = Jekyll::Books::Ranking::RankedBooks::Renderer.new(@context_dev, [{ rating: 4, books: [] }]).render
    assert_includes output, '<ul class="card-grid">'
  end

  def test_renders_empty_if_ranked_list_is_empty
    @context_dev['page']['ranked_list'] = []

    assert_equal '', render_tag('page.ranked_list', @context_dev)
  end

  def test_markdown_mode_renders_star_headings_and_book_links
    @context_dev.registers[:render_mode] = :markdown
    output = render_tag('page.ranked_list', @context_dev)

    assert_equal ['## ★★★★★', '## ★★★★☆', '## ★☆☆☆☆'], output.lines.grep(/^## /).map(&:chomp)
    assert_equal ['/b5a.html', '/b5b.html', '/b4a.html', '/b1a.html'], output.scan(/^- \[_.*?_\]\(([^)]+)\)/).flatten
    refute_match(/<(?:ul|nav|div)\b/, output)
  end

  def test_correct_html_structure_and_grouping_for_valid_list
    output = render_tag('page.ranked_list', @context_dev)
    fragment = Nokogiri::HTML.fragment(output)
    nav = fragment.at_css('nav.alpha-jump-links')
    expected_nav_links = '<a href="#rating-5">5&nbsp;Stars</a> &middot; ' \
                         '<a href="#rating-4">4&nbsp;Stars</a> &middot; <a href="#rating-1">1&nbsp;Star</a>'
    assert_includes output, expected_nav_links
    jump_targets = nav.css('a').map { |link| link['href'] }
    heading_ids = fragment.css('h2.book-list-headline').map { |heading| heading['id'] }
    assert_equal %w[#rating-5 #rating-4 #rating-1], jump_targets
    assert_equal %w[rating-5 rating-4 rating-1], heading_ids
    assert_equal ['★★★★★', '★★★★☆', '★☆☆☆☆'], fragment.css('h2 > span.book-rating').map(&:text)

    titles = fragment.css('h2 + ul.card-grid').map do |grid|
      grid.css('li.book-card cite.book-title').map(&:text)
    end
    assert_equal [['Book A (5 Stars)', 'Book B (5 Stars)'], ['Book C (4 Stars)'], ['Book D (1 Star)']], titles
  end

  private

  def ranked_context(books, titles, environment:)
    site = create_site({ 'environment' => environment, 'url' => 'http://example.com' })
    site.collections = { 'books' => MockCollection.new(books, 'books') }
    page = { 'ranked_list' => titles.dup, 'path' => 'test_page.md' }
    create_context({ 'page' => page }, { site: site, page: create_doc(page, '/test_page.html') })
  end

  def render_tag(list_variable_name, context)
    Jekyll.stub(:logger, silent_logger) do
      Liquid::Template.parse("{% display_ranked_books #{list_variable_name} %}").render!(context)
    end
  end
end
