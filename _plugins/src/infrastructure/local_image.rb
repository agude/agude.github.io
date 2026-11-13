# frozen_string_literal: true

require 'uri'

module Jekyll
  module Infrastructure
    # Resolves an image reference (an `<img src>` or a front-matter
    # `image`) to the file it names in the source tree.
    #
    # The one reading shared by ImageDimensionsInjector,
    # FrontMatterImageValidator, and ImageDerivatives, so the three agree
    # on what counts as local:
    # - Whitespace is stripped; the site's own `url` and `baseurl` prefixes
    #   are removed, so `https://alexgude.com/files/x.png` is local.
    # - Any other scheme or a protocol-relative `//host/` is remote.
    # - A local reference must be root-relative (`/files/x.png`).
    # - The query, fragment, and percent-encoding are handled by file_path.
    #
    # @pattern Resolve, then decide; each caller words its own error:
    #
    #     image = LocalImage.resolve(src, site)
    #     return image.file if image.found?
    #
    #     problem = LocalImage::PROBLEMS.fetch(image.status) { "names no file at #{image.file}" }
    #     fail_with("<img src=\"#{src}\"> #{problem}")
    #
    #   PROBLEMS phrases start with "is" and need the reference as their
    #   subject ("'x.png', which is relative; ...").
    module LocalImage
      REMOTE_URL = %r{\A(?:[a-z][a-z0-9+.-]*:|//)}i
      private_constant :REMOTE_URL

      # status: :remote, :relative, :missing, or :found. file: the absolute
      # source path, for :missing and :found. relative: the same path
      # relative to the source directory, without a leading slash.
      Resolution = Struct.new(:status, :file, :relative, keyword_init: true) do
        def found? = status == :found
      end

      PROBLEMS = {
        remote: 'is remote; host the image under files/',
        relative: 'is relative; use a root-relative path',
      }.freeze

      # @param reference [String] An `src` or front-matter `image` value.
      # @param site [Jekyll::Site] Supplies `source`, `url`, and `baseurl`.
      # @return [Resolution]
      def self.resolve(reference, site)
        path = strip_prefix(reference.strip, site.config['url'])
        return Resolution.new(status: :remote) if path.match?(REMOTE_URL)
        return Resolution.new(status: :relative) unless path.start_with?('/')

        relative = file_path(strip_prefix(path, site.config['baseurl'])).delete_prefix('/')
        file = File.join(site.source, relative)
        Resolution.new(status: File.file?(file) ? :found : :missing, file: file, relative: relative)
      end

      # The file a URL path names. Consumers that emit the URL keep the
      # reference as written: the browser requests it exactly so.
      #
      # The query and fragment are removed at the first literal `?` or `#`
      # before decoding, so an encoded `%3F` or `%23` stays part of the
      # file name. The rest is percent-decoded once. A literal `+` or space
      # is kept: this is a URL path, not form data.
      #
      # @param path [String] A URL path, such as `/files/a%20b.png?v=1`.
      # @return [String] The decoded path, such as `/files/a b.png`.
      def self.file_path(path)
        URI::DEFAULT_PARSER.unescape(path.strip.sub(/[?#].*\z/m, ''))
      end

      def self.strip_prefix(path, prefix)
        prefix = prefix.to_s.chomp('/')
        return path if prefix.empty?
        return path.delete_prefix(prefix) if path.start_with?("#{prefix}/")

        path
      end
      private_class_method :strip_prefix
    end
  end
end
