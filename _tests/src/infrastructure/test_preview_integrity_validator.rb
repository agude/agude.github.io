# frozen_string_literal: true

require 'test_helper'
require 'src/infrastructure/preview_integrity_validator'

# Tests for PreviewIntegrityValidator: raises when rendered HTML contains
# hover-preview markup that the markdown parser split (escaped tag debris
# abutting a raw preview comment marker).
class TestPreviewIntegrityValidator < Minitest::Test
  Validator = Jekyll::Infrastructure::PreviewIntegrityValidator

  def test_valid_book_preview_passes
    html = '<p><a href="/books/dune/"><cite class="book-title">Dune</cite>' \
           '<!--book-preview--><span class="book-link-preview" hidden>x</span><!--/book-preview-->' \
           '</a> text.</p>'
    Validator.validate(html, '/test/')
  end

  def test_valid_footnote_preview_passes
    html = '<sup id="fnref:1"><a href="#fn:1" class="footnote">1</a>' \
           '<!--footnote-preview--><span class="footnote-preview" hidden>x</span><!--/footnote-preview-->' \
           '</sup>'
    Validator.validate(html, '/test/')
  end

  def test_page_without_markers_passes
    Validator.validate('<p>No previews here.</p>', '/test/')
  end

  def test_escaped_debris_before_marker_raises
    # The signature of the mangled abyss page: kramdown escaped the
    # orphaned close tags, leaving them abutting the raw marker.
    html = '<p>powerful.&lt;/span&gt;&lt;/span&gt;<!--/book-preview-->&lt;/a&gt;:</p>'
    error = assert_raises(Jekyll::Errors::FatalException) { Validator.validate(html, '/books/x/') }
    assert_includes error.message, '/books/x/'
    assert_includes error.message, 'book-preview'
  end

  def test_text_after_marker_raises
    html = '<p><!--footnote-preview-->orphaned text with no span</p>'
    assert_raises(Jekyll::Errors::FatalException) { Validator.validate(html, '/test/') }
  end

  def test_marker_inside_code_block_passes
    # Rouge escapes markers inside highlighted code, so a page documenting
    # the preview feature never trips the validator.
    html = '<pre class="highlight"><code>&lt;!--book-preview--&gt;debris&lt;/span&gt;</code></pre>'
    Validator.validate(html, '/test/')
  end
end

# Tests for the :post_render hook registration.
class TestPreviewIntegrityValidatorHook < Minitest::Test
  FakeItem = Struct.new(:output_ext, :output)

  def run_document_hooks(item)
    hooks = Jekyll::Hooks.instance_variable_get(:@registry)
    (hooks.dig(:documents, :post_render) || []).each { |h| h.call(item) }
  end

  def test_hook_raises_on_mangled_html_page
    item = FakeItem.new('.html', '<p>text&lt;/span&gt;<!--/book-preview-->&lt;/a&gt;</p>')
    assert_raises(Jekyll::Errors::FatalException) { run_document_hooks(item) }
  end

  def test_hook_skips_non_html_output
    item = FakeItem.new('.xml', '<p>text&lt;/span&gt;<!--/book-preview-->&lt;/a&gt;</p>')
    run_document_hooks(item)
  end

  def test_hook_skips_nil_output
    item = FakeItem.new('.html', nil)
    run_document_hooks(item)
  end
end
