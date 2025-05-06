# _tests/plugins/utils/test_backlink_utils.rb
require_relative '../../test_helper'
require_relative '../../../_plugins/utils/backlink_utils' # Load the util

class TestBacklinkUtils < Minitest::Test

  def setup
    # --- Target Page ---
    @target_page_data = { 'title' => 'Target Page', 'url' => '/target.html', 'path' => 'target.html' }
    @target_page = MockDocument.new(@target_page_data, @target_page_data['url'])

    # --- Mock Books ---
    @book_html_link = create_doc(
      { 'title' => 'HTML Linker' },
      '/books/html.html',
      "Some text <a href=\"#{@target_page.url}\">link</a> more text."
    )
    @book_liquid_dq_link = create_doc(
      { 'title' => 'Liquid DQ Linker' },
      '/books/liquid-dq.html',
      "Check out {% book_link \"#{@target_page_data['title']}\" %} it's great."
    )
    @book_liquid_sq_link = create_doc(
      { 'title' => 'Liquid SQ Linker' },
      '/books/liquid-sq.html',
      "Another review: {% book_link '#{@target_page_data['title'].downcase}' %}" # Test case insensitivity
    )
    @book_liquid_base_link = create_doc(
      { 'title' => 'Liquid Base Linker' },
      '/books/liquid-base.html',
      "Just the tag: book_link '#{@target_page_data['title']}'" # Test base tag match
    )
    @book_multi_link = create_doc(
      { 'title' => 'Multi Linker' },
      '/books/multi.html',
      "Link 1: <a href=\"#{@target_page.url}\">html</a>. Link 2: {% book_link \"#{@target_page_data['title']}\" %}"
    )
    @book_no_link = create_doc(
      { 'title' => 'No Linker' },
      '/books/no-link.html',
      "This book does not mention the target page."
    )
    @book_unpublished = create_doc(
      { 'title' => 'Unpublished Linker', 'published' => false },
      '/books/unpublished.html',
      "<a href=\"#{@target_page.url}\">unpublished</a>"
    )
    @book_no_title = create_doc(
      { 'title' => nil }, # No title
      '/books/no-title.html',
      "<a href=\"#{@target_page.url}\">no title</a>"
    )
    @book_no_content = create_doc(
      { 'title' => 'No Content Book' },
      '/books/no-content.html',
      nil # Content is nil
    )
    @book_no_url = create_doc(
      { 'title' => 'No URL Book' },
      nil, # URL is nil
      "<a href=\"#{@target_page.url}\">no url</a>"
    )
    # Books for sorting test
    @book_apple = create_doc({ 'title' => 'The Apple Book' }, '/books/apple.html', "<a href=\"#{@target_page.url}\">apple</a>")
    @book_banana = create_doc({ 'title' => 'Banana Book' }, '/books/banana.html', "<a href=\"#{@target_page.url}\">banana</a>")
    @book_orange = create_doc({ 'title' => 'An Orange Story' }, '/books/orange.html', "<a href=\"#{@target_page.url}\">orange</a>")
    @book_pear = create_doc({ 'title' => 'A Pear Chronicle' }, '/books/pear.html', "<a href=\"#{@target_page.url}\">pear</a>")

    # --- Site & Context ---
    @all_mock_books = [
      @book_html_link, @book_liquid_dq_link, @book_liquid_sq_link,
      @book_liquid_base_link, @book_multi_link, @book_no_link,
      @book_unpublished, @book_no_title, @book_no_content, @book_no_url,
      @book_apple, @book_banana, @book_orange, @book_pear
    ]
    @site = create_site({}, { 'books' => @all_mock_books })
    @context = create_context({}, { site: @site, page: @target_page })
  end

  # Helper to call the utility
  def find_backlinks(page = @target_page, site = @site, context = @context)
    BacklinkUtils.find_book_backlinks(page, site, context)
  end

  # --- Helper to check if a title exists in the results (array of pairs) ---
  def assert_result_includes_title(result, title)
    assert result.any? { |pair| pair[0] == title }, "Expected result to include title '#{title}'"
  end

  def refute_result_includes_title(result, title)
    refute result.any? { |pair| pair[0] == title }, "Expected result NOT to include title '#{title}'"
  end

  # --- Test Cases ---

  def test_finds_link_via_html_href
    result = find_backlinks
    assert_result_includes_title(result, @book_html_link.data['title'])
  end

  def test_finds_link_via_liquid_double_quotes
    result = find_backlinks
    assert_result_includes_title(result, @book_liquid_dq_link.data['title'])
  end

  def test_finds_link_via_liquid_single_quotes_case_insensitive
    result = find_backlinks
    assert_result_includes_title(result, @book_liquid_sq_link.data['title'])
  end

  def test_finds_link_via_liquid_base_tag_match
    result = find_backlinks
    assert_result_includes_title(result, @book_liquid_base_link.data['title'])
  end

  def test_does_not_find_link_when_none_exists
    result = find_backlinks
    refute_result_includes_title(result, @book_no_link.data['title'])
  end

  def test_ignores_unpublished_books
    result = find_backlinks
    refute_result_includes_title(result, @book_unpublished.data['title'])
  end

  def test_ignores_books_without_title
    # This is implicitly tested as @book_no_title has no title to include
    result = find_backlinks
    # Check that no pair has a nil or empty title
    assert result.none? { |pair| pair[0].nil? }, "Result should not contain nil titles"
    assert result.none? { |pair| pair[0].strip.empty? }, "Result should not contain empty titles"
  end

  def test_ignores_books_without_content
    result = find_backlinks
    refute_result_includes_title(result, @book_no_content.data['title'])
  end

  def test_ignores_books_without_url
    result = find_backlinks
    refute_result_includes_title(result, @book_no_url.data['title'])
  end

  def test_ignores_self_reference
    # Add the target page itself to the books collection for this test
    books_with_self = @all_mock_books + [@target_page]
    site_with_self = create_site({}, { 'books' => books_with_self })
    context_with_self = create_context({}, { site: site_with_self, page: @target_page })

    result = find_backlinks(@target_page, site_with_self, context_with_self)
    refute_result_includes_title(result, @target_page.data['title'])
  end

  def test_deduplicates_titles_from_multiple_link_types
    result = find_backlinks
    # Count occurrences of pairs where the title matches the multi-linker title
    count = result.count { |pair| pair[0] == @book_multi_link.data['title'] }
    assert_equal 1, count, "Title '#{@book_multi_link.data['title']}' should appear only once"
  end

  def test_returns_sorted_titles_ignoring_articles
    # Filter site to only include the sorting books
    sorting_books = [@book_apple, @book_banana, @book_orange, @book_pear]
    sorting_site = create_site({}, { 'books' => sorting_books })
    sorting_context = create_context({}, { site: sorting_site, page: @target_page })

    result = find_backlinks(@target_page, sorting_site, sorting_context)

    # Expected order of pairs [title, url]
    expected_order = [
      [@book_apple.data['title'], @book_apple.url],     # The Apple Book
      [@book_banana.data['title'], @book_banana.url],   # Banana Book
      [@book_orange.data['title'], @book_orange.url],   # An Orange Story
      [@book_pear.data['title'], @book_pear.url]        # A Pear Chronicle
    ]
    assert_equal expected_order, result
  end

  def test_returns_empty_array_when_no_links_found
    # Filter site to only include non-linking books
    non_linking_books = [@book_no_link, @book_unpublished, @book_no_title, @book_no_content, @book_no_url]
    non_linking_site = create_site({}, { 'books' => non_linking_books })
    non_linking_context = create_context({}, { site: non_linking_site, page: @target_page })

    result = find_backlinks(@target_page, non_linking_site, non_linking_context)
    assert_equal [], result
  end

  # --- Test Edge Cases for Utility Input ---

  def test_returns_empty_array_if_current_page_is_nil
    result = find_backlinks(nil, @site, @context)
    assert_equal [], result
  end

  def test_returns_empty_array_if_current_page_missing_url
    @target_page.url = nil # Modify the mock page
    @context.registers[:page] = @target_page # Update context
    result = find_backlinks(@target_page, @site, @context)
    assert_equal [], result
  end

  def test_returns_empty_array_if_current_page_missing_title
    @target_page.data['title'] = nil # Modify the mock page data
    @context.registers[:page] = @target_page # Update context
    result = find_backlinks(@target_page, @site, @context)
    assert_equal [], result
  end

  def test_returns_empty_array_if_site_is_nil
    result = find_backlinks(@target_page, nil, @context)
    assert_equal [], result
  end

  def test_returns_empty_array_if_books_collection_missing
    site_no_books = create_site({}, {}) # No collections defined
    context_no_books = create_context({}, { site: site_no_books, page: @target_page })
    result = find_backlinks(@target_page, site_no_books, context_no_books)
    assert_equal [], result
  end

  def test_handles_html_escaping_in_target_url
    # Create a target page with a URL that needs escaping for the href attribute
    target_page_tricky_url_data = { 'title' => 'Tricky URL Page', 'url' => '/target&stuff.html', 'path' => 'target&stuff.html' }
    target_page_tricky_url = MockDocument.new(target_page_tricky_url_data, target_page_tricky_url_data['url'])

    # Create a book linking to it using the *unescaped* URL in the href
    # (The util should escape the URL from page data when creating the html_pattern)
    book_linking_tricky = create_doc(
      { 'title' => 'Tricky Linker' },
      '/books/tricky.html',
      "Link: <a href=\"/target&amp;stuff.html\">tricky</a>" # Content has escaped URL
    )

    site_tricky = create_site({}, { 'books' => [book_linking_tricky] })
    context_tricky = create_context({}, { site: site_tricky, page: target_page_tricky_url })

    result = find_backlinks(target_page_tricky_url, site_tricky, context_tricky)
    assert_result_includes_title(result, 'Tricky Linker')
  end

end
