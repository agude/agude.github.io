# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/fixture_site'

# The generator tests check JSON-LD hashes. This test checks the boundary
# they cannot see: the JsonLdInjector hook, head.html, and the HTML parser.
# It verifies that the script element survives HTML5 parsing of hostile
# post text, that hidden hover previews stay out of reviewBody, and that a
# book review references the same author and series @ids that the author
# and series pages declare.
class TestJsonLdRenderedSite < Minitest::Test
  # Text the book_link hover preview shows: the linked book's excerpt.
  PREVIEW_LEDE = 'Second Book is a fixture novel whose lede appears only in the hover preview.'

  # Code-sample text a review could contain: a closing script tag, and the
  # comment-then-script sequence that makes the parser ignore the real
  # closing tag (WHATWG "Restrictions for contents of script elements").
  HOSTILE_CODE = 'close with </script> or open <!-- <script> here'

  FILES = {
    '_books/first_book.md' => <<~MARKDOWN,
      ---
      title: First Book
      book_authors: Fixture Author
      series: Fixture Saga
      book_number: 1
      rating: 4
      wikidata_qid: Q1
      same_as_urls:
        - "https://example.org/first-book"
      ---

      First Book is better than {% book_link "Second Book" %}.

      A code sample: `#{HOSTILE_CODE}`.
    MARKDOWN
    '_books/second_book.md' => <<~MARKDOWN,
      ---
      title: Second Book
      book_authors: Fixture Author
      series: null
      book_number: 1
      rating: 3
      wikidata_qid: Q2
      ---

      #{PREVIEW_LEDE}

      More about Second Book.
    MARKDOWN
    'books/authors/fixture_author.md' => <<~MARKDOWN,
      ---
      layout: author_page
      title: Fixture Author
      wikidata_qid: Q3
      same_as_urls:
        - "https://example.org/fixture-author"
      ---
    MARKDOWN
    'books/series/fixture_saga.md' => <<~MARKDOWN,
      ---
      layout: series_page
      title: Fixture Saga
      ---
    MARKDOWN
  }.freeze

  def self.site_dir
    @site_dir ||= FixtureSite.build(files: FILES).destination!
  end

  # Unescaped, `<!-- <script>` makes the parser treat the real closing tag
  # as text, so the script element runs to the end of the document and its
  # text is no longer JSON.
  def test_book_review_json_ld_parses_after_html_parsing
    review = json_ld(parse_page('books/first_book/index.html'))

    assert_equal 'Review', review['@type']
    assert_equal 'First Book', review.dig('itemReviewed', 'name')
  end

  def test_hostile_review_text_survives_html_parsing
    page = parse_page('books/first_book/index.html')

    assert_includes json_ld(page)['reviewBody'], HOSTILE_CODE
    refute_nil page.at_css('body'), 'body was swallowed by the JSON-LD script element'
    assert_includes page.at_css('body').text, 'A code sample'
  end

  def test_review_body_excludes_hover_preview
    page = parse_page('books/first_book/index.html')
    body = page.at_css('body')

    assert_includes body.inner_html, '<!--book-preview-->', 'fixture should render a real hover preview'
    assert_includes body.inner_html, PREVIEW_LEDE
    review_body = json_ld(page)['reviewBody']
    assert_includes review_body, 'First Book is better than Second Book.'
    refute_includes review_body, PREVIEW_LEDE
  end

  def test_review_author_id_matches_author_page
    review = json_ld(parse_page('books/first_book/index.html'))
    author_page = json_ld(parse_page('books/authors/fixture_author/index.html'))

    review_author = review.dig('itemReviewed', 'author')
    assert_equal 'https://example.com/books/authors/fixture_author/#person', review_author['@id']
    assert_equal author_page.dig('about', '@id'), review_author['@id']
    assert_equal author_page.dig('about', 'sameAs'), review_author['sameAs']
  end

  def test_review_series_id_matches_series_page
    review = json_ld(parse_page('books/first_book/index.html'))
    series_page = json_ld(parse_page('books/series/fixture_saga/index.html'))

    series = review.dig('itemReviewed', 'isPartOf')
    assert_equal 'https://example.com/books/series/fixture_saga/#series', series['@id']
    assert_equal series_page.dig('about', '@id'), series['@id']
  end

  # head.html also emits a speculation rules script. This class already owns
  # the rendered head.html boundary and the fixture site, so the check lives
  # here rather than in a separate fixture build.
  def test_speculation_rules_json_parses_after_html_parsing
    scripts = parse_page('books/first_book/index.html').css('script[type="speculationrules"]')
    assert_equal 1, scripts.size, 'expected one speculation rules script'

    prefetch = JSON.parse(scripts.first.text).dig('prefetch', 0)
    assert_equal 'moderate', prefetch['eagerness']
    assert_includes prefetch.dig('where', 'and'), { 'href_matches' => '/*' }
  end

  private

  def parse_page(relative_path)
    Nokogiri::HTML5(File.read(File.join(self.class.site_dir, relative_path)))
  end

  def json_ld(page)
    scripts = page.css('script[type="application/ld+json"]')
    assert_equal 1, scripts.size, 'expected one JSON-LD script'
    JSON.parse(scripts.first.text)
  end
end
