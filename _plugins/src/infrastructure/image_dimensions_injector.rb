# frozen_string_literal: true

require 'jekyll'
require_relative 'front_matter_image'
require_relative 'html_attributes'
require_relative 'image_dimensions'

module Jekyll
  module Infrastructure
    # Adds `width` and `height` to every `<img>` in rendered HTML, so
    # the browser reserves each image's box before the file arrives and the
    # page does not shift as images load (Cumulative Layout Shift).
    #
    # One post-render pass covers every source of `<img>`: layouts, the
    # figure include, cards, book-link previews, footnote previews, and
    # images written in post Markdown or raw HTML. The stylesheet sets
    # `img { height: auto; }`, so CSS widths keep the intrinsic aspect ratio.
    #
    # Resolution of `src`:
    # - Whitespace is stripped; the site's own `url` and `baseurl` prefixes
    #   are removed, so `https://alexgude.com/files/x.png` is local.
    # - The query, fragment, and percent-encoding are handled by
    #   FrontMatterImage.file_path.
    #
    # Every image must be local and sized here. A remote image would get no
    # size, and no CSS fallback reserves its box, so it stops the build;
    # host the file under `files/` instead. An author-set `width` or
    # `height` also stops the build: no page needs one, and with the
    # stylesheet's `height: auto` it would not change the aspect ratio
    # anyway. Size images with CSS.
    #
    # An image with WebP copies from ImageDerivatives also gains `srcset`
    # and `sizes` from `site.data['image_srcsets']`. Its `src` stays the
    # original, which sets the aspect ratio and serves browsers without
    # `srcset`. A `sizes` already on the tag is kept: a template whose slot
    # differs from the configured one (the book-link preview cover, cards)
    # states its own. A template `sizes` on an image that gets no `srcset`
    # (an SVG, or a file outside every ImageDerivatives entry) is removed:
    # `sizes` without `srcset` is invalid HTML.
    #
    # Hook order: FootnotePreviewInjector also runs at default
    # `:post_render` priority. Either order gives the same output, because a
    # footnote preview copies its `<img>` from the same page and every copy
    # is sized. Do not add a priority to sequence the two.
    #
    # The full HTML is never parsed and reserialized: a quote-aware scan
    # finds each `<img>` start tag and rewrites it in place, as in
    # FootnotePreviewInjector. Comments and the raw-text elements `script`,
    # `style`, and `textarea` are passed through unchanged, because an
    # `<img>` inside them is text, not an image.
    #
    # @validator An `<img>` with no `src`, a remote or relative `src`, a
    #   `src` naming a file missing from the source tree or one
    #   ImageDimensions cannot size, an author-set `width` or `height`, or
    #   an author-set `srcset` on an image with derivatives.
    #   html-proofer would catch a missing file only after the build; this
    #   stops the build at the page that references it.
    module ImageDimensionsInjector
      # One token per match: a comment, a raw-text element, an <img> start
      # tag, or any other start tag. Every start tag is consumed whole, with
      # its quoted attributes, so markup quoted inside an attribute value
      # (`data-example='<img src="...">'`) is never read as a tag. Quoted
      # values may contain '>'.
      TOKEN = %r{
        <!--.*?-->
        | <(?<raw>script|style|textarea)\b.*?</\k<raw>\s*>
        | (?<img><img\b(?:[^>"']|"[^"]*"|'[^']*')*>)
        | <[a-z][^\s/>]*(?:[^>"']|"[^"]*"|'[^']*')*>
      }xim
      IMG_START = /<img\b/i
      REMOTE_URL = %r{\A(?:[a-z][a-z0-9+.-]*:|//)}i
      private_constant :TOKEN, :IMG_START, :REMOTE_URL

      # @param item [Jekyll::Document, Jekyll::Page]
      # @return [Boolean] True for HTML output that may contain an <img>, in
      #   any letter case.
      def self.applies_to?(item)
        item.output_ext == '.html' && item.output.to_s.match?(IMG_START)
      end

      # @param html [String] A rendered page.
      # @param site [Jekyll::Site] Supplies `source`, `url`, and `baseurl`.
      # @param source [String, nil] Names the page in error messages.
      # @return [String] The page with sizes added to local images.
      def self.inject(html, site, source: nil)
        html.gsub(TOKEN) do
          match = Regexp.last_match
          match[:img] ? sized_tag(match[:img], site, source) : match[0]
        end
      end

      def self.sized_tag(tag, site, source)
        attributes = HtmlAttributes.parse(tag)
        src = attributes['src']
        fail_with(source, nil, "#{tag} has no src") unless src
        set = %w[width height].select { |name| attributes.key?(name) }
        fail_with(source, src, "sets #{set.join(' and ')}; size images with CSS instead") if set.any?

        file = local_file(src, site, source)
        width, height = ImageDimensions.of(file)
        srcset = srcset_attributes(attributes, file, site, src, source)
        orphan_sizes = srcset.empty? && attributes.key?('sizes') && !attributes.key?('srcset')
        tag = HtmlAttributes.remove(tag, 'sizes') if orphan_sizes
        added = { 'width' => width, 'height' => height }.merge(srcset)
        text = added.map { |name, value| %( #{name}="#{value}") }.join
        tag.sub(%r{\s*/?>\z}) { |close| "#{text}#{close}" }
      end
      private_class_method :sized_tag

      # @return [Hash{String => String}] `srcset` and `sizes` from
      #   ImageDerivatives, or empty for an image without derivatives. A
      #   lazy image gets `sizes="auto, ..."` so the browser can pick by
      #   its laid-out width; `auto` is invalid on an eager image. Only
      #   `srcset` when the tag already has `sizes`.
      def self.srcset_attributes(attributes, file, site, src, source)
        key = File.expand_path(file).delete_prefix(File.expand_path(site.source))
        derived = (site.data['image_srcsets'] || {})[key]
        return {} unless derived

        fail_with(source, src, 'sets srcset; ImageDerivatives supplies it') if attributes.key?('srcset')
        return { 'srcset' => derived['srcset'] } if attributes.key?('sizes')

        lazy = attributes['loading'].to_s.strip.casecmp?('lazy')
        { 'srcset' => derived['srcset'], 'sizes' => lazy ? "auto, #{derived['sizes']}" : derived['sizes'] }
      end
      private_class_method :srcset_attributes

      # @return [String] The absolute source path of a local image.
      def self.local_file(src, site, source)
        path = strip_prefix(src.strip, site.config['url'])
        fail_with(source, src, 'is remote; host the image under files/') if path.match?(REMOTE_URL)
        fail_with(source, src, 'is relative; use a root-relative path') unless path.start_with?('/')

        relative = FrontMatterImage.file_path(strip_prefix(path, site.config['baseurl']), source: source)
        file = File.join(site.source, relative)
        return file if File.file?(file)

        fail_with(source, src, "names no file at #{file}")
      end
      private_class_method :local_file

      def self.strip_prefix(path, prefix)
        prefix = prefix.to_s.chomp('/')
        return path if prefix.empty?
        return path.delete_prefix(prefix) if path.start_with?("#{prefix}/")

        path
      end
      private_class_method :strip_prefix

      # @param src [String, nil] Named as `<img src="...">`; nil when the
      #   problem text already shows the tag.
      def self.fail_with(source, src, problem)
        where = source ? " in '#{source}'" : ''
        image = src ? %(<img src="#{src}"> ) : ''
        raise Jekyll::Errors::FatalException, "ImageDimensionsInjector: #{image}#{problem}#{where}."
      end
      private_class_method :fail_with
    end
  end
end

Jekyll::Hooks.register [:documents, :pages], :post_render do |item|
  next unless Jekyll::Infrastructure::ImageDimensionsInjector.applies_to?(item)

  item.output = Jekyll::Infrastructure::ImageDimensionsInjector.inject(
    item.output, item.site, source: Jekyll::Infrastructure::FrontMatterImage.source_name(item),
  )
end
