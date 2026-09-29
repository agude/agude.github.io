# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/tags/display_books_by_title_alpha_group_tag'

# Tests for Jekyll::Books::Tags::DisplayBooksByTitleAlphaGroupTag Liquid tag.
#
# Verifies the tag's Liquid syntax and rendered output.
class TestDisplayBooksByTitleAlphaGroupTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({}, { site: @site })
  end

  def test_syntax_error_if_arguments_provided
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_books_by_title_alpha_group some_arg %}')
    end
    assert_match 'This tag does not accept any arguments', err.message
  end

  def test_html_mode_renders_book_groups
    book = create_doc({ 'title' => 'Dune', 'book_authors' => ['Frank Herbert'] }, '/books/dune.html')
    site = create_site({}, { 'books' => [book] })
    context = create_context({}, { site: site })

    output = Liquid::Template.parse('{% display_books_by_title_alpha_group %}').render!(context)

    assert_includes output, 'Dune'
    assert_includes output, 'D'
  end

  # --- Markdown render mode ---

  def test_markdown_mode_outputs_book_list
    books = [
      create_doc(
        {
          'title' => 'Dune',
          'book_authors' => ['Frank Herbert'],
          'rating' => 5,
        },
        '/books/dune.html',
      ),
      create_doc(
        {
          'title' => 'Hyperion',
          'book_authors' => ['Dan Simmons'],
          'rating' => 5,
        },
        '/books/hyperion.html',
      ),
    ]
    site = create_site({ 'url' => 'http://example.com' }, { 'books' => books })
    md_context = create_context(
      {},
      { site: site, page: create_doc({ 'path' => 'test.html' }, '/test.html'), render_mode: :markdown },
    )
    silent_logger = Object.new.tap do |l|
      def l.warn(*, **); end
      def l.error(*, **); end
      def l.info(*, **); end
      def l.debug(*, **); end
    end
    output = ''
    Jekyll.stub :logger, silent_logger do
      output = Liquid::Template.parse('{% display_books_by_title_alpha_group %}').render!(md_context)
    end
    assert_includes output, '## D'
    assert_includes output, '[_Dune_](/books/dune.html)'
    assert_includes output, '## H'
    assert_includes output, '[_Hyperion_](/books/hyperion.html)'
    refute_includes output, '<div'
  end
end
