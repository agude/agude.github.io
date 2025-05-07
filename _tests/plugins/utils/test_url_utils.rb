# _tests/plugins/utils/test_url_utils.rb
require_relative '../../test_helper'
# UrlUtils is loaded via test_helper

class TestUrlUtils < Minitest::Test

  def test_absolute_url_with_baseurl
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/blog' })
    assert_equal "https://example.com/blog/some/page.html", UrlUtils.absolute_url("/some/page.html", site)
    assert_equal "https://example.com/blog/image.jpg", UrlUtils.absolute_url("image.jpg", site) # Relative path
    assert_equal "https://example.com/blog/", UrlUtils.absolute_url("/", site)
    assert_equal "https://example.com/blog/", UrlUtils.absolute_url("", site) # Empty path with baseurl
  end

  def test_absolute_url_without_baseurl
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '' })
    assert_equal "https://example.com/some/page.html", UrlUtils.absolute_url("/some/page.html", site)
    assert_equal "https://example.com/image.jpg", UrlUtils.absolute_url("image.jpg", site)
    assert_equal "https://example.com/", UrlUtils.absolute_url("/", site)
    assert_equal "https://example.com/", UrlUtils.absolute_url("", site) # Empty path, no baseurl
  end

  def test_absolute_url_with_baseurl_as_slash
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/' })
    assert_equal "https://example.com/some/page.html", UrlUtils.absolute_url("/some/page.html", site)
    assert_equal "https://example.com/image.jpg", UrlUtils.absolute_url("image.jpg", site)
    assert_equal "https://example.com/", UrlUtils.absolute_url("/", site)
    assert_equal "https://example.com/", UrlUtils.absolute_url("", site)
  end

  def test_absolute_url_path_already_absolute
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/blog' })
    assert_equal "http://othersite.com/page.html", UrlUtils.absolute_url("http://othersite.com/page.html", site)
    assert_equal "https://secure.com/img.png", UrlUtils.absolute_url("https://secure.com/img.png", site)
  end

  def test_absolute_url_nil_path
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/blog' })
    assert_nil UrlUtils.absolute_url(nil, site)
  end

  def test_absolute_url_handles_trailing_slashes_in_config
    site_trailing = create_site({ 'url' => 'https://example.com/', 'baseurl' => '/blog/' })
    assert_equal "https://example.com/blog/some/page.html", UrlUtils.absolute_url("/some/page.html", site_trailing)
    assert_equal "https://example.com/blog/image.jpg", UrlUtils.absolute_url("image.jpg", site_trailing)

    site_url_trailing_only = create_site({ 'url' => 'https://example.com/', 'baseurl' => '' })
    assert_equal "https://example.com/image.jpg", UrlUtils.absolute_url("image.jpg", site_url_trailing_only)
  end

  def test_absolute_url_handles_leading_slashes_in_path
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/blog' })
    assert_equal "https://example.com/blog/path/to/asset.css", UrlUtils.absolute_url("path/to/asset.css", site)
    assert_equal "https://example.com/blog/path/to/asset.css", UrlUtils.absolute_url("/path/to/asset.css", site)
    assert_equal "https://example.com/blog/path/to/asset.css", UrlUtils.absolute_url("//path/to/asset.css", site) # Multiple leading slashes
  end

  def test_absolute_url_empty_path_with_baseurl_slash
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/' })
    assert_equal "https://example.com/", UrlUtils.absolute_url("", site)
  end

  def test_absolute_url_empty_path_no_baseurl
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '' })
    assert_equal "https://example.com/", UrlUtils.absolute_url("", site)
  end

  def test_absolute_url_path_is_just_slash_with_baseurl_slash
    site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/' })
    assert_equal "https://example.com/", UrlUtils.absolute_url("/", site)
  end
end
