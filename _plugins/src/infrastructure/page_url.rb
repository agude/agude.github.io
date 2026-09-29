# frozen_string_literal: true

module Jekyll
  module Infrastructure
    # Reads the URL from a Jekyll page, document, Liquid payload, or test hash.
    module PageUrl
      def self.fetch(page)
        return nil unless page

        url = page.url if page.respond_to?(:url)
        return url unless url.nil?

        page['url'] if page.respond_to?(:[])
      end
    end
  end
end
