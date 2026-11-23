# frozen_string_literal: true

require_relative '../../../../test_helper'

# Checks direct and series backlinks in the rendered book footer.
class TestBacklinksRenderer < Minitest::Test
  def test_mixed_book_and_series_links
    book = create_doc({ 'title' => 'Target <Book>' }, '/books/target/')
    direct = create_doc({ 'title' => 'Direct Book' }, '/books/direct/')
    series = create_doc({ 'title' => 'Series Book' }, '/books/series/')
    site = create_site({}, { 'books' => [book, direct, series] })
    site.data['link_cache']['backlinks'][book.url] = [
      { source: series, type: 'series' },
      { source: direct, type: 'book' },
    ]
    context = create_context({}, { site: site, page: book })

    output = Liquid::Template.parse('{% book_backlinks %}').render!(context)
    aside = Nokogiri::HTML5.fragment(output).at_css('aside.book-backlinks')
    assert_includes output, 'Target &lt;Book&gt;'
    assert_equal 'Target <Book>', aside.at_css('h2.book-backlink-section .book-title').text
    links = aside.css('ul.book-backlink-list > li.book-backlink-item')
    assert_equal(%w[book series], links.map { |link| link['data-link-type'] })
    assert_equal([direct.url, series.url], links.map { |link| link.at_css('a')['href'] })
    assert_nil links.first.at_css('sup')
    assert_equal '†', links.last.at_css('sup.series-mention-indicator').text
    assert_includes aside.at_css('.backlink-explanation').text, 'Mentioned via a link to the series.'
  end
end
