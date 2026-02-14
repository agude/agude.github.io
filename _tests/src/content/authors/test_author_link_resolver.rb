# frozen_string_literal: true

# _tests/src/content/authors/test_author_link_resolver.rb
require_relative '../../../test_helper'

# Tests for Jekyll::Authors::AuthorLinkResolver.
#
# Verifies that the resolver correctly creates links to author pages with support for pen names and possessives.
class TestAuthorLinkResolver < Minitest::Test
  def setup
    # --- Mock Author Pages ---
    @canonical_author_page = create_doc(
      { 'title' => 'Jane Doe', 'layout' => 'author_page' },
      '/authors/jane-doe.html',
    )
    @pen_name_author_page = create_doc(
      {
        'title' => 'Canonical Author',
        'layout' => 'author_page',
        'pen_names' => ['Pen Name', 'Another Alias'],
      },
      '/authors/canonical.html',
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
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve('Pen Name', nil, nil)
  end

  def test_render_author_link_with_fuzzy_canonical_name_input
    # Input is a fuzzy match for "Canonical Author", not a pen name
    # Expect link to canonical page, and display text to be corrected to "Canonical Author"
    expected = '<a href="/authors/canonical.html"><span class="author-name">Canonical Author</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve('canonical author', nil, nil)
  end

  def test_render_author_link_with_pen_name_and_link_text_override
    # Input is "Pen Name", but link_text override is provided
    # Expect link to canonical page, but display text to be the override
    expected = '<a href="/authors/canonical.html"><span class="author-name">Display This</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve('Pen Name', 'Display This', nil)
  end

  # --- Existing Tests (Adapted for new setup) ---
  def test_render_author_link_found_and_linked
    # Use the simple canonical author page for this test
    expected = '<a href="/authors/jane-doe.html"><span class="author-name">Jane Doe</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve('  jane DOE ', nil, nil)
  end

  def test_render_author_link_possessive_linked
    expected = '<a href="/authors/jane-doe.html"><span class="author-name">Jane Doe</span>’s</a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve('jane doe', nil, true)
  end

  def test_render_author_link_possessive_unlinked
    site_no_pages = create_site({}, {}, [])
    ctx_no_pages = create_context({}, { site: site_no_pages, page: @page })
    expected = '<span class="author-name">Jane Doe</span>’s'
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(ctx_no_pages).resolve('Jane Doe', nil, true)
  end

  def test_render_author_link_not_found
    site_no_pages = create_site({}, {}, [])
    ctx_no_pages = create_context({}, { site: site_no_pages, page: @page })
    expected = '<span class="author-name">John Smith</span>'
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(ctx_no_pages).resolve('John Smith', nil, nil)
  end

  def test_render_author_link_found_but_current_page
    # Current page IS the author page
    ctx_current_is_author = create_context({}, { site: @site, page: @canonical_author_page })
    expected = '<span class="author-name">Jane Doe</span>'
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(ctx_current_is_author).resolve('Jane Doe', nil, nil)
  end

  def test_render_author_link_with_link_text_override_found
    expected = '<a href="/authors/jane-doe.html"><span class="author-name">JD</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve('Jane Doe', 'JD', nil)
  end

  def test_render_author_link_with_link_text_override_not_found
    site_no_pages = create_site({}, {}, [])
    ctx_no_pages = create_context({}, { site: site_no_pages, page: @page })
    expected = '<span class="author-name">JD</span>'
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(ctx_no_pages).resolve('Jane Doe', 'JD', nil)
  end

  def test_render_author_link_possessive_with_override_linked
    expected = '<a href="/authors/jane-doe.html"><span class="author-name">JD</span>’s</a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve('Jane Doe', 'JD', true)
  end

  def test_render_author_link_possessive_with_override_unlinked
    site_no_pages = create_site({}, {}, [])
    ctx_no_pages = create_context({}, { site: site_no_pages, page: @page })
    expected = '<span class="author-name">JD</span>’s'
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(ctx_no_pages).resolve('Jane Doe', 'JD', true)
  end

  def test_render_author_link_empty_input_name
    assert_equal '', Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve('', nil, nil)
    assert_equal '', Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve('   ', nil, nil)
    assert_equal '', Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve(nil, nil, nil)
  end

  def test_render_author_link_nil_context_returns_escaped_name
    resolver = Jekyll::Authors::AuthorLinkResolver.new(nil)
    assert_equal 'Jane Doe', resolver.resolve('Jane Doe', nil, nil)
    assert_equal '&lt;script&gt;', resolver.resolve('<script>', nil, nil)
  end

  def test_render_author_link_with_baseurl
    site_with_baseurl = create_site({ 'baseurl' => '/myblog' }, {}, [@canonical_author_page])
    ctx_with_baseurl = create_context({}, { site: site_with_baseurl, page: @page })
    expected = '<a href="/myblog/authors/jane-doe.html"><span class="author-name">Jane Doe</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(ctx_with_baseurl).resolve('Jane Doe', nil, nil)
  end

  def test_render_author_link_escaping_name
    author_page_escaped = create_doc(
      { 'title' => 'A & B <Company>', 'layout' => 'author_page' },
      '/authors/a-b.html',
    )
    site_escaped = create_site({}, {}, [author_page_escaped])
    ctx_escaped = create_context({}, { site: site_escaped, page: @page })
    expected = '<a href="/authors/a-b.html"><span class="author-name">A &amp; B &lt;Company&gt;</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(ctx_escaped).resolve('a & b <company>', nil, nil)
  end

  def test_render_author_link_escaping_override
    expected = '<a href="/authors/jane-doe.html"><span class="author-name">J &amp; D &lt;Inc&gt;</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve('Jane Doe', 'J & D <Inc>', nil)
  end

  def test_render_author_link_uses_canonical_title_from_page
    author_page_fuzzy = create_doc(
      { 'title' => '  Jane   DOE ', 'layout' => 'author_page' },
      '/authors/jane-doe.html',
    )
    site_fuzzy = create_site({}, {}, [author_page_fuzzy])
    ctx_fuzzy = create_context({}, { site: site_fuzzy, page: @page })
    expected = '<a href="/authors/jane-doe.html"><span class="author-name">Jane   DOE</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(ctx_fuzzy).resolve('jane doe', nil, nil)
  end

  def test_render_author_link_lookup_is_case_insensitive_and_whitespace_normalized
    expected = '<a href="/authors/jane-doe.html"><span class="author-name">Jane Doe</span></a>'
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve('jane doe', nil, nil)
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve('Jane  Doe', nil, nil)
    assert_equal expected, Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve('  jAnE dOe   ', nil, nil)
  end

  # --- resolve() log capture regression tests ---

  def test_resolve_empty_name_includes_log_output_when_logging_enabled
    site_with_logging = create_site({}, {}, [@canonical_author_page])
    site_with_logging.config['plugin_logging']['RENDER_AUTHOR_LINK'] = true
    ctx_logging = create_context({}, { site: site_with_logging, page: @page })

    silent_logger = Object.new
    def silent_logger.warn(_topic, _message); end
    def silent_logger.info(_topic, _message); end

    output = Jekyll.stub(:logger, silent_logger) do
      Jekyll::Authors::AuthorLinkResolver.new(ctx_logging).resolve('', nil, nil)
    end
    assert_match(/<!-- \[WARN\] RENDER_AUTHOR_LINK_FAILURE:.*?empty after normalization.*?-->/, output)
  end

  # --- resolve_data() tests ---

  def test_resolve_data_found
    data = Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve_data('Jane Doe', nil, nil)
    assert_equal :found, data[:status]
    assert_equal '/authors/jane-doe.html', data[:url]
    assert_equal 'Jane Doe', data[:display_text]
    assert_equal false, data[:possessive]
  end

  def test_resolve_data_found_possessive
    data = Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve_data('Jane Doe', nil, true)
    assert_equal :found, data[:status]
    assert_equal '/authors/jane-doe.html', data[:url]
    assert_equal 'Jane Doe', data[:display_text]
    assert_equal true, data[:possessive]
  end

  def test_resolve_data_not_found
    site_no_pages = create_site({}, {}, [])
    ctx_no_pages = create_context({}, { site: site_no_pages, page: @page })
    data = Jekyll::Authors::AuthorLinkResolver.new(ctx_no_pages).resolve_data('John Smith', nil, nil)
    assert_equal :not_found, data[:status]
    assert_nil data[:url]
    assert_equal 'John Smith', data[:display_text]
    assert_equal false, data[:possessive]
  end

  def test_resolve_data_empty_name
    data = Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve_data('', nil, nil)
    assert_equal :empty_name, data[:status]
    assert_nil data[:url]
    assert_nil data[:display_text]
    assert_nil data[:possessive]
  end

  def test_resolve_data_no_site
    resolver = Jekyll::Authors::AuthorLinkResolver.new(nil)
    data = resolver.resolve_data('Jane Doe', nil, nil)
    assert_equal :no_site, data[:status]
    assert_nil data[:url]
    assert_equal 'Jane Doe', data[:display_text]
    assert_nil data[:possessive]
  end

  def test_resolve_data_with_override
    data = Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve_data('Jane Doe', 'JD', nil)
    assert_equal :found, data[:status]
    assert_equal '/authors/jane-doe.html', data[:url]
    assert_equal 'JD', data[:display_text]
  end

  def test_resolve_data_pen_name
    data = Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve_data('Pen Name', nil, nil)
    assert_equal :found, data[:status]
    assert_equal '/authors/canonical.html', data[:url]
    assert_equal 'Pen Name', data[:display_text]
  end

  def test_resolve_data_frozen
    data = Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve_data('Jane Doe', nil, nil)
    assert data.frozen?, 'resolve_data() should return a frozen hash'
  end
end
