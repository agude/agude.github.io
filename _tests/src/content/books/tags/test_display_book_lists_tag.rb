# frozen_string_literal: true

require 'nokogiri'
require_relative '../../../../test_helper'

# Exercises book list markup through Liquid with real finders and renderers.
class TestDisplayBookListsTag < Minitest::Test
  def setup
    @books = [
      create_doc(
        {
          'title' => 'The Zebra',
          'date' => Time.utc(2024, 2),
          'book_authors' => ['Jane & Doe'],
          'series' => 'The Amazing Series',
          'book_number' => 2,
          'rating' => 4,
          'awards' => ['Hugo', 'Nebula & Friends'],
        },
        '/books/zebra.html',
      ),
      create_doc(
        {
          'title' => 'The Apple',
          'date' => Time.utc(2024, 1),
          'book_authors' => ['Jane & Doe', 'John Roe'],
          'series' => 'The Amazing Series',
          'book_number' => 1,
        },
        '/books/apple.html',
      ),
      create_doc(
        { 'title' => '1984', 'date' => Time.utc(2022, 1), 'book_authors' => ['Jane & Doe'] },
        '/books/1984.html',
      ),
      create_doc(
        { 'title' => 'Apricot', 'date' => Time.utc(2022, 2), 'book_authors' => ['Solo Author'] },
        '/books/apricot.html',
      ),
      create_doc(
        { 'title' => 'A Berry', 'date' => Time.utc(2022, 3), 'series' => 'Series Beta' },
        '/books/berry.html',
      ),
    ]
    @site = create_site({}, { 'books' => @books })
  end

  def test_all_books_rejects_arguments
    assert_syntax_error('display_all_books_grouped some_arg', 'display_all_books_grouped', 'This tag does not accept any arguments.')
  end

  def test_awards_rejects_arguments
    assert_syntax_error('display_awards_page some_arg', 'display_awards_page', 'This tag does not accept any arguments.')
  end

  def test_author_requires_an_argument
    assert_syntax_error('display_books_by_author', 'display_books_by_author', 'Author name (string literal or variable) is required.')
  end

  def test_all_authors_rejects_arguments
    assert_syntax_error('display_books_by_author_then_series some_arg', 'display_books_by_author_then_series', 'This tag does not accept any arguments.')
  end

  def test_title_rejects_arguments
    assert_syntax_error('display_books_by_title_alpha_group some_arg', 'display_books_by_title_alpha_group', 'This tag does not accept any arguments.')
  end

  def test_year_rejects_arguments
    assert_syntax_error('display_books_by_year some_arg', 'display_books_by_year', 'This tag does not accept any arguments.')
  end

  def test_series_requires_an_argument
    assert_syntax_error('display_books_for_series', 'display_books_for_series', 'Series name (string literal or variable) is required.')
  end

  def test_card_grid_preserves_empty_wrapper_and_card_newlines
    renderer = Jekyll::Books::Lists::BookListRendererUtils
    book_renderer = Jekyll::Books::Core::BookCardRenderer

    assert_equal "<ul class=\"card-grid\">\n</ul>\n", renderer.render_card_grid([], nil)
    book_renderer.stub(:render, '<li>Book</li>') do
      assert_equal "<ul class=\"card-grid\">\n<li>Book</li>\n</ul>\n", renderer.render_card_grid([@books.first], nil)
      assert_equal "<ul class=\"card-grid\">\n<li>Book</li></ul>\n",
                   renderer.render_card_grid([@books.first], nil, append_newline: false)
    end
  end

  def test_all_books_html
    html = Nokogiri::HTML.fragment(render('display_all_books_grouped'))

    assert_equal [['#', '#standalone-books'], ['A', '#the-amazing-series'], ['B', '#series-beta']], nav_links(html)
    assert_equal %w[C D E F G H I J K L M N O P Q R S T U V W X Y Z], html.css('nav > span').map(&:text)
    assert_equal ['Standalone Books', 'The Amazing Series', 'Series Beta'], html.css('h2').map(&:text)
    assert_nav_targets(html, ['Standalone Books', 'The Amazing Series', 'Series Beta'])
    assert_equal [%w[1984 Apricot], ['The Apple', 'The Zebra'], ['A Berry']], card_grids(html)
  end

  def test_all_books_markdown
    output = render('display_all_books_grouped', mode: :markdown)

    assert_equal <<~MARKDOWN.chomp, output
      ## Standalone
      - [_1984_](/books/1984.html) by Jane & Doe
      - [_Apricot_](/books/apricot.html) by Solo Author
      ## The Amazing Series
      - [_The Apple_](/books/apple.html) by Jane & Doe, John Roe
      - [_The Zebra_](/books/zebra.html) by Jane & Doe --- ★★★★☆
      ## Series Beta
      - [_A Berry_](/books/berry.html)
    MARKDOWN
  end

  def test_all_books_markdown_with_only_standalone_books
    site = create_site({}, { 'books' => [@books[3]] })

    assert_equal "## Standalone\n- [_Apricot_](/books/apricot.html) by Solo Author",
                 render('display_all_books_grouped', site: site, mode: :markdown)
  end

  def test_author_html
    html = Nokogiri::HTML.fragment(render('display_books_by_author author', variables: { 'author' => 'Jane & Doe' }))

    assert_equal ['Standalone Books', 'The Amazing Series'], html.css('h2').map(&:text)
    assert_equal [%w[1984], ['The Apple', 'The Zebra']], card_grids(html)
    assert_empty html.css('nav')
  end

  def test_author_markdown
    output = render("display_books_by_author 'Jane & Doe'", mode: :markdown)

    assert_equal <<~MARKDOWN.chomp, output
      ## Standalone
      - [_1984_](/books/1984.html) by Jane & Doe
      ## The Amazing Series
      - [_The Apple_](/books/apple.html) by Jane & Doe, John Roe
      - [_The Zebra_](/books/zebra.html) by Jane & Doe --- ★★★★☆
    MARKDOWN
  end

  def test_author_markdown_with_only_series_books
    assert_equal "## The Amazing Series\n- [_The Apple_](/books/apple.html) by Jane & Doe, John Roe",
                 render("display_books_by_author 'John Roe'", mode: :markdown)
  end

  def test_author_markdown_with_only_standalone_books
    assert_equal "## Standalone\n- [_Apricot_](/books/apricot.html) by Solo Author",
                 render("display_books_by_author 'Solo Author'", mode: :markdown)
  end

  def test_all_authors_html
    output = render('display_books_by_author_then_series')
    html = Nokogiri::HTML.fragment(output)

    assert_includes output, 'Jane &amp; Doe'
    assert_equal [['J', '#jane-doe'], ['S', '#solo-author']], nav_links(html)
    assert_equal ('A'..'Z').to_a - %w[J S], html.css('nav > span').map(&:text)
    assert_equal ['Jane & Doe', 'John Roe', 'Solo Author'], html.css('h2.book-list-headline').map(&:text)
    assert_nav_targets(html, ['Jane & Doe', 'Solo Author'])
    assert_equal(
      %w[standalone-books-jane-doe jane-doe--the-amazing-series john-roe--the-amazing-series standalone-books-solo-author],
      html.css('h3').map { |heading| heading['id'] },
    )
    assert_equal [%w[1984], ['The Apple', 'The Zebra'], ['The Apple'], ['Apricot']], card_grids(html)
  end

  def test_all_authors_markdown
    output = render('display_books_by_author_then_series', mode: :markdown)

    assert_equal <<~MARKDOWN.chomp, output
      ## Jane & Doe
      ### Standalone
      - [_1984_](/books/1984.html) by Jane & Doe
      ### The Amazing Series
      - [_The Apple_](/books/apple.html) by Jane & Doe, John Roe
      - [_The Zebra_](/books/zebra.html) by Jane & Doe --- ★★★★☆
      ## John Roe
      ### The Amazing Series
      - [_The Apple_](/books/apple.html) by Jane & Doe, John Roe
      ## Solo Author
      ### Standalone
      - [_Apricot_](/books/apricot.html) by Solo Author
    MARKDOWN
  end

  def test_all_authors_html_prepends_finder_diagnostic
    site = create_site({}, { 'books' => [@books.last] })
    site.config['plugin_logging']['ALL_BOOKS_BY_AUTHOR_DISPLAY'] = true

    output = render('display_books_by_author_then_series', site: site)

    assert_match(
      /\A<!-- \[INFO\] ALL_BOOKS_BY_AUTHOR_DISPLAY_FAILURE: Reason='No published books with valid author names found\.'/,
      output,
    )
  end

  def test_title_html
    html = Nokogiri::HTML.fragment(render('display_books_by_title_alpha_group'))

    assert_equal [['#', '#letter-hash'], ['A', '#letter-a'], ['B', '#letter-b'], ['Z', '#letter-z']], nav_links(html)
    assert_equal ('A'..'Z').to_a - %w[A B Z], html.css('nav > span').map(&:text)
    assert_equal %w[# A B Z], html.css('h2.book-list-headline').map(&:text)
    assert_nav_targets(html, %w[# A B Z])
    assert_equal [%w[1984], ['The Apple', 'Apricot'], ['A Berry'], ['The Zebra']], card_grids(html)
  end

  def test_title_html_without_numeric_titles
    site = create_site({}, { 'books' => [@books.last] })
    html = Nokogiri::HTML.fragment(render('display_books_by_title_alpha_group', site: site))

    assert_equal [['B', '#letter-b']], nav_links(html)
    assert_equal ['#', *(('A'..'Z').to_a - ['B'])], html.css('nav > span').map(&:text)
    assert_nav_targets(html, ['B'])
  end

  def test_title_markdown
    output = render('display_books_by_title_alpha_group', mode: :markdown)

    assert_equal <<~MARKDOWN.chomp, output
      ## #
      - [_1984_](/books/1984.html) by Jane & Doe
      ## A
      - [_The Apple_](/books/apple.html) by Jane & Doe, John Roe
      - [_Apricot_](/books/apricot.html) by Solo Author
      ## B
      - [_A Berry_](/books/berry.html)
      ## Z
      - [_The Zebra_](/books/zebra.html) by Jane & Doe --- ★★★★☆
    MARKDOWN
  end

  def test_year_html
    html = Nokogiri::HTML.fragment(render('display_books_by_year'))

    assert_equal [['2024', '#year-2024'], ['2022', '#year-2022']], nav_links(html)
    assert_equal '2024 · 2022', html.at_css('nav').text.strip
    assert_equal %w[2024 2022], html.css('h2.book-list-headline').map(&:text)
    assert_nav_targets(html, %w[2024 2022])
    assert_equal [['The Zebra', 'The Apple'], ['A Berry', 'Apricot', '1984']], card_grids(html)
  end

  def test_year_markdown
    output = render('display_books_by_year', mode: :markdown)

    assert_equal <<~MARKDOWN.chomp, output
      ## 2024
      - [_The Zebra_](/books/zebra.html) by Jane & Doe --- ★★★★☆
      - [_The Apple_](/books/apple.html) by Jane & Doe, John Roe
      ## 2022
      - [_A Berry_](/books/berry.html)
      - [_Apricot_](/books/apricot.html) by Solo Author
      - [_1984_](/books/1984.html) by Jane & Doe
    MARKDOWN
  end

  def test_series_html
    html = Nokogiri::HTML.fragment(render("display_books_for_series 'The Amazing Series'"))

    assert_equal ['ul'], html.element_children.map(&:name)
    assert_equal [['The Apple', 'The Zebra']], card_grids(html)
  end

  def test_series_markdown
    output = render('display_books_for_series series', mode: :markdown, variables: { 'series' => 'The Amazing Series' })

    assert_equal <<~MARKDOWN.chomp, output
      1. [The Apple](/books/apple.html) by Jane & Doe, John Roe
      2. [The Zebra](/books/zebra.html) by Jane & Doe --- ★★★★☆
    MARKDOWN
  end

  def test_awards_html
    output = render('display_awards_page', site: awards_site)
    html = Nokogiri::HTML.fragment(output)

    assert_includes output, 'Nebula &amp; Friends'
    assert_equal ['Major Awards', 'My Favorite Books Lists'], html.css('h2').map(&:text)
    assert_equal ['Hugo Award', 'Nebula & Friends Award', 'Favorites 2024', 'Older Favorites'], html.css('h3').map(&:text)
    assert_equal [
      ['Hugo', '#hugo-award'],
      ['Nebula & Friends', '#nebula-friends-award'],
      ['2024', '#favorites-2024'],
      ['Older Favorites', '#older-favorites'],
    ],
                 nav_links(html)
    assert_equal ['Hugo · Nebula & Friends', 'Best of: 2024 · Older Favorites'], html.css('nav .nav-row').map(&:text)
    assert_equal(['/blog/favorites.html', '/blog/older.html'], html.css('h3 > a').map { |link| link['href'] })
    assert_equal [['The Zebra'], ['The Zebra'], ['The Zebra'], ['The Zebra']], card_grids(html)
    refute_includes output, 'Empty Favorites'
  end

  def test_awards_markdown
    output = render('display_awards_page', site: awards_site, mode: :markdown)

    assert_equal <<~MARKDOWN.chomp, output
      ## Major Awards
      ### Hugo Award
      - [_The Zebra_](/books/zebra.html) by Jane & Doe --- ★★★★☆
      ### Nebula & Friends Award
      - [_The Zebra_](/books/zebra.html) by Jane & Doe --- ★★★★☆
      ## My Favorite Books Lists
      ### [Favorites 2024](/favorites.html)
      - [_The Zebra_](/books/zebra.html) by Jane & Doe --- ★★★★☆
      ### [Older Favorites](/older.html)
      - [_The Zebra_](/books/zebra.html) by Jane & Doe --- ★★★★☆
    MARKDOWN
  end

  def test_empty_collection_renders_no_list
    site = create_site({}, { 'books' => [] })
    %w[display_all_books_grouped display_books_by_author_then_series display_books_by_title_alpha_group display_books_by_year].each do |tag|
      assert_equal '', render(tag, site: site), tag
      assert_equal '', render(tag, site: site, mode: :markdown), tag
    end
  end

  def test_author_logs_for_nil_variable_and_empty_literal
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true

    { 'missing_author' => 'N/A', "''" => '' }.each do |argument, value|
      output = render("display_books_by_author #{argument}")
      log = "<!-- [WARN] BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='Author name filter was empty or nil when fetching data.' " \
            "AuthorFilterInput='#{value}' SourcePage='current.html' -->"
      assert_equal log * 2, output
    end
  end

  def test_series_logs_for_nil_and_blank_filter_variables
    @site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true

    { nil => 'N/A', '   ' => '   ' }.each do |filter, value|
      output = render('display_books_for_series series', variables: { 'series' => filter })
      assert_equal "<!-- [WARN] BOOK_LIST_SERIES_DISPLAY_FAILURE: Reason='Series name filter was empty or nil.' " \
                   "SeriesFilterInput='#{value}' SourcePage='current.html' -->",
                   output
    end
  end

  def test_awards_omits_favorites_section_when_the_only_post_has_no_books
    site = create_site({}, { 'books' => [@books.first] }, [], [empty_favorites_post])
    html = Nokogiri::HTML.fragment(render('display_awards_page', site: site))

    assert_equal ['Major Awards'], html.css('h2').map(&:text)
    assert_equal [['Hugo', '#hugo-award'], ['Nebula & Friends', '#nebula-friends-award']], nav_links(html)
  end

  def test_awards_can_render_favorites_without_award_winners
    book = create_doc({ 'title' => 'Favorite Book', 'date' => Time.utc(2024, 2) }, '/books/favorite.html')
    post = favorite_post('Favorites 2024', '/favorites.html', 2024, 'Favorite Book')
    site = create_site({}, { 'books' => [book] }, [], [post])
    html = Nokogiri::HTML.fragment(render('display_awards_page', site: site))

    assert_equal ['My Favorite Books Lists'], html.css('h2').map(&:text)
    assert_equal [['2024', '#favorites-2024']], nav_links(html)
    assert_equal 'Best of: 2024', html.at_css('nav').text.strip
  end

  def test_awards_renders_only_diagnostics_when_both_sources_are_missing
    site = create_site
    site.data['link_cache'].delete('favorites_posts_to_books')
    site.config['plugin_logging'].merge!('BOOK_LIST_UTIL' => true, 'BOOK_LIST_FAVORITES' => true)

    output = render('display_awards_page', site: site)

    assert_match(/\A<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: [^<>]+ --><!-- \[ERROR\] BOOK_LIST_FAVORITES_FAILURE: [^<>]+ -->\z/, output)
    assert_equal '', render('display_awards_page', site: site, mode: :markdown)
  end

  private

  def assert_syntax_error(markup, name, message)
    error = assert_raises(Liquid::SyntaxError) { Liquid::Template.parse("{% #{markup} %}") }
    assert_equal "Liquid syntax error: Syntax Error in '#{name}': #{message}", error.message
  end

  def render(markup, site: @site, mode: nil, variables: {})
    context = create_context(variables, { site: site, page: create_doc({}, '/current.html'), render_mode: mode })
    Jekyll.stub(:logger, silent_logger) { Liquid::Template.parse("{% #{markup} %}").render!(context) }
  end

  def nav_links(html)
    html.css('nav a').map { |link| [link.text, link['href']] }
  end

  def assert_nav_targets(html, expected_heading_texts)
    headings = html.css('h2, h3')
    target_texts = html.css('nav a[href^="#"]').map do |link|
      id = link['href'].delete_prefix('#')
      matches = headings.select { |heading| heading['id'] == id }
      assert_equal 1, matches.size, "Expected exactly one heading for ##{id}"
      matches.first.text
    end
    assert_equal expected_heading_texts, target_texts
  end

  def card_grids(html)
    html.css('ul.card-grid').map { |grid| grid.css('li cite.book-title').map(&:text) }
  end

  def awards_site
    posts = [
      favorite_post('Favorites 2024', '/favorites.html', 2024, 'The Zebra'),
      favorite_post('Older Favorites', '/older.html', nil, 'The Zebra'),
      empty_favorites_post,
    ]
    create_site({ 'baseurl' => '/blog' }, { 'books' => @books }, [], posts)
  end

  def favorite_post(title, url, year, book)
    create_doc(
      { 'title' => title, 'is_favorites_list' => year },
      url,
      "{% book_card_lookup title=\"#{book}\" date=\"2024-02-01\" %}",
    )
  end

  def empty_favorites_post
    create_doc({ 'title' => 'Empty Favorites', 'is_favorites_list' => 2025 }, '/empty.html')
  end
end
