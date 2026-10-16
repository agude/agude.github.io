# frozen_string_literal: true

require 'jekyll'
require_relative 'url_utils'

module Jekyll
  module Infrastructure
    # The one reading of a front-matter `image` value, shared by the SEO
    # meta tags, JSON-LD, cards, and FrontMatterImageValidator.
    #
    # An image is a string path or URL, or a `{path, alt}` hash. Any other
    # shape stops the build rather than being stringified into a URL.
    module FrontMatterImage
      # @param value [String, Hash, nil] The raw `image` value.
      # @param source [String, nil] Names the document in error messages.
      # @return [String, nil] The stripped path or URL, or nil when blank.
      # @raise [Jekyll::Errors::FatalException] For any other shape, or a
      #   hash whose `path` is not a string.
      def self.path(value, source: nil)
        raw = value.is_a?(Hash) ? value['path'] : value
        return nil if raw.nil?

        raise_shape_error(value, source) unless raw.is_a?(String)

        stripped = raw.strip
        stripped.empty? ? nil : stripped
      end

      # @return [String, nil] The absolute URL of the image, or nil when blank.
      #   Absolute http(s) URLs are returned unchanged.
      def self.absolute_url(value, site, source: nil)
        image_path = path(value, source: source)
        image_path && UrlUtils.absolute_url(image_path, site)
      end

      def self.raise_shape_error(value, source)
        where = source ? " in '#{source}'" : ''
        raise Jekyll::Errors::FatalException,
              "Front-matter image#{where} must be a string or a {path, alt} hash with a string path, " \
              "got #{value.inspect}."
      end
      private_class_method :raise_shape_error
    end
  end
end
