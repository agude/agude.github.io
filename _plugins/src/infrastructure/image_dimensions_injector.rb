# frozen_string_literal: true

require 'jekyll'
require 'cgi'
require_relative 'front_matter_image'
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
    #   ImageDimensions cannot size, or an author-set `width` or `height`.
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
      # One attribute inside a start tag: name, then an optional double-,
      # single-, or unquoted value.
      ATTRIBUTE = %r{([^\s"'>/=]+)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>`]+)))?}
      REMOTE_URL = %r{\A(?:[a-z][a-z0-9+.-]*:|//)}i
      private_constant :TOKEN, :IMG_START, :ATTRIBUTE, :REMOTE_URL

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

      # @return [Hash{String => String, nil}] Lowercased attribute names to
      #   entity-decoded values; nil for a bare attribute. The first
      #   occurrence of a name wins, as in an HTML parser.
      def self.parse_attributes(tag)
        body = tag.sub(/\A<img/i, '').sub(%r{/?>\z}, '')
        body.scan(ATTRIBUTE).each_with_object({}) do |(name, *values), attributes|
          value = values.compact.first
          attributes[name.downcase] = value && CGI.unescapeHTML(value) unless attributes.key?(name.downcase)
        end
      end
      private_class_method :parse_attributes

      def self.sized_tag(tag, site, source)
        attributes = parse_attributes(tag)
        src = attributes['src']
        fail_with(source, nil, "#{tag} has no src") unless src
        set = %w[width height].select { |name| attributes.key?(name) }
        fail_with(source, src, "sets #{set.join(' and ')}; size images with CSS instead") if set.any?

        width, height = ImageDimensions.of(local_file(src, site, source))
        tag.sub(%r{\s*/?>\z}) { |close| %( width="#{width}" height="#{height}"#{close}) }
      end
      private_class_method :sized_tag

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
