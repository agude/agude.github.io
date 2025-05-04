require_relative '../../test_helper'

class TestLiquidUtils < Minitest::Test

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
end
