# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/core/book_link_util'

# Tests for Jekyll::Books::Core::BookLinkUtils delegation.
#
# Verifies that the utility module correctly delegates to BookLinkResolver.
class TestBookLinkUtils < Minitest::Test
  def setup
    @context = create_context
  end

  def test_find_book_link_data_delegates_to_resolver
    title = 'Dune'
    override = 'The Dune Book'
    author = 'Frank Herbert'
    date_filter = nil
    mock_data = {
      status: :found,
      url: '/books/dune/',
      display_text: 'The Dune Book',
      canonical_title: 'Dune',
      cite: true,
    }

    mock_resolver = Minitest::Mock.new
    mock_resolver.expect :resolve_data, mock_data, [title, override, author, date_filter], cite: true

    Jekyll::Books::Core::BookLinkResolver.stub :new, mock_resolver do
      result = Jekyll::Books::Core::BookLinkUtils.find_book_link_data(title, @context, override, author)
      assert_equal mock_data, result
      assert_equal :found, result[:status]
    end

    mock_resolver.verify
  end

  def test_render_book_link_delegates_to_resolver_with_cite_default
    title = 'Dune'
    override = 'The Dune Book'
    author = 'Frank Herbert'
    date_filter = nil
    mock_output = '<a>Dune</a>'

    # Create a mock resolver instance
    mock_resolver = Minitest::Mock.new
    # Expect positional args plus cite: true keyword arg
    mock_resolver.expect :resolve, mock_output, [title, override, author, date_filter], cite: true

    # Stub .new to return the mock
    Jekyll::Books::Core::BookLinkResolver.stub :new, mock_resolver do
      result = Jekyll::Books::Core::BookLinkUtils.render_book_link(title, @context, override, author)
      assert_equal mock_output, result
    end

    mock_resolver.verify
  end

  def test_render_book_link_delegates_to_resolver_with_cite_false
    title = 'Dune'
    override = 'The Dune Book'
    author = 'Frank Herbert'
    date_filter = nil
    mock_output = '<a><span class="book-text">Dune</span></a>'

    # Create a mock resolver instance
    mock_resolver = Minitest::Mock.new
    # Expect positional args plus cite: false keyword arg
    mock_resolver.expect :resolve, mock_output, [title, override, author, date_filter], cite: false

    # Stub .new to return the mock
    Jekyll::Books::Core::BookLinkResolver.stub :new, mock_resolver do
      result = Jekyll::Books::Core::BookLinkUtils.render_book_link(title, @context, override, author, date_filter, cite: false)
      assert_equal mock_output, result
    end

    mock_resolver.verify
  end

  def test_render_book_link_from_data_with_cite_default
    title = 'Dune'
    url = '/books/dune'

    # Stub link helper to just return inner element for simplicity check
    Jekyll::Infrastructure::Links::LinkHelperUtils.stub :_generate_link_html, ->(_ctx, _url, inner) { inner } do
      result = Jekyll::Books::Core::BookLinkUtils.render_book_link_from_data(title, url, @context)
      assert_match %r{<cite class="book-title">Dune</cite>}, result
      refute_match(/book-text/, result)
    end
  end

  def test_render_book_link_from_data_with_cite_true_explicit
    title = 'Dune'
    url = '/books/dune'

    # Stub link helper to just return inner element for simplicity check
    Jekyll::Infrastructure::Links::LinkHelperUtils.stub :_generate_link_html, ->(_ctx, _url, inner) { inner } do
      result = Jekyll::Books::Core::BookLinkUtils.render_book_link_from_data(title, url, @context, cite: true)
      assert_match %r{<cite class="book-title">Dune</cite>}, result
      refute_match(/book-text/, result)
    end
  end

  def test_render_book_link_from_data_with_cite_false
    title = 'Dune'
    url = '/books/dune'

    # Stub link helper to just return inner element for simplicity check
    Jekyll::Infrastructure::Links::LinkHelperUtils.stub :_generate_link_html, ->(_ctx, _url, inner) { inner } do
      result = Jekyll::Books::Core::BookLinkUtils.render_book_link_from_data(title, url, @context, cite: false)
      assert_match %r{<span class="book-text">Dune</span>}, result
      refute_match(/<cite/, result)
    end
  end

  def test_build_book_cite_element
    result = Jekyll::Books::Core::BookLinkUtils._build_book_cite_element('Test Title')
    assert_equal '<cite class="book-title">Test Title</cite>', result
  end

  def test_build_book_text_element
    result = Jekyll::Books::Core::BookLinkUtils._build_book_text_element('Test Title')
    assert_equal '<span class="book-text">Test Title</span>', result
  end

  def test_track_unreviewed_mention_delegates_to_resolver
    title = 'Unreviewed Book'
    mock_resolver = Minitest::Mock.new
    mock_resolver.expect :track_unreviewed_mention_explicit, nil, [title]

    Jekyll::Books::Core::BookLinkResolver.stub :new, mock_resolver do
      Jekyll::Books::Core::BookLinkUtils._track_unreviewed_mention(@context, title)
    end

    mock_resolver.verify
  end
end
