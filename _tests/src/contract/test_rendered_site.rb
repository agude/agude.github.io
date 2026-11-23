# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/fixture_site'

# Rendered behavior shared by one fixture with a nonempty baseurl.
class TestContractRenderedSite < Minitest::Test
  PUBLICATION_URI = 'at://did:web:example.com/site.standard.publication/fixture'
  FILES = {
    '_drafts/visible-draft.md' => <<~MARKDOWN,
      ---
      layout: post
      title: Visible Draft
      date: 2024-01-01 00:00:00 +0000
      ---
      A visible draft.
    MARKDOWN
    '_posts/2024-01-01-sample.md' => <<~MARKDOWN,
      ---
      layout: post
      title: Sample Post
      categories: [fixture]
      last_modified_at: 2024-06-10
      ---
      A sample post.
    MARKDOWN
    '_posts/2024-01-01-favorites.md' => <<~MARKDOWN,
      ---
      layout: post
      title: Favorites 2023
      is_favorites_list: 2023
      ---
      {% book_card_lookup title="Fixture Book" date="2023-01-01" %}
    MARKDOWN
    '_books/fixture.md' => <<~MARKDOWN,
      ---
      title: Fixture Book
      book_authors: Fixture Author
      book_number: 1
      wikidata_qid: Q1
      date: 2023-01-01
      ---
      A book review.
    MARKDOWN
    'books/authors/fixture_author.md' => <<~MARKDOWN,
      ---
      layout: author_page
      title: Fixture Author
      wikidata_qid: Q2
      ---
    MARKDOWN
    'books/awards.md' => <<~MARKDOWN,
      ---
      layout: page
      title: Awards
      permalink: /books/by-award/
      ---
      {% display_awards_page %}
    MARKDOWN
  }.freeze

  def self.site_dir
    @build ||= build_site
    @build.destination!
  end

  def self.build_site
    # Leave at least a day before the post date so crossing midnight is safe.
    future_post_date = Time.now.utc.to_date + 2
    config = {
      'baseurl' => '/preview',
      'show_drafts' => true,
      'time' => (future_post_date + 1).iso8601,
      'standard_site' => { 'publication_uri' => PUBLICATION_URI },
    }
    future_post = <<~MARKDOWN
      ---
      layout: post
      title: Future Post
      categories: [fixture]
      ---
      A post dated after the wall clock.
    MARKDOWN
    files = FILES.merge("_posts/#{future_post_date}-future-post.md" => future_post)
    FixtureSite.build(files: files, config: config)
  end

  def test_visible_draft_gets_json_ld
    assert_equal 'BlogPosting', json_ld('blog/visible-draft/index.html')['@type']
  end

  def test_related_posts_use_jekyll_publication_cutoff
    links = parse_page('blog/sample/index.html').css('aside.related a').map { |link| link['href'] }

    assert_includes links, 'https://example.com/preview/blog/future-post/'
  end

  def test_date_only_last_modified_at_sets_json_ld_date
    assert_equal '2024-06-10T00:00:00+00:00', json_ld('blog/sample/index.html')['dateModified']
  end

  def test_awards_favorites_link_includes_baseurl
    links = parse_page('books/by-award/index.html').css('h3 a').map { |link| link['href'] }

    assert_includes links, '/preview/blog/favorites/'
  end

  def test_did_web_publication_writes_well_known_file
    path = File.join(self.class.site_dir, '.well-known/site.standard.publication')

    assert_equal PUBLICATION_URI, File.read(path)
  end

  private

  def parse_page(path)
    Nokogiri::HTML5(File.read(File.join(self.class.site_dir, path)))
  end

  def json_ld(path)
    scripts = parse_page(path).css('script[type="application/ld+json"]')

    assert_equal 1, scripts.size, "Expected one JSON-LD script in #{path}."
    JSON.parse(scripts.first.text)
  end
end
