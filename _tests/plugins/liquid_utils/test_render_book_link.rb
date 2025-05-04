require_relative '../../test_helper'

class TestLiquidUtils < Minitest::Test

  # --- render_book_link ---
  def test_render_book_link_found_and_linked
    book1 = create_doc({ 'title' => "Found Book", 'published' => true }, '/books/found.html')
    site = create_site({}, { 'books' => [book1] })
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    expected = "<a href=\"/books/found.html\"><cite class=\"book-title\">Found Book</cite></a>"
    assert_equal expected, LiquidUtils.render_book_link("Found Book", ctx)
  end

   def test_render_book_link_found_but_current_page
     book1 = create_doc({ 'title' => "Found Book", 'published' => true }, '/books/found.html')
     site = create_site({}, { 'books' => [book1] })
     page = create_doc({}, '/books/found.html') # Current page IS the book page
     ctx = create_context({}, { site: site, page: page })

     expected = "<cite class=\"book-title\">Found Book</cite>" # Should not be linked
     assert_equal expected, LiquidUtils.render_book_link("Found Book", ctx)
   end

  def test_render_book_link_not_found
    site = create_site({}, { 'books' => [] }) # Empty collection
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    expected = "<cite class=\"book-title\">Missing Book</cite>"
    assert_equal expected, LiquidUtils.render_book_link("Missing Book", ctx)
  end

  def test_render_book_link_with_link_text
    book1 = create_doc({ 'title' => "Real Title", 'published' => true }, '/books/real.html')
    site = create_site({}, { 'books' => [book1] })
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    expected = "<a href=\"/books/real.html\"><cite class=\"book-title\">Display Text</cite></a>"
    assert_equal expected, LiquidUtils.render_book_link("Real Title", ctx, "Display Text")
  end

   def test_render_book_link_uses_smart_quotes
     book1 = create_doc({ 'title' => "It's a Test", 'published' => true }, '/books/test.html')
     site = create_site({}, { 'books' => [book1] })
     page = create_doc({}, '/current.html')
     ctx = create_context({}, { site: site, page: page })

     expected = "<a href=\"/books/test.html\"><cite class=\"book-title\">It’s a Test</cite></a>"
     assert_equal expected, LiquidUtils.render_book_link("It's a Test", ctx)
   end
end
