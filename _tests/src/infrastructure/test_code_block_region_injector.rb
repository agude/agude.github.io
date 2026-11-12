# frozen_string_literal: true

require 'test_helper'
require 'src/infrastructure/code_block_region_injector'

# Tests for CodeBlockRegionInjector: every <pre> in rendered HTML becomes a
# labeled, keyboard-focusable region.
class TestCodeBlockRegionInjector < Minitest::Test
  Injector = Jekyll::Infrastructure::CodeBlockRegionInjector

  REGION = 'tabindex="0" role="region"'

  def inject(html)
    Injector.inject(html, source: '_posts/post.md')
  end

  def fence(language, body = 'x = 1')
    %(<div class="language-#{language} highlighter-rouge"><div class="highlight">) +
      %(<pre class="highlight"><code>#{body}</code></pre></div></div>)
  end

  def test_fence_is_labeled_with_its_language
    wrapper = '<div class="language-python highlighter-rouge"><div class="highlight">'
    pre = %(<pre class="highlight" #{REGION} aria-label="Python code"><code>x = 1</code></pre></div></div>)
    expected = "#{wrapper}#{pre}"
    assert_equal expected, inject(fence('python'))
  end

  def test_language_names_are_spoken_names
    assert_includes inject(fence('cpp')), 'aria-label="C++ code"'
    assert_includes inject(fence('sql')), 'aria-label="SQL code"'
    assert_includes inject(fence('vim')), 'aria-label="Vim script code"'
  end

  def test_plain_text_fences_are_code_blocks
    assert_includes inject(fence('plaintext')), 'aria-label="Code block"'
    assert_includes inject(fence('text')), 'aria-label="Code block"'
  end

  def test_wrapper_with_whitespace_between_tags
    html = %(<div class="language-bash highlighter-rouge">\n  <div class="highlight">\n    <pre class="highlight">)
    assert_includes inject(html), %(<pre class="highlight" #{REGION} aria-label="Bash code">)
  end

  def test_bare_pre_is_a_code_block
    assert_equal %(<p>a</p><pre #{REGION} aria-label="Code block">text</pre>), inject('<p>a</p><pre>text</pre>')
  end

  def test_every_pre_in_page_is_labeled
    output = inject("#{fence('python')}#{fence('yaml')}<PRE>raw</PRE>")
    assert_equal 3, output.scan(REGION).size
    assert_includes output, 'aria-label="YAML code"'
  end

  def test_inline_code_is_unchanged
    html = '<p><code class="language-plaintext highlighter-rouge">pre</code></p>'
    assert_equal html, inject(html)
  end

  def test_preview_span_copy_is_unchanged
    html = '<span class="fnp fnp-pre highlight"><code>x</code></span>'
    assert_equal html, inject(html)
  end

  def test_pre_inside_comment_script_and_attribute_is_unchanged
    html = '<!-- <pre> --><script>let s = "<pre>";</script><a title="<pre>">x</a>'
    assert_equal html, inject(html)
  end

  def test_prefix_named_tags_are_unchanged
    html = '<preview>x</preview>'
    assert_equal html, inject(html)
  end

  def test_unknown_language_stops_the_build
    error = assert_raises(Jekyll::Errors::FatalException) { inject(fence('rust')) }
    assert_includes error.message, "'rust'"
    assert_includes error.message, 'LANGUAGE_NAMES'
    assert_includes error.message, '_posts/post.md'
  end

  def test_author_set_attributes_stop_the_build
    %w[tabindex="-1" role="figure" aria-label="Example"].each do |attribute|
      error = assert_raises(Jekyll::Errors::FatalException) { inject("<pre #{attribute}>x</pre>") }
      assert_includes error.message, '_posts/post.md'
    end
  end

  def test_valueless_author_attributes_stop_the_build
    %w[tabindex role aria-label ARIA-LABEL].each do |attribute|
      error = assert_raises(Jekyll::Errors::FatalException) { inject("<pre #{attribute}>x</pre>") }
      assert_includes error.message, attribute.downcase
    end
  end

  def test_attribute_names_inside_quoted_values_are_allowed
    html = %(<pre title="The role= token" data-note='aria-label=x'>x</pre>)
    assert_equal %(<pre title="The role= token" data-note='aria-label=x' #{REGION} aria-label="Code block">x</pre>),
                 inject(html)
  end

  def test_applies_only_to_html_with_pre
    with_pre = Struct.new(:output_ext, :output).new('.html', '<pre>x</pre>')
    without_pre = Struct.new(:output_ext, :output).new('.html', '<p>x</p>')
    markdown = Struct.new(:output_ext, :output).new('.md', '<pre>x</pre>')
    assert Injector.applies_to?(with_pre)
    refute Injector.applies_to?(without_pre)
    refute Injector.applies_to?(markdown)
  end
end
