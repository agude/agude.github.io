# frozen_string_literal: true

# _tests/plugins/utils/test_backlink_utils.rb
require_relative '../../test_helper'
require_relative '../../../_plugins/utils/backlink_utils' # Load the util

# Tests for BacklinkUtils module.
#
# Verifies that the utility correctly finds and sorts book backlinks from the link cache.
class TestBacklinkUtils < Minitest::Test
  def setup
    # --- Mock Documents that will be the backlinks ---
    @book_apple = create_doc({ 'title' => 'The Apple Book' }, '/books/apple.html')
    @book_banana = create_doc({ 'title' => 'Banana Book' }, '/books/banana.html')
    @book_orange = create_doc({ 'title' => 'An Orange Story' }, '/books/orange.html')

    # --- Target Page ---
    @target_page = create_doc({ 'title' => 'Target Page' }, '/target.html')
    @page_with_no_backlinks = create_doc({ 'title' => 'Unlinked Page' }, '/unlinked.html')

    # --- Site & Context ---
    # The create_site helper runs the LinkCacheGenerator, but we will manually
    # set the backlinks cache to isolate this test to the BacklinkUtils logic.
    @site = create_site
    @site.data['link_cache']['backlinks'] = {
      @target_page.url => [@book_banana, @book_apple, @book_orange] # Intentionally unsorted
    }
    @context = create_context({}, { site: @site, page: @target_page })
  end

  # Helper to call the utility
  def find_backlinks(page = @target_page, site = @site, context = @context)
    BacklinkUtils.find_book_backlinks(page, site, context)
  end

  def test_finds_and_sorts_backlinks_from_cache
    result = find_backlinks

    # Expected order of pairs [title, url], sorted by title ignoring articles
    expected_order = [
      [@book_apple.data['title'], @book_apple.url],     # The Apple Book
      [@book_banana.data['title'], @book_banana.url],   # Banana Book
      [@book_orange.data['title'], @book_orange.url]    # An Orange Story
    ]
    assert_equal expected_order, result
  end

  def test_returns_empty_array_for_page_with_no_backlinks_in_cache
    # Use the page that has no entry in our manually created cache
    result = find_backlinks(@page_with_no_backlinks, @site,
                            create_context({}, { site: @site, page: @page_with_no_backlinks }))
    assert_equal [], result
  end

  def test_handles_backlinking_doc_with_no_title
    book_no_title = create_doc({ 'title' => nil }, '/books/no-title.html')
    @site.data['link_cache']['backlinks'][@target_page.url] << book_no_title

    result = find_backlinks
    # The util should just skip the doc with no title during the mapping phase
    assert(result.none? { |pair| pair[1] == '/books/no-title.html' })
    assert_equal 3, result.size, 'Should still have the original 3 valid backlinks'
  end

  # --- Test Edge Cases for Utility Input ---

  def test_returns_empty_array_if_current_page_is_nil
    result = find_backlinks(nil, @site, @context)
    assert_equal [], result
  end

  def test_returns_empty_array_if_current_page_missing_url
    @target_page.url = nil
    @context.registers[:page] = @target_page
    result = find_backlinks(@target_page, @site, @context)
    assert_equal [], result
  end

  def test_returns_empty_array_if_site_is_nil
    result = find_backlinks(@target_page, nil, @context)
    assert_equal [], result
  end

  def test_returns_empty_array_if_link_cache_is_missing
    @site.data['link_cache'] = nil
    result = find_backlinks(@target_page, @site, @context)
    assert_equal [], result
  end

  def test_returns_empty_array_if_backlinks_key_is_missing_from_cache
    @site.data['link_cache'].delete('backlinks')
    result = find_backlinks(@target_page, @site, @context)
    assert_equal [], result
  end
end
