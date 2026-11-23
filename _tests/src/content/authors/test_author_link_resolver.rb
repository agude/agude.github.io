# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::Authors::AuthorLinkResolver.
#
# Verifies that the resolver correctly creates links to author pages with support for pen names and possessives.
class TestAuthorLinkResolver < Minitest::Test
  def setup
    @canonical_author_page = create_doc(
      { 'title' => 'Jane Doe', 'layout' => 'author_page' },
      '/authors/jane-doe.html',
    )
    pen_name_author_page = create_doc(
      {
        'title' => 'Canonical Author',
        'layout' => 'author_page',
        'pen_names' => ['Pen Name', 'Another Alias'],
      },
      '/authors/canonical.html',
    )

    @site = create_site({}, {}, [@canonical_author_page, pen_name_author_page])
    @page = create_doc({}, '/current.html')
    @ctx = create_context({}, { site: @site, page: @page })
    @resolver = Jekyll::Authors::AuthorLinkResolver.new(@ctx)
  end

  def test_renders_markdown_link
    context = create_context({}, { site: @site, page: @page, render_mode: :markdown })
    template = Liquid::Template.parse('{% author_link "Pen Name" possessive %}')
    assert_equal "[Pen Name](/authors/canonical.html)'s", template.render!(context)
  end

  def test_render_author_link_with_fuzzy_canonical_name_input
    data = @resolver.resolve_data('canonical author', nil, nil)
    assert_equal [:found, '/authors/canonical.html', 'Canonical Author'], data.values_at(:status, :url, :display_text)
  end

  def test_render_author_link_with_pen_name_and_link_text_override
    data = @resolver.resolve_data('Pen Name', '  Display This  ', nil)
    assert_equal [:found, '/authors/canonical.html', 'Display This'], data.values_at(:status, :url, :display_text)
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

  def test_render_author_link_empty_input_name
    ['', '   ', nil].each { |input| assert_equal '', @resolver.resolve(input, nil, nil) }
  end

  def test_render_author_link_nil_context_returns_escaped_name
    resolver = Jekyll::Authors::AuthorLinkResolver.new(nil)
    assert_equal 'Jane Doe', resolver.resolve('Jane Doe', nil, nil)
    assert_equal '&lt;script&gt;', resolver.resolve('<script>', nil, nil)
  end

  def test_render_author_link_with_baseurl
    @site.config['baseurl'] = '/myblog'
    actual = Liquid::Template.parse('{% author_link "Jane Doe" link_text="JD" possessive %}').render!(@ctx)
    expected = '<a href="/myblog/authors/jane-doe.html"><span class="author-name">JD</span>’s</a>'
    assert_equal expected, actual
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
    ['jane doe', 'Jane  Doe', '  jAnE dOe   '].each do |input|
      data = @resolver.resolve_data(input, nil, nil)
      assert_equal [:found, '/authors/jane-doe.html', 'Jane Doe'], data.values_at(:status, :url, :display_text)
    end
  end

  def test_lookup_preserves_punctuation_and_diacritics
    author = create_doc({ 'title' => "Áine O'Neill", 'layout' => 'author_page' }, '/authors/oneill/')
    site = create_site({}, {}, [author])
    context = create_context({}, { site: site, page: @page })
    resolver = Jekyll::Authors::AuthorLinkResolver.new(context)

    data = resolver.resolve_data("  ÁINE  O'NEILL ", nil, nil)
    assert_equal [:found, '/authors/oneill/', "Áine O'Neill"], data.values_at(:status, :url, :display_text)
    assert_equal :not_found, resolver.resolve_data("Aine O'Neill", nil, nil)[:status]
    assert_equal :not_found, resolver.resolve_data('Áine ONeill', nil, nil)[:status]
  end

  def test_resolve_empty_name_includes_log_output_when_logging_enabled
    site_with_logging = create_site({}, {}, [@canonical_author_page])
    site_with_logging.config['plugin_logging']['RENDER_AUTHOR_LINK'] = true
    ctx_logging = create_context({}, { site: site_with_logging, page: @page })

    output = Jekyll.stub(:logger, silent_logger) do
      Jekyll::Authors::AuthorLinkResolver.new(ctx_logging).resolve('', nil, nil)
    end
    assert_match(/<!-- \[WARN\] RENDER_AUTHOR_LINK_FAILURE:.*?empty after normalization.*?-->/, output)
  end

  def test_resolve_data_found
    data = Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve_data('Jane Doe', nil, nil)
    assert_equal :found, data[:status]
    assert_equal '/authors/jane-doe.html', data[:url]
    assert_equal 'Jane Doe', data[:display_text]
    assert_equal false, data[:possessive]
  end

  def test_resolve_data_found_possessive
    data = @resolver.resolve_data('Jane Doe', nil, true)
    assert_equal [:found, '/authors/jane-doe.html', 'Jane Doe', true], data.values_at(:status, :url, :display_text, :possessive)
    refute @resolver.resolve_data('Jane Doe', nil, nil)[:possessive]
  end

  def test_resolve_data_not_found
    data = @resolver.resolve_data('John Smith', nil, nil)
    assert_equal [:not_found, nil, 'John Smith', false], data.values_at(:status, :url, :display_text, :possessive)

    overridden = @resolver.resolve_data('John Smith', 'JD', true)
    assert_equal [:not_found, nil, 'JD', true], overridden.values_at(:status, :url, :display_text, :possessive)
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

  def test_resolve_link_false_possessive
    output = Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve('Jane Doe', nil, true, link: false)
    assert_equal "<span class=\"author-name\">Jane Doe</span>\u2019s", output
  end

  def test_resolve_data_link_false_nullifies_url
    data = Jekyll::Authors::AuthorLinkResolver.new(@ctx).resolve_data('Jane Doe', nil, nil, link: false)
    assert_equal :found, data[:status]
    assert_nil data[:url]
    assert_equal 'Jane Doe', data[:display_text]
  end
end
