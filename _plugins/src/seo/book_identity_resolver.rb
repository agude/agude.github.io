# frozen_string_literal: true

module Jekyll
  module SEO
    # Resolves the site-owned identity URL for a reviewed book.
    class BookIdentityResolver
      def self.resolve(document, site)
        review_url = document&.url
        return if blank?(review_url)

        canonical_url = site&.data&.dig('link_cache', 'url_to_canonical_map', review_url)
        return review_url unless local_path?(canonical_url)

        canonical_url
      end

      def self.blank?(value)
        value.nil? || value.to_s.strip.empty?
      end
      private_class_method :blank?

      def self.local_path?(value)
        value.to_s.strip.start_with?('/')
      end
      private_class_method :local_path?
    end
  end
end
