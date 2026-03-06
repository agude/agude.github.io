# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/tags/render_book_awards_tag'

# Tests for RenderBookAwardsTag.
class TestRenderBookAwardsTag < Minitest::Test
  def setup
    @mention_2024 = create_doc({ 'title' => 'Favorites 2024', 'is_favorites_list' => 2024 }, '/fav-2024.html')
    @mention_2023 = create_doc({ 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 }, '/fav-2023.html')
  end

  # --- Renderer (HTML) tests ---

  def test_html_empty_returns_empty_string
    output = html_render(nil, nil)
    assert_equal '', output
  end

  def test_html_empty_arrays_returns_empty_string
    output = html_render([], [])
    assert_equal '', output
  end

  def test_html_awards_only
    output = html_render(%w[nebula hugo], nil)
    assert_includes output, '<div class="book-awards">Awards: '
    assert_includes output, '<a class="book-award" href="/books/by-award/#hugo-award">Hugo</a>'
    assert_includes output, '<a class="book-award" href="/books/by-award/#nebula-award">Nebula</a>'
    # Sorted: Hugo before Nebula
    assert output.index('Hugo') < output.index('Nebula')
    assert_includes output, '</div>'
  end

  def test_html_mentions_only
    output = html_render(nil, [@mention_2023, @mention_2024])
    assert_includes output, '<div class="book-awards">Awards: '
    assert_includes output, '<a class="book-favorite-link" href="/fav-2024.html">2024 Favorites</a>'
    assert_includes output, '<a class="book-favorite-link" href="/fav-2023.html">2023 Favorites</a>'
    # Sorted descending: 2024 before 2023
    assert output.index('2024') < output.index('2023')
  end

  def test_html_awards_and_mentions
    output = html_render(%w[hugo], [@mention_2024])
    assert_includes output, '<a class="book-award" href="/books/by-award/#hugo-award">Hugo</a>'
    assert_includes output, '<a class="book-favorite-link" href="/fav-2024.html">2024 Favorites</a>'
    # Comma between award and mention
    assert_match(%r{Hugo</a>, <a class="book-favorite-link"}, output)
  end

  def test_html_multi_word_capitalization
    output = html_render(['locus fantasy'], nil)
    assert_includes output, '>Locus Fantasy</a>'
    assert_includes output, 'href="/books/by-award/#locus-fantasy-award"'
  end

  def test_html_mentions_include_baseurl
    output = html_render_with_baseurl(%w[hugo], [@mention_2024], '/blog')
    assert_includes output, 'href="/blog/fav-2024.html"'
    # Award hrefs are absolute paths — no baseurl
    assert_includes output, 'href="/books/by-award/#hugo-award"'
  end

  def test_html_book_not_in_favorites_cache
    # Book URL has no entry in favorites_mentions (key missing, not nil)
    site = create_site_with_mentions(nil, nil)
    refute site.data['link_cache']['favorites_mentions'].key?('/books/test-book/')

    page = site.collections['books'].docs.first
    context = create_context({}, { site: site, page: page })
    output = Jekyll::Books::Tags::RenderBookAwardsTag::Renderer.new(context).render
    assert_equal '', output
  end

  # --- Tag integration tests ---

  def test_tag_html_delegation
    site = create_site_with_mentions(%w[hugo], [@mention_2024])
    context = create_context({}, { site: site, page: site.collections['books'].docs.first })
    output = Liquid::Template.parse('{% render_book_awards %}').render!(context)

    assert_includes output, '<div class="book-awards">'
    assert_includes output, 'Hugo'
    assert_includes output, '2024 Favorites'
  end

  def test_tag_html_empty
    site = create_site_with_mentions(nil, nil)
    context = create_context({}, { site: site, page: site.collections['books'].docs.first })
    output = Liquid::Template.parse('{% render_book_awards %}').render!(context)

    assert_equal '', output
  end

  def test_tag_syntax_error
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% render_book_awards some_arg %}')
    end
    assert_match 'This tag does not accept any arguments', err.message
  end

  def test_tag_markdown_delegation
    site = create_site_with_mentions(%w[hugo], [@mention_2024])
    page = site.collections['books'].docs.first
    context = create_context({}, { site: site, page: page, render_mode: :markdown })
    output = Liquid::Template.parse('{% render_book_awards %}').render!(context)

    assert_includes output, 'Awards: '
    assert_includes output, '[Hugo](/books/by-award/#hugo-award)'
    refute_match(/<div/, output)
    refute_match(/<a /, output)
  end

  def test_tag_markdown_empty
    site = create_site_with_mentions(nil, nil)
    page = site.collections['books'].docs.first
    context = create_context({}, { site: site, page: page, render_mode: :markdown })
    output = Liquid::Template.parse('{% render_book_awards %}').render!(context)

    assert_instance_of String, output, 'Tag#render must return a String, not nil'
    assert_equal '', output
  end

  private

  def html_render(awards, mentions, baseurl: '')
    site = create_site_with_mentions(awards, mentions, baseurl: baseurl)
    page = site.collections['books'].docs.first
    context = create_context({}, { site: site, page: page })
    Jekyll::Books::Tags::RenderBookAwardsTag::Renderer.new(context).render
  end

  def html_render_with_baseurl(awards, mentions, baseurl)
    html_render(awards, mentions, baseurl: baseurl)
  end

  def create_site_with_mentions(awards, mentions, baseurl: '')
    book = create_doc(
      { 'title' => 'Test Book', 'awards' => awards, 'layout' => 'book' },
      '/books/test-book/',
      'content',
      nil,
      MockCollection.new([], 'books'),
    )
    site = create_site(
      { 'baseurl' => baseurl },
      { 'books' => [book] },
    )
    # Inject favorites_mentions into link cache
    site.data['link_cache'] ||= {}
    site.data['link_cache']['favorites_mentions'] ||= {}
    site.data['link_cache']['favorites_mentions']['/books/test-book/'] = mentions if mentions
    site
  end
end
