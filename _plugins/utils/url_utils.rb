# frozen_string_literal: true

# _plugins/utils/url_utils.rb

module UrlUtils
  def self.absolute_url(path, site)
    return nil if path.nil?

    path_str = path.to_s
    return path_str if path_str.start_with?('http://', 'https://')

    site_url = site.config['url'].to_s.chomp('/')
    baseurl  = site.config['baseurl'].to_s
    normalized_baseurl = _normalize_baseurl(baseurl)
    normalized_path = _normalize_path(path_str, normalized_baseurl, site_url)
    return normalized_path if normalized_path.start_with?('http')

    full_path = "#{site_url}#{normalized_baseurl}#{normalized_path}"
    final_url = _clean_slashes(full_path)
    _ensure_trailing_slash(final_url, path_str, site_url)
  end

  def self._normalize_baseurl(baseurl)
    normalized = baseurl.gsub(%r{^/+|/+$}, '')
    normalized.empty? ? '' : "/#{normalized}"
  end

  def self._normalize_path(path_str, normalized_baseurl, site_url)
    return "#{site_url}/" if path_str.empty? && normalized_baseurl.empty?

    normalized = path_str.gsub(%r{^/+}, '')
    return "/#{normalized}" if !normalized.empty? || path_str == '/'
    return '' if path_str.empty? && !normalized_baseurl.empty?

    ''
  end

  def self._clean_slashes(url)
    url.gsub(%r{(?<!:)/+}, '/')
  end

  def self._ensure_trailing_slash(url, path_str, site_url)
    url += '/' if (path_str.empty? || path_str == '/') && !url.end_with?('/')
    url = "#{site_url}/" if url == site_url
    url
  end
end
