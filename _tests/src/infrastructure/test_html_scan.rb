# frozen_string_literal: true

require 'test_helper'
require 'src/infrastructure/html_scan'
require 'support/property_test'

# Tests for HtmlScan: the Regexp pieces of the post-render tokenizers.
class TestHtmlScan < Minitest::Test
  include PropertyTestSupport

  Scan = Jekyll::Infrastructure::HtmlScan
  G = PropCheck::Generators
  PROPERTY_SEED = 0x5CA1_2026
  PROPERTY_RUNS = 100

  # A tokenizer written as the @pattern in HtmlScan shows.
  def self.image_token
    /
      #{Scan::SKIPPED}
      | (?<img>#{Scan.start_tag('img')})
      | #{Scan::OTHER_START_TAG}
    /xi
  end

  TOKEN = image_token

  TAG_CASES = %w[img IMG iMg].freeze
  ATTRIBUTE_NAMES = %w[src alt data-note title].freeze
  QUOTES = ['"', "'"].freeze
  ATTRIBUTE_VALUES = ['a > b', 'A &amp; B', 'plain text'].freeze
  SKIPPED_ELEMENTS = %w[script style textarea].freeze
  SKIP_CASES = [
    ['<!--', '-->'],
    ['<script>', '</script>'],
    ['<style>', '</style>'],
    ['<textarea>', '</textarea>'],
  ].freeze

  ScanFragment = Struct.new(:html, :matches, keyword_init: true)
  ScanCase = Struct.new(:html, :matches, :skip_kind, keyword_init: true)

  def self.image_tag(tag_case, attribute_name, quote, value)
    tag_name = TAG_CASES.fetch(tag_case)
    name = ATTRIBUTE_NAMES.fetch(attribute_name)
    delimiter = QUOTES.fetch(quote)
    text = ATTRIBUTE_VALUES.fetch(value)
    "<#{tag_name} #{name}=#{delimiter}#{text}#{delimiter}>"
  end

  FRAGMENT_GENERATOR = G.tuple(
    G.choose(0..5),
    G.choose(0...TAG_CASES.length),
    G.choose(0...ATTRIBUTE_NAMES.length),
    G.choose(0...QUOTES.length),
    G.choose(0...ATTRIBUTE_VALUES.length),
  ).map do |kind, tag_case, attribute_name, quote, value|
    tag = TestHtmlScan.image_tag(tag_case, attribute_name, quote, value)
    case kind
    when 0
      ScanFragment.new(html: tag, matches: [tag])
    when 1
      tag_name = TAG_CASES.fetch(tag_case)
      custom_name = tag_case.even? ? 'img-icon' : 'imgur'
      custom_tag = "<#{custom_name}" + tag.delete_prefix("<#{tag_name}")
      ScanFragment.new(html: custom_tag, matches: [])
    when 2
      ScanFragment.new(html: "<!--\n#{tag}\n-->", matches: [])
    when 3
      element = SKIPPED_ELEMENTS.fetch(tag_case % SKIPPED_ELEMENTS.length)
      opening = tag_case.even? ? element.upcase : element
      ScanFragment.new(html: "<#{opening}>\n#{tag}\n</#{element}>", matches: [])
    when 4
      outer_quote = QUOTES.fetch(quote)
      inner_tag = TestHtmlScan.image_tag(tag_case, attribute_name, 1 - quote, value)
      html = "<div data-example=#{outer_quote}#{inner_tag}#{outer_quote}>"
      ScanFragment.new(html: html, matches: [])
    else
      html = "<script-loader></script-loader>#{tag}<script></script>"
      ScanFragment.new(html: html, matches: [tag])
    end
  end

  SCAN_CASE_GENERATOR = G.tuple(
    G.choose(0...SKIP_CASES.length),
    G.choose(0...TAG_CASES.length),
    G.choose(0...ATTRIBUTE_NAMES.length),
    G.choose(0...QUOTES.length),
    G.choose(0...ATTRIBUTE_VALUES.length),
    G.array(FRAGMENT_GENERATOR),
  ).map do |skip_kind, tag_case, attribute_name, quote, value, fragments|
    opener, closer = SKIP_CASES.fetch(skip_kind)
    fake_tag = TestHtmlScan.image_tag(tag_case, attribute_name, quote, value)
    live_tag = TestHtmlScan.image_tag(
      (tag_case + 1) % TAG_CASES.length,
      (attribute_name + 1) % ATTRIBUTE_NAMES.length,
      1 - quote,
      (value + 1) % ATTRIBUTE_VALUES.length,
    )
    skipped = "#{opener}\n#{fake_tag}\n#{closer}"
    ScanCase.new(
      html: skipped + live_tag + fragments.map(&:html).join,
      matches: [live_tag] + fragments.flat_map(&:matches),
      skip_kind: skip_kind,
    )
  end

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

  def test_custom_tag_name_is_matched_literally
    pattern = Scan.start_tag('site-card.v2')

    assert_equal ['<site-card.v2>'], '<site-card-v2><site-card.v2>'.scan(pattern)
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

  def test_generated_skip_matrix_resumes_at_the_live_image
    tag_cases = TAG_CASES.first(2)
    placements = ['', '<span data-note="between"></span>']
    SKIP_CASES.each do |opener, closer|
      tag_cases.each_with_index do |tag_name, tag_case|
        placements.each do |placement|
          fake = "<#{tag_name} alt='fake > image'>"
          live = "<#{TAG_CASES.fetch(1 - tag_case)} src=\"/live.png\">"
          html = "#{opener}\n#{fake}\n#{closer}#{placement}#{live}"
          assert_equal [live], images(html), "skip=#{opener.inspect} placement=#{placement.inspect}"
        end
      end
    end
  end

  def test_property_generation_replays_and_shrinks
    integer_generator = G.integer
    seed = (1..100).find do |candidate|
      seeded_property_generator(integer_generator, candidate).call(size: 1) != 0
    end
    refute_nil seed, 'expected a seed whose initial integer can shrink'

    first_sequence = seeded_property_generator(integer_generator, seed).sample(12)
    second_sequence = seeded_property_generator(integer_generator, seed).sample(12)
    assert_equal first_sequence, second_sequence

    failure = assert_raises(Minitest::Assertion) do
      run_seeded_property(integer_generator, seed: seed, runs: 1) do |_input|
        raise Minitest::Assertion, 'intentional PropCheck shrink probe'
      end
    end
    assert_equal 0, failure.prop_check_info.fetch(:shrunken_input)
    assert_operator failure.prop_check_info.fetch(:n_shrink_steps), :>, 0
    assert_includes failure.message, "property seed=#{seed}"
  end

  def test_property_finds_exact_tags_in_generated_fragment_sequences
    # Compile inside the test so method-level mutations affect this tokenizer.
    token = self.class.image_token
    check_property(SCAN_CASE_GENERATOR, seed: PROPERTY_SEED, runs: PROPERTY_RUNS) do |input|
      assert_equal input.matches, images(input.html, token), "HTML input: #{input.html.inspect}"
    end
  end
end
