# frozen_string_literal: true

require 'jekyll'

module Jekyll
  module Infrastructure
    # Fails the build when a document's front-matter `image` names a local
    # file that does not exist.
    #
    # The `image` value feeds the lead image, the card on index and related
    # pages, and the SEO and JSON-LD image URLs. html-proofer only sees it
    # where a page renders it as a relative `src`, so a page with
    # `hide_lead_image: true` and a broken `image` would ship broken cards.
    # This check reads the file system and does not depend on rendering.
    #
    # Absolute `http(s)` URLs are not checked. A hash-form image
    # (`{path, alt}`) is checked by its `path`.
    #
    # @validator Front-matter `image` that names a local file missing from
    #   the source tree, including on pages that hide their lead image.
    module FrontMatterImageValidator
      # Raises when the item's local image does not exist under the source.
      # @param item [Jekyll::Document, Jekyll::Page] Carries the `image` field.
      # @param site [Jekyll::Site] Supplies the source directory.
      def self.validate(item, site)
        return unless item.data.is_a?(Hash)

        path = image_path(item.data['image'])
        return if path.nil? || path.start_with?('http://', 'https://')
        return if File.file?(File.join(site.source, path))

        identifier = item.relative_path || item.url
        raise Jekyll::Errors::FatalException,
              "FrontMatterImageValidator: '#{identifier}' sets image '#{path}', " \
              "but no file exists at #{File.join(site.source, path)}."
      end

      def self.image_path(image)
        value = image.is_a?(Hash) ? image['path'] : image
        path = value.to_s.strip
        path.empty? ? nil : path
      end
      private_class_method :image_path
    end
  end
end

Jekyll::Hooks.register [:documents, :pages], :pre_render do |item, _payload|
  Jekyll::Infrastructure::FrontMatterImageValidator.validate(item, item.site)
end
