#a_plugins/tests/test_liquid_utils.rb
require_relative 'test_helper'

class TestLiquidUtils < Minitest::Test

  def test_debug_hello_quote
    input = "'hello'"
    expected = "‘hello’"
    actual = LiquidUtils._prepare_display_title(input)
    assert_equal expected, actual
  end

  # --- normalize_title ---
  def test_normalize_title_basic
    assert_equal "hello world", LiquidUtils.normalize_title("  Hello \n World  ")
  end

  def test_normalize_title_with_articles
    assert_equal "test title", LiquidUtils.normalize_title("The Test Title", strip_articles: true)
    assert_equal "example", LiquidUtils.normalize_title("an Example", strip_articles: true)
  end

  def test_normalize_title_nil
    assert_equal "", LiquidUtils.normalize_title(nil)
  end

  # --- _prepare_display_title ---
  def test_prepare_display_title_empty_and_nil
    assert_equal "", LiquidUtils._prepare_display_title(nil)
    assert_equal "", LiquidUtils._prepare_display_title("")
  end

  def test_prepare_display_title_basic_text
    assert_equal "Simple Title", LiquidUtils._prepare_display_title("Simple Title")
  end

  def test_prepare_display_title_html_escaping
    assert_equal "Ampersand &amp; Test", LiquidUtils._prepare_display_title("Ampersand & Test")
    assert_equal "Less Than &lt; Test", LiquidUtils._prepare_display_title("Less Than < Test")
    assert_equal "Greater Than &gt; Test", LiquidUtils._prepare_display_title("Greater Than > Test")
    assert_equal "All &amp; &lt;Three&gt;", LiquidUtils._prepare_display_title("All & <Three>")
    # Ensure quotes are NOT escaped by this step
    assert_equal "Quotes ‘ “ remain", LiquidUtils._prepare_display_title("Quotes ' \" remain")
  end

  def test_prepare_display_title_br_tags
    assert_equal "Line 1<br>Line 2", LiquidUtils._prepare_display_title("Line 1<br>Line 2")
    assert_equal "Line 1<br>Line 2", LiquidUtils._prepare_display_title("Line 1<br />Line 2")
    assert_equal "Line 1<br>Line 2", LiquidUtils._prepare_display_title("Line 1<br/>Line 2")
    assert_equal "Line 1 <br> Line 2", LiquidUtils._prepare_display_title("Line 1 <br> Line 2") # Space around
    assert_equal "<br> at start", LiquidUtils._prepare_display_title("<br> at start")
    assert_equal "Allow <br> tag", LiquidUtils._prepare_display_title("Allow <br> tag")
  end

  def test_prepare_display_title_dashes
    assert_equal "En–dash", LiquidUtils._prepare_display_title("En--dash")
    assert_equal "Em—dash", LiquidUtils._prepare_display_title("Em---dash")
    assert_equal "Okay – not — this", LiquidUtils._prepare_display_title("Okay -- not --- this")
  end

  def test_prepare_display_title_ellipsis
    assert_equal "Wait for it…", LiquidUtils._prepare_display_title("Wait for it...")
  end

  def test_prepare_display_title_double_quotes
    assert_equal "“Hello”", LiquidUtils._prepare_display_title("\"Hello\"")
    assert_equal "He said “Hi.”", LiquidUtils._prepare_display_title("He said \"Hi.\"")
    assert_equal "“Hi,” he said.", LiquidUtils._prepare_display_title("\"Hi,\" he said.")
    assert_equal "A quote: “word”", LiquidUtils._prepare_display_title("A quote: \"word\"")
    assert_equal "(“word”)", LiquidUtils._prepare_display_title("(\"word\")")
    assert_equal "[“word”]", LiquidUtils._prepare_display_title("[\"word\"]")
  end

  def test_prepare_display_title_single_quotes_and_apostrophes
    # Apostrophes
    assert_equal "It’s an apostrophe", LiquidUtils._prepare_display_title("It's an apostrophe")
    assert_equal "Don’t stop", LiquidUtils._prepare_display_title("Don't stop")
    assert_equal "’90s", LiquidUtils._prepare_display_title("'90s")
    assert_equal "The ’90s", LiquidUtils._prepare_display_title("The '90s")
    assert_equal "The users’ rights", LiquidUtils._prepare_display_title("The users' rights")
    assert_equal "The user’s right.", LiquidUtils._prepare_display_title("The user's right.")
    # Single Quotes
    assert_equal "‘Hello’", LiquidUtils._prepare_display_title("'Hello'")
    assert_equal "He said ‘Hi.’", LiquidUtils._prepare_display_title("He said 'Hi.'")
    assert_equal "‘Hi,’ he said.", LiquidUtils._prepare_display_title("'Hi,' he said.")
    assert_equal "A quote: ‘word’", LiquidUtils._prepare_display_title("A quote: 'word'")
    assert_equal "(‘word’)", LiquidUtils._prepare_display_title("('word')")
    assert_equal "[‘word’]", LiquidUtils._prepare_display_title("['word']")
    # Edge case: Apostrophe at start (treated as opening quote)
    assert_equal "‘Tis the season", LiquidUtils._prepare_display_title("'Tis the season")
  end

  def test_prepare_display_title_mixed_quotes
    assert_equal "“Don’t say ‘hello’ like that,” she said.", LiquidUtils._prepare_display_title("\"Don't say 'hello' like that,\" she said.")
    assert_equal "He replied, ‘I heard him say “Stop!” just now.’", LiquidUtils._prepare_display_title("He replied, 'I heard him say \"Stop!\" just now.'")
  end

  def test_prepare_display_title_combinations_with_escaping
    # Test typography applied AFTER escaping of non-br tags
    assert_equal "It’s &lt;OK&gt; – “Sure…”", LiquidUtils._prepare_display_title("It's <OK> -- \"Sure...\"")
    assert_equal "Safe &amp; &lt;Tags&gt; – Not ‘Bad’", LiquidUtils._prepare_display_title("Safe & <Tags> -- Not 'Bad'")
  end

  def test_prepare_display_title_combinations_with_br
    # Test typography applied, escaping done, but <br> restored
    assert_equal "Line 1<br>It’s – “Okay”", LiquidUtils._prepare_display_title("Line 1<br>It's -- \"Okay\"")
    assert_equal "Line 1<br>It’s – “Okay”", LiquidUtils._prepare_display_title("Line 1<br />It's -- \"Okay\"") # Test self-closing input
    assert_equal "&lt;Start&gt; First – then<br>Second", LiquidUtils._prepare_display_title("<Start> First -- then<br>Second")
  end

  # --- resolve_value ---
  def test_resolve_value_quoted_string
    ctx = create_context
    assert_equal "hello", LiquidUtils.resolve_value('"hello"', ctx)
    assert_equal "world", LiquidUtils.resolve_value("'world'", ctx)
  end

  def test_resolve_value_variable_found
    ctx = create_context({ 'page' => { 'my_var' => 'found it' } })
    assert_equal "found it", LiquidUtils.resolve_value('page.my_var', ctx)
  end

  def test_resolve_value_variable_not_found_returns_markup
    ctx = create_context
    assert_equal "missing_var", LiquidUtils.resolve_value('missing_var', ctx)
  end

  def test_resolve_value_nil_or_empty
    ctx = create_context
    assert_nil LiquidUtils.resolve_value(nil, ctx)
    assert_nil LiquidUtils.resolve_value('', ctx)
    assert_nil LiquidUtils.resolve_value('  ', ctx)
  end

  # --- render_rating_stars ---
  def test_render_rating_stars_valid
    assert_match(/class=".*star-rating-5.*★.*★.*★.*★.*★/, LiquidUtils.render_rating_stars(5))
    assert_match(/class=".*star-rating-3.*★.*★.*★.*☆.*☆/, LiquidUtils.render_rating_stars(3))
    assert_match(/class=".*star-rating-1.*★.*☆.*☆.*☆.*☆/, LiquidUtils.render_rating_stars(1))
  end

  def test_render_rating_stars_invalid
    assert_equal "", LiquidUtils.render_rating_stars(0)
    assert_equal "", LiquidUtils.render_rating_stars(6)
    assert_equal "", LiquidUtils.render_rating_stars("invalid")
    assert_equal "", LiquidUtils.render_rating_stars(nil)
  end

  def test_render_rating_stars_wrapper_tag
    assert_match(/^<span class=.*<\/span>$/, LiquidUtils.render_rating_stars(4, 'span'))
    assert_match(/^<div class=.*<\/div>$/, LiquidUtils.render_rating_stars(4, 'div'))
    # Ensure invalid tags default to div
    assert_match(/^<div class=.*<\/div>$/, LiquidUtils.render_rating_stars(4, 'script'))
  end

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

  # --- render_author_link ---
  def test_render_author_link_found_and_linked
    author_page = create_doc({ 'title' => 'Jane Doe', 'layout' => 'author_page' }, '/authors/jane-doe.html')
    site = create_site({}, {}, [author_page]) # Add to pages
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    expected = "<a href=\"/authors/jane-doe.html\"><span class=\"author-name\">Jane Doe</span></a>"
    assert_equal expected, LiquidUtils.render_author_link("Jane Doe", ctx)
  end

  def test_render_author_link_possessive_linked
    author_page = create_doc({ 'title' => 'Jane Doe', 'layout' => 'author_page' }, '/authors/jane-doe.html')
    site = create_site({}, {}, [author_page])
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    expected = "<a href=\"/authors/jane-doe.html\"><span class=\"author-name\">Jane Doe</span>’s</a>" # Possessive inside link
    assert_equal expected, LiquidUtils.render_author_link("Jane Doe", ctx, nil, true)
  end

  def test_render_author_link_possessive_unlinked
    site = create_site({}, {}, []) # No author pages
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    expected = "<span class=\"author-name\">Jane Doe</span>’s" # Possessive outside span
    assert_equal expected, LiquidUtils.render_author_link("Jane Doe", ctx, nil, true)
  end

  # Add tests for render_article_card, render_book_card, log_failure...

end
