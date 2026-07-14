# frozen_string_literal: true

require 'test_helper'
require 'src/infrastructure/footnote_preview_injector'

# Tests for FootnotePreviewInjector: injects a .footnote-preview span inside
# each kramdown footnote <sup>, after the reference <a>. The preview is a
# phrasing-only rewrite of the footnote body — block elements become
# <span class="fnp fnp-<tag>"> so the copy is valid inside a paragraph.
class TestFootnotePreviewInjector < Minitest::Test
  Injector = Jekyll::Infrastructure::FootnotePreviewInjector
  Text     = Jekyll::Infrastructure::TextProcessingUtils

  # Minimal kramdown-style HTML with one footnote reference and one footnote body.
  def footnote_html(id:, ref_text: '1', footnote_body: '<p>Note text.</p>')
    <<~HTML.chomp
      <sup id="fnref:#{id}"><a href="#fn:#{id}" class="footnote" rel="footnote" role="doc-noteref">#{ref_text}</a></sup>
      <div class="footnotes" role="doc-endnotes"><ol>
        <li id="fn:#{id}">#{footnote_body} <a href="#fnref:#{id}" class="reversefootnote" role="doc-backlink">&#8617;</a></li>
      </ol></div>
    HTML
  end

  # Extracts preview content. The comment markers are the reliable anchor —
  # the preview can contain nested </span> tags.
  def extract_preview(html)
    html[/#{Regexp.escape(Text::FOOTNOTE_PREVIEW_OPEN)}(.*?)#{Regexp.escape(Text::FOOTNOTE_PREVIEW_CLOSE)}/m, 1]
      &.then { |s| s[%r{<span class="footnote-preview"[^>]*>(.*)</span>}m, 1] }
  end

  # ── inject: guard conditions ─────────────────────────────────────────────────

  def test_inject_returns_unchanged_when_no_footnotes
    html = '<p>No footnotes here.</p>'
    assert_equal html, Injector.inject(html)
  end

  def test_inject_returns_unchanged_when_footnotes_section_missing
    html = '<a href="#fn:x" class="footnote">1</a>'
    assert_equal html, Injector.inject(html)
  end

  # ── inject: structure ────────────────────────────────────────────────────────

  def test_inject_places_preview_inside_sup_after_ref_link
    result = Injector.inject(footnote_html(id: 'note'))
    # The preview opens after the reference </a> and closes before </sup>,
    # so it is a sibling of the <a> (links inside the preview stay valid).
    assert_match %r{</a>#{Regexp.escape(Text::FOOTNOTE_PREVIEW_OPEN)}}, result
    assert_match %r{#{Regexp.escape(Text::FOOTNOTE_PREVIEW_CLOSE)}</sup>}, result
  end

  def test_inject_emits_matching_inline_anchor_names
    # Per-footnote anchor names: a shared name would resolve to the last
    # element in the document, anchoring every card to the final ref.
    result = Injector.inject(footnote_html(id: 'note'))
    assert_includes result, '<sup style="anchor-name:--fnref-note" id="fnref:note">'
    assert_includes result, 'style="position-anchor:--fnref-note"'
  end

  def test_inject_sanitizes_anchor_names_to_css_idents
    result = Injector.inject(footnote_html(id: 'a.b:c'))
    assert_includes result, 'anchor-name:--fnref-a-b-c'
    assert_includes result, 'position-anchor:--fnref-a-b-c'
  end

  def test_inject_adds_comment_markers
    result = Injector.inject(footnote_html(id: 'note'))
    assert_includes result, Text::FOOTNOTE_PREVIEW_OPEN
    assert_includes result, Text::FOOTNOTE_PREVIEW_CLOSE
  end

  def test_inject_preview_span_attributes
    result = Injector.inject(footnote_html(id: 'note'))
    assert_includes result, 'class="footnote-preview"'
    assert_includes result, 'aria-hidden="true"'
    assert_includes result, 'hidden'
  end

  # ── inject: content ──────────────────────────────────────────────────────────

  def test_inject_preview_contains_footnote_text
    result = Injector.inject(footnote_html(id: 'note', footnote_body: '<p>My footnote.</p>'))
    assert_includes result, 'My footnote.'
  end

  def test_inject_strips_reversefootnote_from_preview
    result  = Injector.inject(footnote_html(id: 'note'))
    preview = extract_preview(result)
    refute_includes preview.to_s, 'reversefootnote'
    refute_includes preview.to_s, '&#8617;'
  end

  # ── inject: phrasing-only rewrite ────────────────────────────────────────────

  def test_inject_flattens_block_elements_to_classed_spans
    body    = '<figure><blockquote><p>Quote.</p></blockquote><figcaption>Author</figcaption></figure>'
    result  = Injector.inject(footnote_html(id: 'note', footnote_body: body))
    preview = extract_preview(result).to_s
    assert_includes preview, '<span class="fnp fnp-figure">'
    assert_includes preview, '<span class="fnp fnp-blockquote">'
    assert_includes preview, '<span class="fnp fnp-figcaption">'
    assert_includes preview, '<span class="fnp fnp-p">'
    # No raw block tags may survive: inside a <p>, the HTML5 parser would
    # eject them and split the paragraph.
    refute_match(/<(?:figure|blockquote|figcaption|p)\b/, preview)
  end

  def test_inject_citedquote_full_fidelity
    # The real citedquote structure: figure > blockquote + figcaption,
    # where figcaption holds span.citation with <cite> and <a>. Existing
    # classes are preserved after the fnp classes.
    body = '<figure class="cited-quote">' \
           '<blockquote><p>The quote text.</p></blockquote>' \
           '<figcaption>—<span class="citation">Author. ' \
           '<a href="https://example.com">"Title"</a> ' \
           '<cite>Journal</cite>. 2024.</span></figcaption>' \
           '</figure>'
    result  = Injector.inject(footnote_html(id: 'note', footnote_body: body))
    preview = extract_preview(result).to_s
    assert_includes preview, '<span class="fnp fnp-figure cited-quote">'
    assert_includes preview, '<span class="fnp fnp-blockquote">'
    assert_includes preview, 'The quote text.'
    assert_includes preview, '<span class="fnp fnp-figcaption">'
    assert_includes preview, '<cite>Journal</cite>'
    assert_includes preview, '<a href="https://example.com"'
  end

  def test_inject_flattens_nested_divs
    # Footnotes with book-link cards contain <div class="card-element">.
    inner_div = '<div class="card-element card-image"><img src="cover.jpg" alt="Cover"></div>'
    body      = "<p>Note with a card. #{inner_div}</p>"
    result    = Injector.inject(footnote_html(id: 'note', footnote_body: body))
    preview   = extract_preview(result).to_s
    assert_includes preview, 'Note with a card.'
    assert_includes preview, '<span class="fnp fnp-div card-element card-image">'
  end

  def test_inject_flattens_headings_and_removes_anchor_icons
    # Sectioned footnotes contain h3 headings; the layout's
    # anchor_headings.html decorates them with an <a><svg></svg></a> icon.
    body    = '<h3 id="sec">Section <a href="#sec"><svg class="anchor-link-img"><path d="M0"></path></svg></a></h3>' \
              '<p>Section text.</p>'
    result  = Injector.inject(footnote_html(id: 'note', footnote_body: body))
    preview = extract_preview(result).to_s
    assert_includes preview, '<span class="fnp fnp-h3">'
    assert_includes preview, 'Section text.'
    refute_includes preview, 'anchor-link-img'
    refute_includes preview, '<svg'
  end

  def test_inject_preserves_whitespace_inside_pre
    # Whitespace is collapsed everywhere except <pre> content, whose
    # alignment is significant (fnp-pre restores white-space: pre in CSS).
    body    = "<p>Code:</p><pre><code>line one\n  indented two</code></pre>"
    result  = Injector.inject(footnote_html(id: 'note', footnote_body: body))
    preview = extract_preview(result).to_s
    assert_includes preview, '<span class="fnp fnp-pre">'
    assert_includes preview, "line one\n  indented two"
    refute_match(/<pre\b/, preview)
  end

  def test_inject_raises_on_unexpected_block_element
    body  = '<p>Data:</p><table><tr><td>x</td></tr></table>'
    html  = footnote_html(id: 'note', footnote_body: body)
    error = assert_raises(Jekyll::Errors::FatalException) { Injector.inject(html) }
    assert_includes error.message, 'table'
    assert_includes error.message, 'fn:note'
  end

  # ── inject: duplicate-content neutralization ─────────────────────────────────

  def test_inject_strips_ids_from_preview_copy
    body    = '<p id="para-anchor">Text with <span id="span-anchor">anchor</span>.</p>'
    result  = Injector.inject(footnote_html(id: 'note', footnote_body: body))
    preview = extract_preview(result).to_s
    refute_includes preview, 'para-anchor'
    refute_includes preview, 'span-anchor'
  end

  def test_inject_preserves_links_but_removes_them_from_tab_order
    body    = '<p>See <a href="https://example.com">this link</a> for details.</p>'
    result  = Injector.inject(footnote_html(id: 'note', footnote_body: body))
    preview = extract_preview(result).to_s
    assert_includes preview, 'href="https://example.com"'
    assert_includes preview, 'this link'
    assert_match(/<a [^>]*tabindex="-1"/, preview)
  end

  def test_inject_removes_nested_book_previews_from_copy
    # A book link inside a footnote carries its own hover-preview card.
    # The copy drops it (and its comment markers); the original footnote
    # at the page bottom keeps the working book preview.
    body = '<p>Coined in <a href="/books/excession/"><cite class="book-title">Excession</cite>' \
           '<!--book-preview--><span class="book-link-preview" aria-hidden="true" hidden>' \
           '<img src="cover.jpg" alt="Cover"><span class="book-link-preview-lede">Lede text.</span>' \
           '</span><!--/book-preview--></a>.</p>'
    result  = Injector.inject(footnote_html(id: 'note', footnote_body: body))
    preview = extract_preview(result).to_s
    assert_includes preview, '<cite class="book-title">Excession</cite>'
    refute_includes preview, 'book-link-preview'
    refute_includes preview, 'book-preview'
    refute_includes preview, 'Lede text.'
  end

  def test_inject_lazy_loads_preview_images
    body    = '<p>The cover: <img src="cover.jpg" alt="Cover"></p>'
    result  = Injector.inject(footnote_html(id: 'note', footnote_body: body))
    preview = extract_preview(result).to_s
    assert_includes preview, 'loading="lazy"'
    assert_includes preview, 'decoding="async"'
  end

  def test_inject_keeps_explicit_image_loading_attribute
    body    = '<p>The cover: <img src="cover.jpg" alt="Cover" loading="eager"></p>'
    result  = Injector.inject(footnote_html(id: 'note', footnote_body: body))
    preview = extract_preview(result).to_s
    assert_includes preview, 'loading="eager"'
    refute_includes preview, 'loading="lazy"'
  end

  # ── inject: multiple footnotes and non-footnote sups ─────────────────────────

  def test_inject_handles_multiple_footnotes
    html = <<~HTML
      <sup id="fnref:one"><a href="#fn:one" class="footnote">1</a></sup>
      <sup id="fnref:two"><a href="#fn:two" class="footnote">2</a></sup>
      <div class="footnotes"><ol>
        <li id="fn:one"><p>First note.</p> <a class="reversefootnote">&#8617;</a></li>
        <li id="fn:two"><p>Second note.</p> <a class="reversefootnote">&#8617;</a></li>
      </ol></div>
    HTML
    result = Injector.inject(html)
    assert_equal 2, result.scan('class="footnote-preview"').length
    assert_includes result, 'First note.'
    assert_includes result, 'Second note.'
  end

  def test_inject_does_not_affect_other_sup_elements
    html = <<~HTML
      <p>Math: x<sup>2</sup></p>
      <sup id="fnref:note"><a href="#fn:note" class="footnote">1</a></sup>
      <div class="footnotes"><ol>
        <li id="fn:note"><p>Note.</p> <a class="reversefootnote">&#8617;</a></li>
      </ol></div>
    HTML
    result = Injector.inject(html)
    assert_equal 1, result.scan('class="footnote-preview"').length
    assert_includes result, '<sup>2</sup>'
  end

  def test_inject_is_idempotent
    html  = footnote_html(id: 'note')
    once  = Injector.inject(html)
    assert_equal once, Injector.inject(once)
  end

  def test_inject_is_idempotent_when_footnote_contains_sup
    # A copied <sup> in the preview would derail the non-greedy </sup>
    # match on a second pass; the guard skips already-injected sups.
    html  = footnote_html(id: 'note', footnote_body: '<p>Math: x<sup>2</sup> note.</p>')
    once  = Injector.inject(html)
    assert_equal once, Injector.inject(once)
  end

  def test_inject_empty_footnote_body_skipped
    html = <<~HTML
      <sup id="fnref:note"><a href="#fn:note" class="footnote">1</a></sup>
      <div class="footnotes"><ol>
        <li id="fn:note"><p> <a class="reversefootnote">&#8617;</a></p></li>
      </ol></div>
    HTML
    result = Injector.inject(html)
    refute_includes result, 'footnote-preview'
  end
end

# Tests for the :post_render hook registration.
class TestFootnotePreviewInjectorHook < Minitest::Test
  # output_ext needed because strip_feed_previews_hook fires on :pages hooks too.
  FakeItem = Struct.new(:output_ext, :output)

  def run_document_hooks(item)
    hooks = Jekyll::Hooks.instance_variable_get(:@registry)
    (hooks.dig(:documents, :post_render) || []).each { |h| h.call(item) }
  end

  def run_page_hooks(item)
    hooks = Jekyll::Hooks.instance_variable_get(:@registry)
    (hooks.dig(:pages, :post_render) || []).each { |h| h.call(item) }
  end

  def footnote_page
    html = <<~HTML
      <sup id="fnref:x"><a href="#fn:x" class="footnote">1</a></sup>
      <div class="footnotes"><ol>
        <li id="fn:x"><p>Hook note.</p> <a class="reversefootnote">&#8617;</a></li>
      </ol></div>
    HTML
    FakeItem.new('.html', html)
  end

  def test_hook_injects_on_documents
    item = footnote_page
    run_document_hooks(item)
    assert_includes item.output, 'class="footnote-preview"'
  end

  def test_hook_injects_on_pages
    item = footnote_page
    run_page_hooks(item)
    assert_includes item.output, 'class="footnote-preview"'
  end

  def test_hook_skips_nil_output
    item = FakeItem.new('.html', nil)
    run_document_hooks(item)
    assert_nil item.output
  end

  def test_hook_skips_output_without_footnotes
    item     = FakeItem.new('.html', '<p>No footnotes.</p>')
    original = item.output.dup
    run_document_hooks(item)
    assert_equal original, item.output
  end
end
