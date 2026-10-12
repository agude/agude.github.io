# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/seo/generators/author_profile_generator' # Load the specific generator
require 'minitest/mock' # For mocking logger

# Tests for Jekyll::SEO::Generators::AuthorProfileLdGenerator module.
#
# An author page lists the site owner's reviews of one author's books. The
# author wrote the books, not the site, so the page is not their profile:
# Google's ProfilePage requires a person "affiliated with the overall
# website". The page is a CollectionPage whose `about` is the author's
# Person node. Page-level text (name, description) stays on the page node;
# the Person carries only identity (@id, url, name, sameAs, pen names).
class TestAuthorProfileLdGenerator < Minitest::Test
  PAGE_URL = 'https://mysite.dev/authors/jane-doe.html'

  def setup
    @site = create_site(
      {
        'url' => 'https://mysite.dev',
        'baseurl' => '',
        'title' => 'My Site',
        'author' => { 'name' => 'Site Owner', 'url' => '/resume/' },
      },
    )
  end

  # --- Page node ---

  def test_generate_hash_is_collection_page_for_the_author_page
    result = generate(create_author_doc)

    assert_equal 'https://schema.org', result['@context']
    assert_equal 'CollectionPage', result['@type']
    assert_equal PAGE_URL, result['@id']
    assert_equal PAGE_URL, result['url']
    assert_equal 'Jane Doe - Book Reviews', result['name']
  end

  def test_generate_hash_page_carries_page_description
    result = generate(create_author_doc('description' => "Alex Gude's reviews of books written by Jane Doe."))

    assert_equal "Alex Gude's reviews of books written by Jane Doe.", result['description']
  end

  def test_generate_hash_page_author_is_site_owner
    result = generate(create_author_doc)

    expected = {
      '@type' => 'Person',
      '@id' => 'https://mysite.dev/resume/#person',
      'url' => 'https://mysite.dev/resume/',
      'name' => 'Site Owner',
    }
    assert_equal expected, result['author']
  end

  def test_generate_hash_page_is_part_of_website
    result = generate(create_author_doc)

    assert_equal 'https://mysite.dev/#website', result.dig('isPartOf', '@id')
  end

  # --- about: the book author ---

  # Book reviews reference the author as <author page>#person; the page's
  # `about` must be that same node.
  def test_generate_hash_about_is_author_person
    result = generate(create_author_doc)

    expected = {
      '@type' => 'Person',
      '@id' => "#{PAGE_URL}#person",
      'url' => PAGE_URL,
      'name' => 'Jane Doe',
    }
    assert_equal expected, result['about']
  end

  # The page description describes the page ("Alex Gude's reviews of books
  # written by Jane Doe."), not the person.
  def test_generate_hash_about_ignores_page_description
    result = generate(create_author_doc('description' => "Alex Gude's reviews of books written by Jane Doe."))

    refute result['about'].key?('description'), 'Page description must not describe the Person'
  end

  def test_generate_hash_about_ignores_page_excerpt
    result = generate(create_author_doc('excerpt_output_override' => '<p>Page intro.</p>'))

    refute result['about'].key?('description'), 'Page excerpt must not describe the Person'
  end

  def test_generate_hash_about_with_same_as_urls
    doc = create_author_doc(
      'same_as_urls' => ['https://twitter.com/janedoe', ' https://linkedin.com/in/janedoe ', nil, ''],
    )
    result = generate(doc)

    assert_equal ['https://twitter.com/janedoe', 'https://linkedin.com/in/janedoe'], result.dig('about', 'sameAs')
  end

  # The author's Wikidata link comes from wikidata_qid, ahead of same_as_urls.
  def test_generate_hash_about_same_as_starts_with_wikidata_url
    doc = create_author_doc('wikidata_qid' => 'Q42', 'same_as_urls' => ['https://twitter.com/janedoe'])
    result = generate(doc)

    assert_equal ['https://www.wikidata.org/wiki/Q42', 'https://twitter.com/janedoe'], result.dig('about', 'sameAs')
  end

  def test_generate_hash_about_with_pen_names
    doc = create_author_doc('pen_names' => ['Pen Name One', '  Pen Name Two  ', nil, ''])
    result = generate(doc)

    assert_equal ['Pen Name One', 'Pen Name Two'], result.dig('about', 'alternateName')
  end

  def test_generate_hash_about_omits_empty_same_as_and_pen_names
    [[], nil].each do |empty|
      result = generate(create_author_doc('same_as_urls' => empty, 'pen_names' => empty))

      refute result['about'].key?('sameAs'), "same_as_urls #{empty.inspect} should omit sameAs"
      refute result['about'].key?('alternateName'), "pen_names #{empty.inspect} should omit alternateName"
    end
  end

  def test_generate_hash_blank_title_keeps_identity_only
    doc = create_doc(
      { 'layout' => 'author_page', 'title' => ' ', 'description' => '', 'same_as_urls' => [], 'pen_names' => [] },
      '/authors/empty.html',
    )
    result = generate(doc)

    refute result.key?('name'), 'Blank title should omit the page name'
    refute result.key?('description'), 'Blank description should be omitted'
    expected_about = {
      '@type' => 'Person',
      '@id' => 'https://mysite.dev/authors/empty.html#person',
      'url' => 'https://mysite.dev/authors/empty.html',
    }
    assert_equal expected_about, result['about']
  end

  # Titles may contain <br> and &nbsp; for on-page display. JSON-LD names
  # are plain text.
  def test_generate_hash_page_and_person_names_are_plain_text
    result = generate(create_author_doc('title' => 'Jane&nbsp;Doe<br>Jr.'))

    assert_equal "Jane\u00A0Doe Jr. - Book Reviews", result['name']
    assert_equal "Jane\u00A0Doe Jr.", result.dig('about', 'name')
  end

  private

  def create_author_doc(overrides = {})
    create_doc({ 'layout' => 'author_page', 'title' => 'Jane Doe' }.merge(overrides), '/authors/jane-doe.html')
  end

  def generate(doc)
    Jekyll::SEO::Generators::AuthorProfileLdGenerator.generate_hash(doc, @site)
  end
end
