# frozen_string_literal: true

require 'test_helper'
require 'src/infrastructure/footnote_markup_hook'

# Tests for FootnoteMarkupTransforms: the <hr> before the footnotes section
# and the ",&#x202F;" separator between adjacent footnote references
# (formerly Liquid replace filters in _layouts/substitute.html).
class TestFootnoteMarkupTransforms < Minitest::Test
  Transforms = Jekyll::Infrastructure::FootnoteMarkupTransforms

  FOOTNOTES_DIV = '<div class="footnotes" role="doc-endnotes"><ol><li id="fn:1"><p>Note.</p></li></ol></div>'

  def test_inserts_hr_before_footnotes_section
    result = Transforms.transform("<p>Body.</p>#{FOOTNOTES_DIV}")
    assert_includes result, '<hr><div class="footnotes" role="doc-endnotes">'
  end

  def test_separates_adjacent_footnote_refs
    refs = '<sup id="fnref:1"><a href="#fn:1" class="footnote">1</a></sup>' \
           '<sup id="fnref:2"><a href="#fn:2" class="footnote">2</a></sup>'
    result = Transforms.transform("<p>Claim.#{refs}</p>#{FOOTNOTES_DIV}")
    assert_includes result,
                    '</a></sup><sup class="fn-separator">,&#x202F;</sup><sup id="fnref:2">'
  end

  def test_separates_three_adjacent_refs_twice
    refs = '<sup id="fnref:a"><a href="#fn:a" class="footnote">1</a></sup>' \
           '<sup id="fnref:b"><a href="#fn:b" class="footnote">2</a></sup>' \
           '<sup id="fnref:c"><a href="#fn:c" class="footnote">3</a></sup>'
    result = Transforms.transform("<p>X.#{refs}</p>#{FOOTNOTES_DIV}")
    assert_equal 2, result.scan('fn-separator').length
  end

  def test_non_adjacent_refs_untouched
    html = '<p>One.<sup id="fnref:1"><a href="#fn:1" class="footnote">1</a></sup> ' \
           "and two.<sup id=\"fnref:2\"><a href=\"#fn:2\" class=\"footnote\">2</a></sup></p>#{FOOTNOTES_DIV}"
    result = Transforms.transform(html)
    refute_includes result, 'fn-separator'
  end

  def test_page_without_footnotes_returned_unchanged
    html = '<p>No footnotes.</p>'
    assert_same html, Transforms.transform(html)
  end

  def test_transform_precedes_preview_injection
    # The separator pattern matches pristine kramdown sups; the injector
    # then rewrites the sup interiors without disturbing the separator.
    require 'src/infrastructure/footnote_preview_injector'
    refs = '<sup id="fnref:1"><a href="#fn:1" class="footnote">1</a></sup>' \
           '<sup id="fnref:2"><a href="#fn:2" class="footnote">2</a></sup>'
    body = "<p>Claim.#{refs}</p>" \
           '<div class="footnotes" role="doc-endnotes"><ol>' \
           '<li id="fn:1"><p>One.</p></li><li id="fn:2"><p>Two.</p></li></ol></div>'
    result = Jekyll::Infrastructure::FootnotePreviewInjector.inject(Transforms.transform(body))
    assert_includes result, 'fn-separator'
    assert_equal 2, result.scan('class="footnote-preview"').length
  end
end

# Tests for the :post_render hook registration.
class TestFootnoteMarkupHook < Minitest::Test
  FakeItem = Struct.new(:output_ext, :output)

  def run_document_hooks(item)
    hooks = Jekyll::Hooks.instance_variable_get(:@registry)
    (hooks.dig(:documents, :post_render) || []).each { |h| h.call(item) }
  end

  def footnote_page
    FakeItem.new(
      '.html',
      '<p>Body.</p><div class="footnotes" role="doc-endnotes"><ol>' \
      '<li id="fn:1"><p>Note.</p></li></ol></div>',
    )
  end

  def test_hook_transforms_html_documents
    item = footnote_page
    run_document_hooks(item)
    assert_includes item.output, '<hr><div class="footnotes"'
  end

  def test_hook_skips_non_html_output
    item = FakeItem.new('.xml', footnote_page.output)
    original = item.output.dup
    run_document_hooks(item)
    assert_equal original, item.output
  end

  def test_hook_skips_nil_output
    item = FakeItem.new('.html', nil)
    run_document_hooks(item)
    assert_nil item.output
  end
end
