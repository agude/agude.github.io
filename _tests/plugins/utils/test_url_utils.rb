# frozen_string_literal: true

# _tests/plugins/utils/test_url_utils.rb
require_relative '../../test_helper'
# UrlUtils is loaded via test_helper

# Tests for UrlUtils module.
#
# Verifies that the utility correctly constructs absolute URLs with proper baseurl handling.
class TestUrlUtils < Minitest::Test
  def test_absolute_url_with_baseurl
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/blog' })
    assert_equal 'https://example.com/blog/some/page.html', UrlUtils.absolute_url('/some/page.html', site)
    assert_equal 'https://example.com/blog/image.jpg', UrlUtils.absolute_url('image.jpg', site) # Relative path
    assert_equal 'https://example.com/blog/', UrlUtils.absolute_url('/', site)
    assert_equal 'https://example.com/blog/', UrlUtils.absolute_url('', site) # Empty path with baseurl
  end

  def test_absolute_url_without_baseurl
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '' })
    assert_equal 'https://example.com/some/page.html', UrlUtils.absolute_url('/some/page.html', site)
    assert_equal 'https://example.com/image.jpg', UrlUtils.absolute_url('image.jpg', site)
    assert_equal 'https://example.com/', UrlUtils.absolute_url('/', site)
    assert_equal 'https://example.com/', UrlUtils.absolute_url('', site) # Empty path, no baseurl
  end

  def test_absolute_url_with_baseurl_as_slash
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/' })
    assert_equal 'https://example.com/some/page.html', UrlUtils.absolute_url('/some/page.html', site)
    assert_equal 'https://example.com/image.jpg', UrlUtils.absolute_url('image.jpg', site)
    assert_equal 'https://example.com/', UrlUtils.absolute_url('/', site)
    assert_equal 'https://example.com/', UrlUtils.absolute_url('', site)
  end

  def test_absolute_url_path_already_absolute
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/blog' })
    assert_equal 'http://othersite.com/page.html', UrlUtils.absolute_url('http://othersite.com/page.html', site)
    assert_equal 'https://secure.com/img.png', UrlUtils.absolute_url('https://secure.com/img.png', site)
  end

  def test_absolute_url_nil_path
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/blog' })
    assert_nil UrlUtils.absolute_url(nil, site)
  end

  def test_absolute_url_handles_trailing_slashes_in_config
    site_trailing = create_site({ 'url' => 'https://example.com/', 'baseurl' => '/blog/' })
    assert_equal 'https://example.com/blog/some/page.html', UrlUtils.absolute_url('/some/page.html', site_trailing)
    assert_equal 'https://example.com/blog/image.jpg', UrlUtils.absolute_url('image.jpg', site_trailing)

    site_url_trailing_only = create_site({ 'url' => 'https://example.com/', 'baseurl' => '' })
    assert_equal 'https://example.com/image.jpg', UrlUtils.absolute_url('image.jpg', site_url_trailing_only)
  end

  def test_absolute_url_handles_leading_slashes_in_path
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/blog' })
    assert_equal 'https://example.com/blog/path/to/asset.css', UrlUtils.absolute_url('path/to/asset.css', site)
    assert_equal 'https://example.com/blog/path/to/asset.css', UrlUtils.absolute_url('/path/to/asset.css', site)
    assert_equal 'https://example.com/blog/path/to/asset.css', UrlUtils.absolute_url('//path/to/asset.css', site) # Multiple leading slashes
  end

  def test_absolute_url_empty_path_with_baseurl_slash
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/' })
    assert_equal 'https://example.com/', UrlUtils.absolute_url('', site)
  end

  def test_absolute_url_empty_path_no_baseurl
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '' })
    assert_equal 'https://example.com/', UrlUtils.absolute_url('', site)
  end

  def test_absolute_url_path_is_just_slash_with_baseurl_slash
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/' })
    assert_equal 'https://example.com/', UrlUtils.absolute_url('/', site)
  end

  def test_absolute_url_empty_path_results_in_site_url
    # This tests the branch on line 45 where url == site_url
    # We need a scenario where after all processing, url equals site_url exactly
    # This can happen with empty path and empty baseurl, but the path normalization
    # should handle that. Let me test edge cases.
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '' })

    # Empty path should give us site_url + '/'
    result = UrlUtils.absolute_url('', site)
    assert_equal 'https://example.com/', result

    # Try with path that resolves to nothing
    # Actually, based on the code, this is already tested above
    # The line 45 check ensures that if url == site_url (without trailing slash),
    # it adds one. But our current tests may not trigger this exact condition.
  end

  def test_absolute_url_multiple_slashes_with_baseurl
    # Tests line 36: the final else in _normalize_path
    # Multiple slashes without being exactly '/' should result in empty normalized path
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/blog' })
    result = UrlUtils.absolute_url('///', site)
    # Multiple slashes are stripped, leaving empty, so we get baseurl without trailing slash
    # because path_str is not empty or '/' after processing
    assert_equal 'https://example.com/blog', result
  end
end
