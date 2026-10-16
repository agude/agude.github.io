# frozen_string_literal: true

require 'jekyll'
require 'uri'
require_relative 'url_utils'

module Jekyll
  module Infrastructure
    # The one reading of a front-matter `image` value, shared by the SEO
    # meta tags, JSON-LD, cards, and FrontMatterImageValidator.
    #
    # An image is a string path or URL. Any other shape, a hash included,
    # stops the build rather than being stringified into a URL. Alt text is
    # the separate top-level `image_alt` key.
    #
    # @gotcha The book layout, BookPreviewRenderer, and
    #   MarkdownOutputAssembler read `image` directly. They rely on
    #   FrontMatterImageValidator, which calls `path` on every rendered
    #   document and page, to fail the build on any other shape.
    module FrontMatterImage
      # @param value [String, nil] The raw `image` value.
      # @param source [String, nil] Names the document in error messages.
      # @return [String, nil] The stripped path or URL, or nil when blank.
      # @raise [Jekyll::Errors::FatalException] For any value that is
      #   neither a string nor nil.
      def self.path(value, source: nil)
        return nil if value.nil?

        raise_shape_error(value, source) unless value.is_a?(String)

        stripped = value.strip
        stripped.empty? ? nil : stripped
      end

      # Names a document or page in error messages: its source file, or its
      # URL when it has none.
      # @param item [Jekyll::Document, Jekyll::Page, Jekyll::Drops::Drop, nil]
      # @return [String, nil]
      def self.source_name(item)
        return nil if item.nil?

        file = item.relative_path if item.respond_to?(:relative_path)
        file.to_s.empty? ? item.url : file
      end

      # The source-relative file a local image reference names, for checks
      # that read the file system. Consumers that emit the URL keep `path`:
      # the browser requests it exactly as written.
      #
      # The query and fragment are removed at the first literal `?` or `#`
      # before decoding, so an encoded `%3F` or `%23` stays part of the
      # file name. The rest is percent-decoded once. A literal `+` or space
      # is kept: this is a URL path, not form data.
      #
      # @return [String, nil] The decoded path, or nil when blank.
      def self.file_path(value, source: nil)
        image_path = path(value, source: source)
        image_path && URI::DEFAULT_PARSER.unescape(image_path.sub(/[?#].*\z/m, ''))
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
              "Front-matter image#{where} must be a string path or URL, got #{value.inspect}. " \
              'Put alt text in the top-level image_alt key.'
      end
      private_class_method :raise_shape_error
    end
  end
end
