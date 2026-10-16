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
#
# Content links are checked through whatever token `.themed .content a`
# uses in _sass/_layout.scss (LINK below), on both the page and the
# hover-card background. Tokens whose value is the `$sidebar-color-value`
# interpolation resolve to `theme_color` in _config.yml, the value
# main.scss injects at build time.
class TestDarkModeContrast < Minitest::Test
  VARIABLES_PATH = File.expand_path('../../_sass/_variables.scss', __dir__)
  LAYOUT_PATH = File.expand_path('../../_sass/_layout.scss', __dir__)
  CONFIG_PATH = File.expand_path('../../_config.yml', __dir__)

  # The Sass interpolation main.scss fills with theme_color.
  ACCENT_INTERPOLATION = "\#{$sidebar-color-value}"

  # Placeholder for the token content links use, read from _layout.scss.
  LINK = :content_link

  AA_NORMAL_TEXT = 4.5

  PAIRS = [
    %w[--body-color --body-bg],
    %w[--muted-color --body-bg],
    %w[--code-color --code-bg],
    %w[--heading-color --body-bg],
    %w[--emphasis-color --body-bg],
    %w[--blockquote-color --body-bg],
    [LINK, '--body-bg'],
    [LINK, '--card-bg'],
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
        fg = content_link_token if fg == LINK
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

  # The custom property behind `.themed .content a { color: ... }`, read
  # through the Sass variable it names (`$x: var(--token)` in
  # _variables.scss; Sass treats `-` and `_` in names as equal).
  def content_link_token
    rule = File.read(LAYOUT_PATH)[/\.themed \.content a\b[^{]*\{\s*color:\s*([^;]+);/, 1]
    raise 'No color rule for .themed .content a in _layout.scss' unless rule

    value = rule.strip
    if value.start_with?('$')
      name = Regexp.escape(value[1..]).gsub(/\\-|_/, '[-_]')
      value = source[/^\$#{name}:\s*([^;]+);/, 1] or raise "Sass variable #{rule} not found"
    end
    value[/\Avar\((--[\w-]+)\)\z/, 1] or raise "Unexpected link color #{value.inspect}"
  end

  def theme_color
    @theme_color ||= YAML.safe_load_file(CONFIG_PATH).fetch('theme_color')
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
      value = value.strip
      tokens[name] = value == ACCENT_INTERPOLATION ? theme_color : value
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
