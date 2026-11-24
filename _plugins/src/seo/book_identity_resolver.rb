# frozen_string_literal: true

module Jekyll
  module SEO
    # Resolves the site-owned identity URL for a reviewed book.
    #
    # @gotcha An archived review resolves to its local canonical review URL
    #   for the Book entity. The review page itself keeps its own document URL;
    #   this resolver changes only the identity of the book being reviewed.
    class BookIdentityResolver
      def self.resolve(document, site)
        review_url = document&.url
        return if blank?(review_url)

        # BookFamilyValidator allows only local canonical_url values, so a
        # mapped URL is always a page on this site.
        site&.data&.dig('link_cache', 'url_to_canonical_map', review_url) || review_url
      end

      def self.blank?(value)
        value.nil? || value.to_s.strip.empty?
      end
      private_class_method :blank?
    end
  end
end
