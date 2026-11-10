# frozen_string_literal: true

require 'test_helper'
require 'src/infrastructure/html_compression_filter'

# Compares the accelerated path with the retained upstream Liquid compressor.
class TestHtmlCompressionFilter < Minitest::Test
  include Jekyll::Infrastructure::HtmlCompressionFilter

  # Forces the layout to execute its unchanged Liquid implementation.
  module OriginalCompression
    def compress_html_whitespace(_input, _settings, _environment)
      nil
    end
  end

  def setup
    @settings = {
      'endings' => [],
      'startings' => [],
      'comments' => [],
      'clippings' => [],
      'blanklines' => false,
      'profile' => false,
      'ignore' => { 'envs' => [] },
    }
    layout = File.read(File.expand_path('../../../_layouts/compress.html', __dir__))
    @template = Liquid::Template.parse(layout.sub(/\A---\n.*?\n---\n/m, ''))
  end

  def test_matches_original_for_whitespace_preformatted_text_and_malformed_tags
    inputs = [
      '',
      " \n\t ",
      '<p>plain</p>',
      "<p> é\ttext\r\n here </p>",
      "<pre>  a\n\tb  </pre>   <p> after </p>",
      "before <pre class='x'>  a\n\n b </pre><pre> next </pre>",
      '<pre>unclosed',
      '</pre>after',
      '<pre></pre>',
      '<pre',
      '<prefix> value </prefix>',
      '<pre>a</pre>b</pre>c',
      '<!--book-preview--><span> preview </span><!--/book-preview-->',
      '<script> const x = 1; </script><style> a { color: red; } </style>',
    ]
    inputs.each { |input| assert_matches_original(input) }
  end

  def test_advanced_options_use_the_original_layout
    {
      'endings' => ['p'],
      'startings' => ['html'],
      'comments' => 'all',
      'clippings' => 'all',
      'blanklines' => true,
      'profile' => true,
    }.each do |key, value|
      @settings[key] = value
      assert_nil compress_html_whitespace('<p> text </p>', @settings, 'production')
      assert_matches_original("<html><p> text </p><!-- comment -->\n</html>")
      @settings[key] = %w[blanklines profile].include?(key) ? false : []
    end
  end

  def test_ignored_environments_preserve_the_input
    [%w[development production], 'all', 'production'].each do |ignored|
      @settings['ignore']['envs'] = ignored
      input = "<p>  keep\n whitespace </p>"
      assert_equal input, compress_html_whitespace(input, @settings, 'production')
      assert_matches_original(input)
    end
  end

  def test_missing_configuration_uses_the_original_layout
    assert_nil compress_html_whitespace('text', nil, 'production')
    assert_nil compress_html_whitespace('text', {}, 'production')
  end

  private

  def assert_matches_original(input)
    payload = {
      'content' => input,
      'site' => { 'compress_html' => @settings, 'time' => Time.utc(2026) },
      'jekyll' => { 'environment' => 'production' },
    }
    original = @template.render!(Marshal.load(Marshal.dump(payload)), filters: [OriginalCompression])
    accelerated = @template.render!(Marshal.load(Marshal.dump(payload)))
    assert_equal original, accelerated, input.inspect
  end
end
