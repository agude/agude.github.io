# frozen_string_literal: true

require 'jekyll'
require_relative 'front_matter_image'
require_relative 'local_image'

module Jekyll
  module Infrastructure
    # Fails the build when a document's front-matter `image` is not a local
    # file that exists.
    #
    # The `image` value feeds the lead image, the card on index and related
    # pages, and the SEO and JSON-LD image URLs. html-proofer only sees it
    # where a page renders it as a relative `src`, so a page with
    # `hide_lead_image: true` and a broken `image` would ship broken cards.
    # This check reads the file system and does not depend on rendering.
    #
    # The reference is resolved by LocalImage, so the site's own URL prefix,
    # a query, a fragment, or percent-encoding does not hide the file. A
    # remote or relative reference fails: the image is shown as an `<img>`
    # (lead image or card), and ImageDimensionsInjector stops the build on
    # either, but only on pages that render it; this check covers every
    # page. A value that is not a string, such as a `{path, alt}` hash,
    # stops the build in FrontMatterImage.path.
    #
    # @validator Front-matter `image` that is remote or relative, or that
    #   names a local file missing from the source tree, including on pages
    #   that hide their lead image.
    module FrontMatterImageValidator
      # Raises when the item's image is not a local file that exists.
      # @param item [Jekyll::Document, Jekyll::Page] Carries the `image` field.
      # @param site [Jekyll::Site] Supplies the source directory.
      def self.validate(item, site)
        return unless item.data.is_a?(Hash)

        identifier = FrontMatterImage.source_name(item)
        path = FrontMatterImage.path(item.data['image'], source: identifier)
        return if path.nil?

        image = LocalImage.resolve(path, site)
        return if image.found?

        problem = LocalImage::PROBLEMS.fetch(image.status) { "names no file; looked for #{image.file}" }
        raise Jekyll::Errors::FatalException,
              "FrontMatterImageValidator: '#{identifier}' sets image '#{path}', which #{problem}."
      end
    end
  end
end

Jekyll::Hooks.register [:documents, :pages], :pre_render do |item, _payload|
  Jekyll::Infrastructure::FrontMatterImageValidator.validate(item, item.site)
end
