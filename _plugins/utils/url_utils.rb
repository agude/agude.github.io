# frozen_string_literal: true

# _plugins/utils/url_utils.rb

module UrlUtils
  def self.absolute_url(path, site)
    return nil if path.nil?

    path_str = path.to_s

    # Return immediately if path_str is already a full URL
    return path_str if path_str.start_with?('http://', 'https://')

    site_url = site.config['url'].to_s.chomp('/')
    baseurl  = site.config['baseurl'].to_s # Don't chomp here initially

    # Normalize baseurl: remove leading/trailing slashes, then add a leading one if not empty
    normalized_baseurl = baseurl.gsub(%r{^/+|/+$}, '')
    normalized_baseurl = "/#{normalized_baseurl}" unless normalized_baseurl.empty?

    # Normalize path: remove leading slashes, then add a leading one if not empty
    # unless it's an empty string (which means we want the base or site URL)
    normalized_path = path_str.gsub(%r{^/+}, '')
    if !normalized_path.empty? || path_str == '/' # if original path was "/" or non-empty after stripping
      normalized_path = "/#{normalized_path}"
    elsif path_str.empty? && !normalized_baseurl.empty?
      # If path is empty but baseurl exists, we want the baseurl path, often ending in /
      # The join later will handle this. If baseurl is just "/", normalized_baseurl will be "/".
      # If path is empty, normalized_path should be empty so baseurl is the target.
      normalized_path = '' # Ensure it's empty if original path was empty
    elsif path_str.empty? && normalized_baseurl.empty?
      # Path and baseurl are empty, target is site_url + "/"
      return "#{site_url}/"
    end

    # Combine parts, then clean up slashes
    full_path = "#{site_url}#{normalized_baseurl}#{normalized_path}"

    # Replace multiple slashes (except in protocol) with a single slash
    # And ensure a trailing slash if the original path was empty or just "/"
    # and the result is just the domain or domain + baseurl.
    final_url = full_path.gsub(%r{(?<!:)/+}, '/')

    # Add trailing slash if the effective path component is empty or just baseurl
    # (i.e., original path was "" or "/")
    final_url += '/' if (path_str.empty? || path_str == '/') && !final_url.end_with?('/')
    # Special case: if the result is just the site_url (e.g. https://example.com), ensure it has a trailing slash
    final_url = "#{site_url}/" if final_url == site_url

    final_url
  end
end
