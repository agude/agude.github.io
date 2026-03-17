# frozen_string_literal: true

# _tests/src/infrastructure/links/test_link_resolver_support.rb
require_relative '../../../test_helper'

# A minimal test resolver that includes LinkResolverSupport to verify
# the shared helpers work correctly in isolation.
class TestResolverStub
  include Jekyll::Infrastructure::Links::LinkResolverSupport

  # Expose private helpers for testing
  public :find_in_cache, :wrap_with_link, :log_failure

  attr_reader :context, :site, :log_output
end

# Tests for Jekyll::Infrastructure::Links::LinkResolverSupport.
class TestLinkResolverSupport < Minitest::Test
  def setup
    @page = create_doc({}, '/current.html')
    @author_page = create_doc(
      { 'title' => 'Jane Doe', 'layout' => 'author_page' },
      '/authors/jane-doe.html',
    )
    @site = create_site({}, {}, [@author_page])
    @ctx = create_context({}, { site: @site, page: @page })
  end

  # --- initialize ---

  def test_initialize_sets_context_and_site
    resolver = TestResolverStub.new(@ctx)
    assert_equal @ctx, resolver.context
    assert_equal @site, resolver.site
    assert_equal '', resolver.log_output
  end

  def test_initialize_with_nil_context
    resolver = TestResolverStub.new(nil)
    assert_nil resolver.context
    assert_nil resolver.site
    assert_equal '', resolver.log_output
  end

  # --- find_in_cache ---

  def test_find_in_cache_returns_entry_when_present
    resolver = TestResolverStub.new(@ctx)
    result = resolver.find_in_cache('authors', 'jane doe')
    assert_equal 'Jane Doe', result['title']
    assert_equal '/authors/jane-doe.html', result['url']
  end

  def test_find_in_cache_returns_nil_when_missing
    resolver = TestResolverStub.new(@ctx)
    assert_nil resolver.find_in_cache('authors', 'nonexistent')
  end

  def test_find_in_cache_returns_nil_for_missing_section
    resolver = TestResolverStub.new(@ctx)
    assert_nil resolver.find_in_cache('nonexistent_section', 'key')
  end

  # --- wrap_with_link ---

  def test_wrap_with_link_generates_anchor_tag
    resolver = TestResolverStub.new(@ctx)
    html = resolver.wrap_with_link('<span>Test</span>', '/some/url.html')
    assert_equal '<a href="/some/url.html"><span>Test</span></a>', html
  end

  def test_wrap_with_link_returns_inner_html_when_url_empty
    resolver = TestResolverStub.new(@ctx)
    html = resolver.wrap_with_link('<span>Test</span>', '')
    assert_equal '<span>Test</span>', html
  end

  def test_wrap_with_link_returns_inner_html_when_url_nil
    resolver = TestResolverStub.new(@ctx)
    html = resolver.wrap_with_link('<span>Test</span>', nil)
    assert_equal '<span>Test</span>', html
  end

  # --- log_failure ---

  def test_log_failure_returns_empty_string_when_logging_disabled
    resolver = TestResolverStub.new(@ctx)
    result = resolver.log_failure(
      tag_type: 'RENDER_AUTHOR_LINK',
      reason: 'Test reason.',
      identifiers: { Name: 'test' },
      level: :info,
    )
    # Logging is disabled in test config, so result should be empty
    assert_equal '', result
  end

  def test_log_failure_returns_html_comment_when_logging_enabled
    site_with_logging = create_site({}, {}, [@author_page])
    site_with_logging.config['plugin_logging']['RENDER_AUTHOR_LINK'] = true
    ctx_logging = create_context({}, { site: site_with_logging, page: @page })

    resolver = TestResolverStub.new(ctx_logging)
    output = Jekyll.stub(:logger, silent_logger) do
      resolver.log_failure(
        tag_type: 'RENDER_AUTHOR_LINK',
        reason: 'Test reason.',
        identifiers: { Name: 'test' },
        level: :info,
      )
    end
    assert_match(/<!-- \[INFO\] RENDER_AUTHOR_LINK_FAILURE:.*?Test reason\..*?-->/, output)
  end

  # --- Constants accessible from includer ---

  def test_text_constant_available
    resolver = TestResolverStub.new(@ctx)
    # Text.normalize_title should be accessible via the mixin constant
    assert_equal 'hello world', resolver.class.const_get(:Text).normalize_title('  Hello   World  ')
  end
end
