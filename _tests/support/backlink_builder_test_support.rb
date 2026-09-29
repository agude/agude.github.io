# frozen_string_literal: true

require_relative '../test_helper'

# Tests for Jekyll::Infrastructure::LinkCache::BacklinkBuilder
#
# Verifies that backlinks are correctly built by scanning book content
# for book_link, series_link, and short_story_link tags.
class BacklinkBuilderTestCase < Minitest::Test
  def setup
    @book_a = create_doc(
      { 'title' => 'Book A', 'published' => true },
      '/books/book-a.html',
      "Review of Book A with {% book_link 'Book B' %} reference.",
    )
    @book_b = create_doc(
      { 'title' => 'Book B', 'published' => true },
      '/books/book-b.html',
      'Book B content with no links.',
    )
    @book_c = create_doc(
      { 'title' => 'Book C', 'published' => true },
      '/books/book-c.html',
      "Book C references {% book_link \"Book A\" %} and {% book_link 'Book B' %}.",
    )
  end

  private

  def rebuild_backlinks(site)
    link_cache = site.data['link_cache']
    maps = Jekyll::Infrastructure::LinkCache::CacheMaps.new(link_cache)
    Jekyll::Infrastructure::LinkCache::BacklinkBuilder.new(site, link_cache, maps).build
  end

  def create_site_with_short_stories(books, short_stories_cache, pages = [])
    site = create_site({}, { 'books' => books }, pages)
    site.data['link_cache']['short_stories'] = short_stories_cache
    rebuild_backlinks(site)
    site
  end
end
