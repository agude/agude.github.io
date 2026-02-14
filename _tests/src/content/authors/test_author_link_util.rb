# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/authors/author_link_util'

# Tests for Jekyll::Authors::AuthorLinkUtils.
#
# Verifies that the utility module correctly uses AuthorLinkFinder + LinkFormatter.
class TestAuthorLinkUtils < Minitest::Test
  Utils = Jekyll::Authors::AuthorLinkUtils

  def setup
    @author_page = create_doc(
      { 'title' => 'Isaac Asimov', 'layout' => 'author_page' },
      '/authors/isaac-asimov.html'
    )
    @site = create_site({}, {}, [@author_page])
    @page = create_doc({}, '/current.html')
    @context = create_context({}, { site: @site, page: @page })
  end

  # --- Format Parameter Tests ---

  def test_render_with_format_html_returns_html
    result = Utils.render_author_link('Isaac Asimov', @context, format: :html)
    assert_match %r{<a href="/authors/isaac-asimov.html">}, result
    assert_match %r{<span class="author-name">Isaac Asimov</span>}, result
  end

  def test_render_with_format_markdown_returns_markdown
    result = Utils.render_author_link('Isaac Asimov', @context, format: :markdown)
    assert_equal '[Isaac Asimov](/authors/isaac-asimov.html)', result
  end

  def test_render_without_format_uses_context_mode
    # Default context has no markdown_mode, should return HTML
    result = Utils.render_author_link('Isaac Asimov', @context)
    assert_match(/<a href=/, result)
    assert_match(/<span class="author-name">/, result)
  end

  def test_render_with_markdown_context_returns_markdown
    md_context = create_context({}, { site: @site, page: @page, markdown_mode: true })
    result = Utils.render_author_link('Isaac Asimov', md_context)
    assert_equal '[Isaac Asimov](/authors/isaac-asimov.html)', result
  end

  def test_render_with_format_overrides_context_mode
    # Even with markdown_mode: true, format: :html should return HTML
    md_context = create_context({}, { site: @site, page: @page, markdown_mode: true })
    result = Utils.render_author_link('Isaac Asimov', md_context, format: :html)
    assert_match(/<a href=/, result)
    assert_match(/<span class="author-name">/, result)
  end

  # --- Possessive Tests ---

  def test_render_possessive_html
    result = Utils.render_author_link('Isaac Asimov', @context, nil, true, format: :html)
    assert_match %r{Isaac Asimov</span>\u2019s</a>}, result
  end

  def test_render_possessive_markdown
    result = Utils.render_author_link('Isaac Asimov', @context, nil, true, format: :markdown)
    assert_equal "[Isaac Asimov](/authors/isaac-asimov.html)\u2019s", result
  end

  # --- Override Tests ---

  def test_render_with_override_html
    result = Utils.render_author_link('Isaac Asimov', @context, 'The Good Doctor', nil, format: :html)
    assert_match %r{<span class="author-name">The Good Doctor</span>}, result
  end

  def test_render_with_override_markdown
    result = Utils.render_author_link('Isaac Asimov', @context, 'The Good Doctor', nil, format: :markdown)
    assert_equal '[The Good Doctor](/authors/isaac-asimov.html)', result
  end

  # --- Unknown Author Tests ---

  def test_render_unknown_author_html
    result = Utils.render_author_link('Unknown Person', @context, format: :html)
    assert_equal '<span class="author-name">Unknown Person</span>', result
    refute_match(/<a href=/, result)
  end

  def test_render_unknown_author_markdown
    result = Utils.render_author_link('Unknown Person', @context, format: :markdown)
    assert_equal 'Unknown Person', result
  end
end
