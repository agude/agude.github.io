# frozen_string_literal: true

# _tests/plugins/utils/test_author_link_util.rb
require_relative '../../../test_helper'

# Tests for Jekyll::Authors::AuthorLinkUtils module.
#
# Verifies that the utility correctly creates links to author pages with support for pen names and possessives.
class TestAuthorLinkUtils < Minitest::Test
  def setup
    # --- Mock Author Pages ---
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

    # --- Site and Context ---
    @site = create_site({}, {}, [@canonical_author_page, @pen_name_author_page])
    @page = create_doc({}, '/current.html')
    @ctx = create_context({}, { site: @site, page: @page })
  end

  # --- New Alias-Specific Tests ---

  def test_render_author_link_with_pen_name_input
    # Input is "Pen Name", which is an alias for "Canonical Author"
    # Expect link to canonical page, but display text to be the input "Pen Name"
    expected = '<a href="/authors/canonical.html"><span class="author-name">Pen Name</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('Pen Name', @ctx)
  end

  def test_render_author_link_with_fuzzy_canonical_name_input
    # Input is a fuzzy match for "Canonical Author", not a pen name
    # Expect link to canonical page, and display text to be corrected to "Canonical Author"
    expected = '<a href="/authors/canonical.html"><span class="author-name">Canonical Author</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('canonical author', @ctx)
  end

  def test_render_author_link_with_pen_name_and_link_text_override
    # Input is "Pen Name", but link_text override is provided
    # Expect link to canonical page, but display text to be the override
    expected = '<a href="/authors/canonical.html"><span class="author-name">Display This</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('Pen Name', @ctx, 'Display This')
  end

  # --- Existing Tests (Adapted for new setup) ---
  def test_render_author_link_found_and_linked
    # Use the simple canonical author page for this test
    expected = '<a href="/authors/jane-doe.html"><span class="author-name">Jane Doe</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('  jane DOE ', @ctx)
  end

  def test_render_author_link_possessive_linked
    expected = '<a href="/authors/jane-doe.html"><span class="author-name">Jane Doe</span>’s</a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('jane doe', @ctx, nil, true)
  end

  def test_render_author_link_possessive_unlinked
    site_no_pages = create_site({}, {}, [])
    ctx_no_pages = create_context({}, { site: site_no_pages, page: @page })
    expected = '<span class="author-name">Jane Doe</span>’s'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('Jane Doe', ctx_no_pages, nil, true)
  end

  def test_render_author_link_not_found
    site_no_pages = create_site({}, {}, [])
    ctx_no_pages = create_context({}, { site: site_no_pages, page: @page })
    expected = '<span class="author-name">John Smith</span>'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('John Smith', ctx_no_pages)
  end

  def test_render_author_link_found_but_current_page
    # Current page IS the author page
    ctx_current_is_author = create_context({}, { site: @site, page: @canonical_author_page })
    expected = '<span class="author-name">Jane Doe</span>'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('Jane Doe', ctx_current_is_author)
  end

  def test_render_author_link_with_link_text_override_found
    expected = '<a href="/authors/jane-doe.html"><span class="author-name">JD</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('Jane Doe', @ctx, 'JD')
  end

  def test_render_author_link_with_link_text_override_not_found
    site_no_pages = create_site({}, {}, [])
    ctx_no_pages = create_context({}, { site: site_no_pages, page: @page })
    expected = '<span class="author-name">JD</span>'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('Jane Doe', ctx_no_pages, 'JD')
  end

  def test_render_author_link_possessive_with_override_linked
    expected = '<a href="/authors/jane-doe.html"><span class="author-name">JD</span>’s</a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('Jane Doe', @ctx, 'JD', true)
  end

  def test_render_author_link_possessive_with_override_unlinked
    site_no_pages = create_site({}, {}, [])
    ctx_no_pages = create_context({}, { site: site_no_pages, page: @page })
    expected = '<span class="author-name">JD</span>’s'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('Jane Doe', ctx_no_pages, 'JD', true)
  end

  def test_render_author_link_empty_input_name
    assert_equal '', Jekyll::Authors::AuthorLinkUtils.render_author_link('', @ctx)
    assert_equal '', Jekyll::Authors::AuthorLinkUtils.render_author_link('   ', @ctx)
    assert_equal '', Jekyll::Authors::AuthorLinkUtils.render_author_link(nil, @ctx)
  end

  def test_render_author_link_with_baseurl
    site_with_baseurl = create_site({ 'baseurl' => '/myblog' }, {}, [@canonical_author_page])
    ctx_with_baseurl = create_context({}, { site: site_with_baseurl, page: @page })
    expected = '<a href="/myblog/authors/jane-doe.html"><span class="author-name">Jane Doe</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('Jane Doe', ctx_with_baseurl)
  end

  def test_render_author_link_escaping_name
    author_page_escaped = create_doc(
      { 'title' => 'A & B <Company>', 'layout' => 'author_page' },
      '/authors/a-b.html'
    )
    site_escaped = create_site({}, {}, [author_page_escaped])
    ctx_escaped = create_context({}, { site: site_escaped, page: @page })
    expected = '<a href="/authors/a-b.html"><span class="author-name">A &amp; B &lt;Company&gt;</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('a & b <company>', ctx_escaped)
  end

  def test_render_author_link_escaping_override
    expected = '<a href="/authors/jane-doe.html"><span class="author-name">J &amp; D &lt;Inc&gt;</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('Jane Doe', @ctx, 'J & D <Inc>')
  end

  def test_render_author_link_uses_canonical_title_from_page
    author_page_fuzzy = create_doc(
      { 'title' => '  Jane   DOE ', 'layout' => 'author_page' },
      '/authors/jane-doe.html'
    )
    site_fuzzy = create_site({}, {}, [author_page_fuzzy])
    ctx_fuzzy = create_context({}, { site: site_fuzzy, page: @page })
    expected = '<a href="/authors/jane-doe.html"><span class="author-name">Jane   DOE</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('jane doe', ctx_fuzzy)
  end

  def test_render_author_link_lookup_is_case_insensitive_and_whitespace_normalized
    expected = '<a href="/authors/jane-doe.html"><span class="author-name">Jane Doe</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('jane doe', @ctx)
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('Jane  Doe', @ctx)
    assert_equal expected, Jekyll::Authors::AuthorLinkUtils.render_author_link('  jAnE dOe   ', @ctx)
  end
end
