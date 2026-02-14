# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::Authors::AuthorLinkFinder
#
# The AuthorLinkFinder locates author data without any formatting.
# It returns a data hash that can be passed to a formatter.
class TestAuthorLinkFinder < Minitest::Test
  Finder = Jekyll::Authors::AuthorLinkFinder

  def setup
    # Create author pages
    @canonical_author_page = create_doc(
      { 'title' => 'Jane Doe', 'layout' => 'author_page' },
      '/authors/jane-doe.html'
    )
    @pen_name_author_page = create_doc(
      {
        'title' => 'Canonical Author',
        'layout' => 'author_page',
        'pen_names' => ['Pen Name', 'Another Alias']
      },
      '/authors/canonical.html'
    )

    @site = create_site({}, {}, [@canonical_author_page, @pen_name_author_page])
    @page = create_doc({}, '/current.html')
    @context = create_context({}, { site: @site, page: @page })
  end

  # --- Finding Authors ---

  def test_find_returns_data_for_existing_author
    result = Finder.new(@context).find('Jane Doe')

    assert result[:found]
    assert_equal 'Jane Doe', result[:display_name]
    assert_equal '/authors/jane-doe.html', result[:url]
  end

  def test_find_normalizes_input_name
    result = Finder.new(@context).find('  jane DOE  ')

    assert result[:found]
    assert_equal 'Jane Doe', result[:display_name]
  end

  def test_find_returns_not_found_for_unknown_author
    result = Finder.new(@context).find('Unknown Author')

    refute result[:found]
    assert_equal 'Unknown Author', result[:display_name]
    assert_nil result[:url]
  end

  def test_find_returns_input_as_display_name_when_not_found
    result = Finder.new(@context).find('Some Random Name')

    refute result[:found]
    assert_equal 'Some Random Name', result[:display_name]
  end

  # --- Pen Names ---

  def test_find_resolves_pen_name_to_canonical_url
    result = Finder.new(@context).find('Pen Name')

    assert result[:found]
    assert_equal '/authors/canonical.html', result[:url]
  end

  def test_find_uses_pen_name_as_display_when_searching_by_pen_name
    result = Finder.new(@context).find('Pen Name')

    assert result[:found]
    # Display name should be the input (pen name), not canonical
    assert_equal 'Pen Name', result[:display_name]
  end

  def test_find_uses_canonical_name_when_searching_by_canonical
    result = Finder.new(@context).find('canonical author')

    assert result[:found]
    assert_equal 'Canonical Author', result[:display_name]
  end

  # --- Override Text ---

  def test_find_with_override_uses_override_as_display_name
    result = Finder.new(@context).find('Jane Doe', override: 'JD')

    assert result[:found]
    assert_equal 'JD', result[:display_name]
    assert_equal '/authors/jane-doe.html', result[:url]
  end

  def test_find_with_override_for_unknown_author
    result = Finder.new(@context).find('Unknown', override: 'Custom Text')

    refute result[:found]
    assert_equal 'Custom Text', result[:display_name]
  end

  # --- Possessive ---

  def test_find_with_possessive_flag
    result = Finder.new(@context).find('Jane Doe', possessive: true)

    assert result[:found]
    assert result[:possessive]
  end

  def test_find_without_possessive_flag
    result = Finder.new(@context).find('Jane Doe')

    refute result[:possessive]
  end

  # --- Edge Cases ---

  def test_find_with_empty_name_returns_empty_result
    result = Finder.new(@context).find('')

    refute result[:found]
    assert_equal '', result[:display_name]
  end

  def test_find_with_nil_name_returns_empty_result
    result = Finder.new(@context).find(nil)

    refute result[:found]
  end

  def test_find_with_nil_context
    result = Finder.new(nil).find('Jane Doe')

    refute result[:found]
    assert_equal 'Jane Doe', result[:display_name]
  end

  # --- Current Page Detection ---

  def test_find_marks_current_page_when_on_author_page
    ctx_on_author_page = create_context({}, { site: @site, page: @canonical_author_page })
    result = Finder.new(ctx_on_author_page).find('Jane Doe')

    assert result[:found]
    assert result[:is_current_page]
  end

  def test_find_does_not_mark_current_page_for_different_author
    ctx_on_author_page = create_context({}, { site: @site, page: @canonical_author_page })
    result = Finder.new(ctx_on_author_page).find('Canonical Author')

    assert result[:found]
    refute result[:is_current_page]
  end
end
