# frozen_string_literal: true

require 'html-proofer'

# HTMLProofer check, run by check_links.rb over every page in _site/: an
# external `<script src>` or `<link rel="stylesheet" href>` needs an
# `integrity` hash and `crossorigin`, so a compromised or changed CDN file
# is refused instead of run.
#
# HTMLProofer's own `check_sri` option cannot do this here: check_links.rb
# ignores every http(s) URL so that CI fetches nothing external, and
# HTMLProofer skips ignored URLs before it checks SRI.
class SubresourceIntegrity < HTMLProofer::Check
  EXTERNAL = %r{\A(?:https?:)?//}i
  # Same-origin URLs written in full are local, not third-party.
  SITE_ORIGIN = %r{\Ahttps?://(?:www\.)?alexgude\.com(?:/|\z)}i

  def run
    @html.css('script[src]').each { |node| check(node, node['src']) }
    @html.css('link[href]').each do |node|
      check(node, node['href']) if node['rel'].to_s.split.map(&:downcase).include?('stylesheet')
    end
  end

  private

  def check(node, url)
    url = url.to_s.strip
    return unless url.match?(EXTERNAL) && !url.match?(SITE_ORIGIN)

    missing = %w[integrity crossorigin].reject { |name| node[name].to_s.strip.length.positive? }
    return if missing.empty?

    add_failure("external <#{node.name}> #{url} has no #{missing.join(' or ')}", element: create_element(node))
  end
end
