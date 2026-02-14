# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/core/book_link_util'

# Tests for Jekyll::Books::Core::BookLinkUtils.
#
# Verifies that the utility module correctly uses BookLinkFinder + LinkFormatter.
class TestBookLinkUtils < Minitest::Test
  Utils = Jekyll::Books::Core::BookLinkUtils

  def setup
    @book_entry = {
      'title' => 'Dune',
      'url' => '/books/dune/',
      'authors' => ['Frank Herbert'],
      'date' => Date.new(2024, 1, 15)
    }
    @site = create_site_with_link_cache({
                                          'books' => {
                                            'dune' => [@book_entry]
                                          }
                                        })
    @page = create_doc({}, '/current.html')
    @context = create_context({}, { site: @site, page: @page })
  end

  # --- Format Parameter Tests ---

  def test_render_with_format_html_returns_html
    result = Utils.render_book_link('Dune', @context, format: :html)
    assert_match %r{<a href="/books/dune/">}, result
    assert_match %r{<cite class="book-title">Dune</cite>}, result
  end

  def test_render_with_format_markdown_returns_markdown
    result = Utils.render_book_link('Dune', @context, format: :markdown)
    assert_equal '[*Dune*](/books/dune/)', result
  end

  def test_render_without_format_uses_context_mode
    # Default context has no markdown_mode, should return HTML
    result = Utils.render_book_link('Dune', @context)
    assert_match(/<a href=/, result)
    assert_match(/<cite class="book-title">/, result)
  end

  def test_render_with_markdown_context_returns_markdown
    md_context = create_context({}, { site: @site, page: @page, markdown_mode: true })
    result = Utils.render_book_link('Dune', md_context)
    assert_equal '[*Dune*](/books/dune/)', result
  end

  def test_render_with_format_overrides_context_mode
    # Even with markdown_mode: true, format: :html should return HTML
    md_context = create_context({}, { site: @site, page: @page, markdown_mode: true })
    result = Utils.render_book_link('Dune', md_context, format: :html)
    assert_match(/<a href=/, result)
    assert_match(/<cite class="book-title">/, result)
  end

  # --- Cite Parameter Tests ---

  def test_render_with_cite_true_uses_cite_element
    result = Utils.render_book_link('Dune', @context, nil, nil, nil, cite: true, format: :html)
    assert_match %r{<cite class="book-title">Dune</cite>}, result
    refute_match(/book-text/, result)
  end

  def test_render_with_cite_false_uses_span_element
    result = Utils.render_book_link('Dune', @context, nil, nil, nil, cite: false, format: :html)
    assert_match %r{<span class="book-text">Dune</span>}, result
    refute_match(/<cite/, result)
  end

  def test_render_markdown_with_cite_true_uses_italic
    result = Utils.render_book_link('Dune', @context, format: :markdown, cite: true)
    assert_equal '[*Dune*](/books/dune/)', result
  end

  def test_render_markdown_with_cite_false_no_italic
    result = Utils.render_book_link('Dune', @context, nil, nil, nil, cite: false, format: :markdown)
    assert_equal '[Dune](/books/dune/)', result
  end

  # --- Override Tests ---

  def test_render_with_override_uses_override_text
    result = Utils.render_book_link('Dune', @context, 'The Masterpiece', format: :html)
    assert_match %r{<cite class="book-title">The Masterpiece</cite>}, result
    assert_match %r{href="/books/dune/"}, result
  end

  def test_render_with_override_markdown
    result = Utils.render_book_link('Dune', @context, 'The Spice Must Flow', format: :markdown)
    assert_equal '[*The Spice Must Flow*](/books/dune/)', result
  end

  # --- Unknown Book Tests ---

  def test_render_unknown_book_html_returns_cite_only
    result = Utils.render_book_link('Unknown Book', @context, format: :html)
    assert_equal '<cite class="book-title">Unknown Book</cite>', result
    refute_match(/<a href=/, result)
  end

  def test_render_unknown_book_markdown_returns_italic_only
    result = Utils.render_book_link('Unknown Book', @context, format: :markdown)
    assert_equal '*Unknown Book*', result
  end

  # --- render_book_link_from_data Tests ---

  def test_render_from_data_with_cite_default
    result = Utils.render_book_link_from_data('Dune', '/books/dune/', @context)
    assert_match %r{<a href="/books/dune/">}, result
    assert_match %r{<cite class="book-title">Dune</cite>}, result
  end

  def test_render_from_data_with_cite_false
    result = Utils.render_book_link_from_data('Dune', '/books/dune/', @context, cite: false)
    assert_match %r{<span class="book-text">Dune</span>}, result
    refute_match(/<cite/, result)
  end

  def test_render_from_data_with_format_markdown
    result = Utils.render_book_link_from_data('Dune', '/books/dune/', @context, format: :markdown)
    assert_equal '[*Dune*](/books/dune/)', result
  end

  def test_render_from_data_with_format_markdown_cite_false
    result = Utils.render_book_link_from_data('Dune', '/books/dune/', @context, cite: false, format: :markdown)
    assert_equal '[Dune](/books/dune/)', result
  end

  # --- Helper Method Tests ---

  def test_build_book_cite_element
    result = Utils._build_book_cite_element('Test Title')
    assert_equal '<cite class="book-title">Test Title</cite>', result
  end

  def test_build_book_text_element
    result = Utils._build_book_text_element('Test Title')
    assert_equal '<span class="book-text">Test Title</span>', result
  end

  def test_track_unreviewed_mention_delegates_to_resolver
    title = 'Unreviewed Book'
    mock_resolver = Minitest::Mock.new
    mock_resolver.expect :track_unreviewed_mention_explicit, nil, [title]

    Jekyll::Books::Core::BookLinkResolver.stub :new, mock_resolver do
      Utils._track_unreviewed_mention(@context, title)
    end

    mock_resolver.verify
  end
end
