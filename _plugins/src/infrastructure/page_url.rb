# frozen_string_literal: true

module Jekyll
  module Infrastructure
    # Reads the URL from a Jekyll page, document, Liquid payload, or test hash.
    module PageUrl
      def self.fetch(page)
        return nil unless page

        page.respond_to?(:url) ? page.url : page['url']
      end
    end
  end
end
