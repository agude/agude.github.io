# frozen_string_literal: true

require 'test_helper'
require 'src/infrastructure/html_scan'

# Tests for HtmlScan: the Regexp pieces of the post-render tokenizers.
class TestHtmlScan < Minitest::Test
  Scan = Jekyll::Infrastructure::HtmlScan

  # A tokenizer written as the @pattern in HtmlScan shows.
  TOKEN = /
    #{Scan::SKIPPED}
    | (?<img>#{Scan.start_tag('img')})
    | #{Scan::OTHER_START_TAG}
  /xi

  def images(html, token = TOKEN)
    html.to_enum(:scan, token).filter_map { Regexp.last_match[:img] }
  end

  def test_finds_start_tags_with_quoted_greater_than_in_any_case
    assert_equal ['<img alt="a > b" src="/x.png">', "<IMG src='/y.png'/>"],
                 images(%(<p><img alt="a > b" src="/x.png"> <IMG src='/y.png'/></p>))
  end

  # SKIPPED keeps its own `m` flag, so a multi-line comment or script is
  # skipped although TOKEN is not `m`.
  def test_skips_comments_and_raw_text_elements_across_lines
    html = %(<!--\n<img src="/a.png">\n--><SCRIPT>\n"<img src='/b.png'>"</script>) +
           %(<style>/* <img> */</style><textarea><img src="/c.png"></textarea><img src="/d.png">)
    assert_equal ['<img src="/d.png">'], images(html)
  end

  # A custom element named like a raw-text element is not one: its
  # contents, up to some later </script>, are still scanned.
  def test_custom_element_named_like_a_raw_text_element_is_not_skipped
    html = '<script-loader></script-loader><img src="/a.png"><script>"<img>"</script>'
    assert_equal ['<img src="/a.png">'], images(html)
  end

  def test_markup_inside_another_tags_attribute_is_not_a_tag
    assert_equal [], images(%(<div data-example='<img src="/a.png">'></div>))
  end

  def test_tag_name_must_end_the_name
    assert_equal [], images('<imgx src="/a.png">')
    assert_equal [], images('<img-icon src="/a.png">')
    assert_equal ['<img>', '<img/>', "<img\nsrc=\"/a.png\">"], images("<img><img/><img\nsrc=\"/a.png\">")
  end

  # Alternatives are tried in order at each position: a caller group that
  # starts with a tag must come before OTHER_START_TAG, or that tag is
  # consumed as an ordinary start tag and the group never matches.
  def test_caller_group_before_other_start_tag_wins
    before = /#{Scan::SKIPPED} | (?<img><a\b[^>]*><img\b[^>]*>) | #{Scan::OTHER_START_TAG}/xi
    after = /#{Scan::SKIPPED} | #{Scan::OTHER_START_TAG} | (?<img><a\b[^>]*><img\b[^>]*>)/xi
    html = '<a href="/x/"><img src="/x.png"></a>'

    assert_equal ['<a href="/x/"><img src="/x.png">'], images(html, before)
    assert_equal [], images(html, after)
  end
end
