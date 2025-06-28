# _tests/plugins/utils/test_author_finder_utils.rb
require_relative '../../test_helper'
require_relative '../../../_plugins/utils/author_finder_utils'

class TestAuthorFinderUtils < Minitest::Test
  def setup
    # --- Mock Author Pages ---
    @page_canonical = create_doc(
      { 'title' => 'Canonical Author', 'layout' => 'author_page' },
      '/authors/canonical.html'
    )
    @page_with_pen_names = create_doc(
      {
        'title' => 'Real Name',
        'layout' => 'author_page',
        'pen_names' => ['Pen Name One', 'Alias Two']
      },
      '/authors/real-name.html'
    )
    @page_not_author = create_doc(
      { 'title' => 'Not An Author', 'layout' => 'post' }, # Wrong layout
      '/posts/not-author.html'
    )

    @all_pages = [@page_canonical, @page_with_pen_names, @page_not_author]
    @site = create_site({}, {}, @all_pages)
  end

  def test_find_by_canonical_name
    found_page = AuthorFinderUtils.find_author_page_by_name('Canonical Author', @site)
    assert_equal @page_canonical, found_page
  end

  def test_find_by_canonical_name_case_insensitive
    found_page = AuthorFinderUtils.find_author_page_by_name('canonical author', @site)
    assert_equal @page_canonical, found_page
  end

  def test_find_by_pen_name
    found_page = AuthorFinderUtils.find_author_page_by_name('Pen Name One', @site)
    assert_equal @page_with_pen_names, found_page
  end

  def test_find_by_second_pen_name_case_insensitive
    found_page = AuthorFinderUtils.find_author_page_by_name('alias two', @site)
    assert_equal @page_with_pen_names, found_page
  end

  def test_returns_nil_if_name_not_found
    found_page = AuthorFinderUtils.find_author_page_by_name('NonExistent Author', @site)
    assert_nil found_page
  end

  def test_returns_nil_for_page_with_wrong_layout
    # The name matches, but the layout is wrong, so it should not be found.
    found_page = AuthorFinderUtils.find_author_page_by_name('Not An Author', @site)
    assert_nil found_page
  end

  def test_returns_nil_for_empty_or_nil_name
    assert_nil AuthorFinderUtils.find_author_page_by_name('', @site)
    assert_nil AuthorFinderUtils.find_author_page_by_name('   ', @site)
    assert_nil AuthorFinderUtils.find_author_page_by_name(nil, @site)
  end

  def test_finds_first_match_if_duplicate_definition_exists
    # This tests the behavior if, by mistake, a name is defined on multiple pages.
    # `site.pages.find` will return the first one it encounters.
    duplicate_page = create_doc(
      { 'title' => 'Another Page', 'layout' => 'author_page', 'pen_names' => ['Pen Name One'] },
      '/authors/another.html'
    )
    @site.pages << duplicate_page # Add the duplicate to the end of the list

    found_page = AuthorFinderUtils.find_author_page_by_name('Pen Name One', @site)
    # It should find the first one in the array, which is @page_with_pen_names
    assert_equal @page_with_pen_names, found_page
  end
end
