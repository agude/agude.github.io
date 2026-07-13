# frozen_string_literal: true

require_relative '../test_helper'

# Parses the light and dark :root custom-property blocks in
# _sass/_variables.scss and checks WCAG AA contrast (>=4.5:1) for the pairs
# that carry text: body, muted, code, heading, emphasis (strong/thead/
# post-title), abbr, and blockquote foregrounds against their backgrounds.
#
# The dark palette (added for dark mode) must pass all pairs. Three
# light-mode pairs are pre-existing site colors that already fall short of
# full AA (--muted-color ~3.7:1, --code-color ~3.9:1, --blockquote-color
# ~4.3:1) — untouched by dark-mode work and out of scope to change here.
# Those are pinned to their current ratio as a regression guard instead of
# the full AA bar, so the test still documents the gap without blocking the
# build on a pre-existing issue.
#
# --disabled-color is intentionally excluded: it styles inactive nav
# letters, a disabled affordance WCAG exempts from contrast minimums.
class TestDarkModeContrast < Minitest::Test
  VARIABLES_PATH = File.expand_path('../../_sass/_variables.scss', __dir__)

  AA_NORMAL_TEXT = 4.5

  PAIRS = [
    %w[--body-color --body-bg],
    %w[--muted-color --body-bg],
    %w[--code-color --code-bg],
    %w[--heading-color --body-bg],
    %w[--emphasis-color --body-bg],
    %w[--blockquote-color --body-bg],
  ].freeze

  # [mode, fg, bg] => minimum acceptable ratio. Absent from this map means
  # the pair must clear full AA (AA_NORMAL_TEXT).
  KNOWN_GAPS = {
    %w[light --muted-color --body-bg] => 3.6,
    %w[light --code-color --code-bg] => 3.9,
    %w[light --blockquote-color --body-bg] => 4.2,
  }.freeze

  # Sass interpolation (`#{...}`) can contain its own braces, so a naive
  # non-greedy `.*?` up to the first `}` truncates at the interpolation
  # instead of the block's real close. Treat `#{...}` as an opaque unit.
  ROOT_BLOCK_BODY = /(?:[^{}]|\#\{[^{}]*\})*/

  def test_contrast_pairs_meet_wcag_aa_or_known_baseline
    failures = []

    %w[light dark].each do |mode|
      tokens = mode == 'light' ? light_tokens : dark_tokens

      PAIRS.each do |fg, bg|
        ratio = contrast_ratio(tokens.fetch(fg), tokens.fetch(bg))
        minimum = KNOWN_GAPS.fetch([mode, fg, bg], AA_NORMAL_TEXT)

        next if ratio >= minimum

        failures << "#{mode} #{fg}/#{bg}: #{ratio.round(2)}:1 < #{minimum}:1"
      end
    end

    assert_empty failures, "Contrast regressions:\n  #{failures.join("\n  ")}"
  end

  private

  def source
    @source ||= File.read(VARIABLES_PATH)
  end

  def light_tokens
    @light_tokens ||= parse_root_block(source[/:root\s*\{(#{ROOT_BLOCK_BODY})\}/m, 1])
  end

  def dark_tokens
    @dark_tokens ||= begin
      dark_block = source[/@media \(prefers-color-scheme: dark\)\s*\{\s*:root\s*\{(#{ROOT_BLOCK_BODY})\}\s*\}/m, 1]
      light_tokens.merge(parse_root_block(dark_block))
    end
  end

  def parse_root_block(block)
    tokens = {}
    block.scan(/(--[\w-]+):\s*([^;]+);/) do |name, value|
      tokens[name] = value.strip
    end
    tokens
  end

  def contrast_ratio(fg_value, bg_value)
    l1 = relative_luminance(to_rgb(fg_value))
    l2 = relative_luminance(to_rgb(bg_value))
    l1, l2 = l2, l1 if l1 < l2
    (l1 + 0.05) / (l2 + 0.05)
  end

  def to_rgb(value)
    case value
    when /\Ahsl\(\s*([\d.]+)\s*,\s*([\d.]+)%\s*,\s*([\d.]+)%\s*\)\z/
      hsl_to_rgb(Regexp.last_match(1).to_f, Regexp.last_match(2).to_f, Regexp.last_match(3).to_f)
    when 'white'
      [255, 255, 255]
    when /\A#([0-9a-fA-F]{6})\z/
      Regexp.last_match(1).scan(/../).map { |h| h.to_i(16) }
    else
      raise "Unparseable color value: #{value.inspect}"
    end
  end

  def hsl_to_rgb(hue, saturation, lightness)
    hue /= 360.0
    saturation /= 100.0
    lightness /= 100.0

    if saturation.zero?
      gray = (lightness * 255).round
      return [gray, gray, gray]
    end

    upper = lightness < 0.5 ? lightness * (1 + saturation) : lightness + saturation - (lightness * saturation)
    lower = (2 * lightness) - upper
    [hue + (1.0 / 3), hue, hue - (1.0 / 3)].map { |channel_hue| (hue_to_rgb(lower, upper, channel_hue) * 255).round }
  end

  def hue_to_rgb(lower, upper, channel_hue)
    channel_hue += 1 if channel_hue.negative?
    channel_hue -= 1 if channel_hue > 1
    return lower + ((upper - lower) * 6 * channel_hue) if channel_hue < 1.0 / 6
    return upper if channel_hue < 0.5
    return lower + ((upper - lower) * ((2.0 / 3) - channel_hue) * 6) if channel_hue < 2.0 / 3

    lower
  end

  def relative_luminance(rgb)
    red, green, blue = rgb.map { |channel| srgb_to_linear(channel / 255.0) }
    (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
  end

  def srgb_to_linear(channel)
    channel <= 0.03928 ? channel / 12.92 : (((channel + 0.055) / 1.055)**2.4)
  end
end
