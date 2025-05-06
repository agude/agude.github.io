require_relative '../../test_helper'

class TestBookLinkUtils < Minitest::Test

  # --- render_book_link ---
  def test_render_book_link_found_and_linked
    book1 = create_doc({ 'title' => "Found Book", 'published' => true }, '/books/found.html')
    site = create_site({}, { 'books' => [book1] })
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    expected = "<a href=\"/books/found.html\"><cite class=\"book-title\">Found Book</cite></a>"
    assert_equal expected, BookLinkUtils.render_book_link("Found Book", ctx)
  end

   def test_render_book_link_found_but_current_page
     book1 = create_doc({ 'title' => "Found Book", 'published' => true }, '/books/found.html')
     site = create_site({}, { 'books' => [book1] })
     page = create_doc({}, '/books/found.html') # Current page IS the book page
     ctx = create_context({}, { site: site, page: page })

     expected = "<cite class=\"book-title\">Found Book</cite>" # Should not be linked
     assert_equal expected, BookLinkUtils.render_book_link("Found Book", ctx)
   end

  def test_render_book_link_not_found
    site = create_site({}, { 'books' => [] }) # Empty collection
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # Expect unlinked cite. log_failure returns ""
    expected = "<cite class=\"book-title\">Missing Book</cite>"
    assert_equal expected, BookLinkUtils.render_book_link("Missing Book", ctx)
  end

  def test_render_book_link_with_link_text
    book1 = create_doc({ 'title' => "Real Title", 'published' => true }, '/books/real.html')
    site = create_site({}, { 'books' => [book1] })
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    expected = "<a href=\"/books/real.html\"><cite class=\"book-title\">Display Text</cite></a>"
    assert_equal expected, BookLinkUtils.render_book_link("Real Title", ctx, "Display Text")
  end

   def test_render_book_link_uses_smart_quotes
     book1 = create_doc({ 'title' => "It's a Test", 'published' => true }, '/books/test.html')
     site = create_site({}, { 'books' => [book1] })
     page = create_doc({}, '/current.html')
     ctx = create_context({}, { site: site, page: page })

     expected = "<a href=\"/books/test.html\"><cite class=\"book-title\">It’s a Test</cite></a>"
     assert_equal expected, BookLinkUtils.render_book_link("It's a Test", ctx)
   end

  def test_render_book_link_case_insensitive_and_whitespace_normalized_lookup
    # Canonical title has different case and spacing
    book1 = create_doc({ 'title' => "  My BOOK Title ", 'published' => true }, '/books/my-book.html')
    site = create_site({}, { 'books' => [book1] })
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # Input should match via normalize_title
    input_title = "my book title"
    # Output should use canonical title, prepared for display
    expected = "<a href=\"/books/my-book.html\"><cite class=\"book-title\">My BOOK Title</cite></a>"
    assert_equal expected, BookLinkUtils.render_book_link(input_title, ctx)

    # Test another variation
    input_title_2 = "  MY  book   TITLE "
    assert_equal expected, BookLinkUtils.render_book_link(input_title_2, ctx)
  end

  def test_render_book_link_with_baseurl
    book1 = create_doc({ 'title' => "Base Book", 'published' => true }, '/books/base.html')
    site = create_site({ 'baseurl' => '/blog' }, { 'books' => [book1] })
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    expected = "<a href=\"/blog/books/base.html\"><cite class=\"book-title\">Base Book</cite></a>"
    assert_equal expected, BookLinkUtils.render_book_link("Base Book", ctx)
  end

  def test_render_book_link_unpublished_book_not_found
    book1 = create_doc({ 'title' => "Unpublished Book", 'published' => false }, '/books/unpublished.html')
    site = create_site({}, { 'books' => [book1] })
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # Should not find the book, render unlinked cite with input title
    expected = "<cite class=\"book-title\">Unpublished Book</cite>"
    assert_equal expected, BookLinkUtils.render_book_link("Unpublished Book", ctx)
  end

  def test_render_book_link_empty_input_title
    site = create_site({}, { 'books' => [] })
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # log_failure called internally, returns ""
    assert_equal "", BookLinkUtils.render_book_link("", ctx)
    assert_equal "", BookLinkUtils.render_book_link("   ", ctx)
    assert_equal "", BookLinkUtils.render_book_link(nil, ctx)
  end

  def test_render_book_link_books_collection_missing
    site = create_site({}, {}) # No 'books' collection defined
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # Should log failure (returns "") and render unlinked cite with input title
    expected = "<cite class=\"book-title\">Some Book</cite>"
    assert_equal expected, BookLinkUtils.render_book_link("Some Book", ctx)
  end

  def test_render_book_link_found_book_has_no_url
    # Create a book doc with url explicitly set to nil
    book1 = MockDocument.new({ 'title' => "No URL Book", 'published' => true }, nil) # url is nil
    site = create_site({}, { 'books' => [book1] })
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # Should find the book but render unlinked cite because target_url is nil
    expected = "<cite class=\"book-title\">No URL Book</cite>"
    assert_equal expected, BookLinkUtils.render_book_link("No URL Book", ctx)
  end

  def test_render_book_link_complex_typography_and_br_in_title
    book1 = create_doc({ 'title' => "Test--\"Quotes\" & Stuff... <br> Line 2", 'published' => true }, '/books/complex.html')
    site = create_site({}, { 'books' => [book1] })
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # Check _prepare_display_title output within the cite tag
    expected = "<a href=\"/books/complex.html\"><cite class=\"book-title\">Test–“Quotes” &amp; Stuff… <br> Line 2</cite></a>"
    assert_equal expected, BookLinkUtils.render_book_link("Test--\"Quotes\" & Stuff... <br> Line 2", ctx)
  end

  def test_render_book_link_complex_typography_in_link_text
    book1 = create_doc({ 'title' => "Simple Title", 'published' => true }, '/books/simple.html')
    site = create_site({}, { 'books' => [book1] })
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    link_text = "Override--\"Quotes\" & Stuff... <br> Line 2"
    # Check _prepare_display_title output for the override text
    expected = "<a href=\"/books/simple.html\"><cite class=\"book-title\">Override–“Quotes” &amp; Stuff… <br> Line 2</cite></a>"
    assert_equal expected, BookLinkUtils.render_book_link("Simple Title", ctx, link_text)
  end

  def test_render_book_link_uses_canonical_title_not_input_for_display
    book1 = create_doc({ 'title' => "Canonical Title", 'published' => true }, '/books/canonical.html')
    site = create_site({}, { 'books' => [book1] })
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # Input matches via normalization, but display should use canonical
    input_title = "canonical title"
    expected = "<a href=\"/books/canonical.html\"><cite class=\"book-title\">Canonical Title</cite></a>"
    assert_equal expected, BookLinkUtils.render_book_link(input_title, ctx)
  end

end
