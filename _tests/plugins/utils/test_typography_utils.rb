# _tests/plugins/utils/test_typography_utils.rb
require_relative '../../test_helper'
# TypographyUtils will be loaded by test_helper.rb after we add the require there.

# Renamed class
class TestTypographyUtils < Minitest::Test
  def test_prepare_display_title_empty_and_nil
    assert_equal '', TypographyUtils.prepare_display_title(nil)
    assert_equal '', TypographyUtils.prepare_display_title('')
  end

  def test_prepare_display_title_basic_text
    assert_equal 'Simple Title', TypographyUtils.prepare_display_title('Simple Title')
  end

  def test_prepare_display_title_html_escaping
    assert_equal 'Ampersand &amp; Test', TypographyUtils.prepare_display_title('Ampersand & Test')
    assert_equal 'Less Than &lt; Test', TypographyUtils.prepare_display_title('Less Than < Test')
    assert_equal 'Greater Than &gt; Test', TypographyUtils.prepare_display_title('Greater Than > Test')
    assert_equal 'All &amp; &lt;Three&gt;', TypographyUtils.prepare_display_title('All & <Three>')
    # Ensure quotes are NOT escaped by this step, they are transformed later
    assert_equal 'Quotes ‘ “ remain', TypographyUtils.prepare_display_title("Quotes ' \" remain")
  end

  def test_prepare_display_title_br_tags
    assert_equal 'Line 1<br>Line 2', TypographyUtils.prepare_display_title('Line 1<br>Line 2')
    assert_equal 'Line 1<br>Line 2', TypographyUtils.prepare_display_title('Line 1<br />Line 2')
    assert_equal 'Line 1<br>Line 2', TypographyUtils.prepare_display_title('Line 1<br/>Line 2')
    assert_equal 'Line 1 <br> Line 2', TypographyUtils.prepare_display_title('Line 1 <br> Line 2')
    assert_equal '<br> at start', TypographyUtils.prepare_display_title('<br> at start')
    assert_equal 'Allow <br> tag', TypographyUtils.prepare_display_title('Allow <br> tag')
    # Test with spaces around self-closing br
    assert_equal 'Line 1 <br> Line 2', TypographyUtils.prepare_display_title('Line 1 <br /> Line 2')
  end

  def test_prepare_display_title_dashes
    assert_equal 'En–dash', TypographyUtils.prepare_display_title('En--dash')
    assert_equal 'Em—dash', TypographyUtils.prepare_display_title('Em---dash')
    assert_equal 'Okay – not — this', TypographyUtils.prepare_display_title('Okay -- not --- this')
  end

  def test_prepare_display_title_ellipsis
    assert_equal 'Wait for it…', TypographyUtils.prepare_display_title('Wait for it...')
  end

  def test_prepare_display_title_double_quotes
    assert_equal '“Hello”', TypographyUtils.prepare_display_title('"Hello"')
    assert_equal 'He said “Hi.”', TypographyUtils.prepare_display_title('He said "Hi."')
    assert_equal '“Hi,” he said.', TypographyUtils.prepare_display_title('"Hi," he said.')
    assert_equal 'A quote: “word”', TypographyUtils.prepare_display_title('A quote: "word"')
    assert_equal '(“word”)', TypographyUtils.prepare_display_title('("word")')
    assert_equal '[“word”]', TypographyUtils.prepare_display_title('["word"]')
  end

  def test_prepare_display_title_single_quotes_and_apostrophes
    # Apostrophes
    assert_equal 'It’s an apostrophe', TypographyUtils.prepare_display_title("It's an apostrophe")
    assert_equal 'Don’t stop', TypographyUtils.prepare_display_title("Don't stop")
    assert_equal '’90s', TypographyUtils.prepare_display_title("'90s")
    assert_equal 'The ’90s', TypographyUtils.prepare_display_title("The '90s")
    assert_equal 'The users’ rights', TypographyUtils.prepare_display_title("The users' rights")
    assert_equal 'The user’s right.', TypographyUtils.prepare_display_title("The user's right.")
    # Single Quotes
    assert_equal '‘Hello’', TypographyUtils.prepare_display_title("'Hello'")
    assert_equal 'He said ‘Hi.’', TypographyUtils.prepare_display_title("He said 'Hi.'")
    assert_equal '‘Hi,’ he said.', TypographyUtils.prepare_display_title("'Hi,' he said.")
    assert_equal 'A quote: ‘word’', TypographyUtils.prepare_display_title("A quote: 'word'")
    assert_equal '(‘word’)', TypographyUtils.prepare_display_title("('word')")
    assert_equal '[‘word’]', TypographyUtils.prepare_display_title("['word']")
    assert_equal '‘Tis the season', TypographyUtils.prepare_display_title("'Tis the season")
  end

  def test_prepare_display_title_mixed_quotes
    assert_equal '“Don’t say ‘hello’ like that,” she said.',
                 TypographyUtils.prepare_display_title("\"Don't say 'hello' like that,\" she said.")
    assert_equal 'He replied, ‘I heard him say “Stop!” just now.’',
                 TypographyUtils.prepare_display_title("He replied, 'I heard him say \"Stop!\" just now.'")
  end

  def test_prepare_display_title_combinations_with_escaping
    assert_equal 'It’s &lt;OK&gt; – “Sure…”', TypographyUtils.prepare_display_title("It's <OK> -- \"Sure...\"")
    assert_equal 'Safe &amp; &lt;Tags&gt; – Not ‘Bad’',
                 TypographyUtils.prepare_display_title("Safe & <Tags> -- Not 'Bad'")
  end

  def test_prepare_display_title_combinations_with_br
    assert_equal 'Line 1<br>It’s – “Okay”', TypographyUtils.prepare_display_title("Line 1<br>It's -- \"Okay\"")
    assert_equal 'Line 1<br>It’s – “Okay”', TypographyUtils.prepare_display_title("Line 1<br />It's -- \"Okay\"")
    assert_equal '&lt;Start&gt; First – then<br>Second',
                 TypographyUtils.prepare_display_title('<Start> First -- then<br>Second')
  end
end
