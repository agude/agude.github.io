# frozen_string_literal: true

require 'nokogiri'
require 'jekyll'
require_relative 'text_processing_utils'

module Jekyll
  module Infrastructure
    # Injects hover-preview cards into kramdown footnote references.
    #
    # Kramdown renders footnote references as:
    #   <sup id="fnref:label"><a href="#fn:label" class="footnote" ...>N</a></sup>
    # and the footnote body as:
    #   <div class="footnotes"><ol><li id="fn:label"><p>Text ↩</p></li></ol></div>
    #
    # This module injects a <span class="footnote-preview"> inside each
    # <sup>, after the reference <a>, containing the footnote body.
    #
    # @gotcha The <sup> sits inside a <p>, so the preview may contain only
    #   phrasing content: an HTML5 parser force-closes an open <p> at any
    #   block-level start tag (<figure>, <blockquote>, <div>, ...), ejecting
    #   the preview content out of the paragraph and splitting the paragraph
    #   in the DOM the browser builds. Block elements in the footnote body
    #   are therefore renamed to <span class="fnp fnp-<tag>"> and the
    #   stylesheet (_previews.scss) restores their block layout and
    #   typography via CSS. Any element outside the known block and phrasing
    #   sets fails the build rather than shipping a paragraph the browser
    #   would re-nest.
    #
    # Output structure (wrapped here for readability):
    #   <sup style="anchor-name:--fnref-label" id="fnref:label">
    #     <a href="#fn:label" class="footnote">N</a>
    #     <!--footnote-preview--><span class="footnote-preview"
    #         style="position-anchor:--fnref-label" aria-hidden="true" hidden>
    #       <span class="footnote-preview-body">   <!-- the scrollable region -->
    #         <span class="fnp fnp-figure cited-quote">...</span>
    #       </span>
    #     </span><!--/footnote-preview-->
    #   </sup>
    #
    # The comment markers are load-bearing: downstream pipelines match on them
    # to strip the preview when reusing rendered HTML (feeds, plain-text, etc).
    #
    # The full HTML string is never round-tripped through Nokogiri to avoid
    # DOCTYPE mangling: Nokogiri::HTML5 is used read-only for extraction;
    # injection uses targeted string replacement on the original string.
    module FootnotePreviewInjector
      Text = Jekyll::Infrastructure::TextProcessingUtils
      private_constant :Text

      # Matches the <sup id="fnref:ID"> element emitted by kramdown, split
      # before the closing tag so the preview can be injected inside.
      FOOTNOTE_SUP_REGEX = %r{(<sup\b[^>]*\bid="fnref:([^"]+)"[^>]*>.*?)(</sup>)}m
      private_constant :FOOTNOTE_SUP_REGEX

      # Block-level elements expected in footnote bodies. Each is renamed to
      # <span class="fnp fnp-<tag>">; _previews.scss rebuilds its layout.
      BLOCK_TAGS = %w[p div blockquote figure figcaption ol ul li pre h1 h2 h3 h4 h5 h6].freeze
      private_constant :BLOCK_TAGS

      # Phrasing elements that may remain in a preview verbatim.
      PHRASING_TAGS = (%w[a abbr b bdi bdo br cite code data del dfn em i img ins kbd mark q] +
                       %w[rp rt ruby s samp small span strong sub sup time u var wbr]).freeze
      private_constant :PHRASING_TAGS

      # Injects footnote preview cards into a full rendered HTML page string.
      # Returns the original string unchanged when no footnotes are present.
      def self.inject(html)
        return html unless html.include?('class="footnote"')

        doc = Nokogiri::HTML5(html)
        footnote_map = build_footnote_map(doc)
        return html if footnote_map.empty?

        html.gsub(FOOTNOTE_SUP_REGEX) do
          sup_open  = Regexp.last_match(1)
          id        = Regexp.last_match(2)
          sup_close = Regexp.last_match(3)

          # Idempotency guard: never re-inject into an already-injected sup
          # (a copied <sup> in the preview would otherwise derail the
          # non-greedy </sup> match on a second pass).
          next "#{sup_open}#{sup_close}" if sup_open.include?(Text::FOOTNOTE_PREVIEW_OPEN)

          # Repeat references to the same footnote are named fnref:label:N
          # by kramdown while the body stays fn:label — fall back to the
          # suffix-stripped label so every ref gets the preview.
          content = footnote_map[id] || footnote_map[id.sub(/:\d+\z/, '')]
          next "#{sup_open}#{sup_close}" if content.nil? || content.empty?

          # Each ref/preview pair gets a unique inline anchor name: a shared
          # name resolves to the LAST element in the document carrying it
          # (not the nearest), so every card would anchor to the final
          # footnote ref on the page.
          anchor = "--fnref-#{id.gsub(/[^a-zA-Z0-9_-]/, '-')}"
          anchored_sup = sup_open.sub(/\A<sup /, %(<sup style="anchor-name:#{anchor}" ))

          preview_span = %(<span class="footnote-preview" style="position-anchor:#{anchor}" aria-hidden="true" hidden>\
<span class="footnote-preview-body">#{content}</span></span>)
          preview = "#{Text::FOOTNOTE_PREVIEW_OPEN}#{preview_span}#{Text::FOOTNOTE_PREVIEW_CLOSE}"
          "#{anchored_sup}#{preview}#{sup_close}"
        end
      end

      # Returns a hash of footnote ID => phrasing-only preview HTML.
      def self.build_footnote_map(doc)
        doc.css('.footnotes li').each_with_object({}) do |li, map|
          id = li['id'].to_s.delete_prefix('fn:')
          next if id.empty?

          map[id] = extract_content(li)
        end
      end
      private_class_method :build_footnote_map

      # Extracts footnote body HTML, removes the back-link arrow, and
      # rewrites the copy into phrasing-only markup (see module docs).
      def self.extract_content(list_item)
        node = list_item.dup
        node.css('a.reversefootnote').each(&:remove)
        remove_heading_anchors(node)
        return nil if node.text.strip.empty?

        collapse_whitespace(node)
        flatten_blocks(node)
        neutralize_duplicates(node)
        assert_phrasing_only(node, list_item['id'])
        node.inner_html.strip
      end
      private_class_method :extract_content

      # Headings inside footnotes carry anchor-link icons (an <a> holding
      # svg.anchor-link-img, added by _includes/anchor_headings.html). They
      # are navigation chrome, not content — remove them from the copy.
      def self.remove_heading_anchors(node)
        node.css('svg.anchor-link-img').each do |svg|
          target = svg.parent.name == 'a' ? svg.parent : svg
          target.remove
        end
      end
      private_class_method :remove_heading_anchors

      # Collapses runs of whitespace in text nodes so the injected markup is
      # compact. Runs before flatten_blocks so <pre> is still identifiable:
      # its text keeps significant whitespace (the fnp-pre style restores
      # `white-space: pre` after the tag becomes a span).
      def self.collapse_whitespace(node)
        node.xpath('.//text()').each do |text_node|
          next if text_node.ancestors.any? { |ancestor| ancestor.name == 'pre' }

          text_node.content = text_node.content.gsub(/\s+/, ' ')
        end
      end
      private_class_method :collapse_whitespace

      # Renames block-level elements to phrasing-safe spans, preserving
      # their identity in a class (fnp-p, fnp-blockquote, ...) so the
      # stylesheet can rebuild their block layout.
      def self.flatten_blocks(node)
        node.css(BLOCK_TAGS.join(',')).each do |el|
          el['class'] = ['fnp', "fnp-#{el.name}", el['class']].compact.join(' ')
          el.name = 'span'
        end
      end
      private_class_method :flatten_blocks

      # The preview duplicates content that already exists in the footnote
      # list, so the copy must not compete with the original: ids would
      # collide with the footnote's anchors, links would add aria-hidden tab
      # stops, and eager images would download even while display: none
      # (loading="lazy" defers the fetch until the preview is shown).
      def self.neutralize_duplicates(node)
        # Book links inside footnotes carry their own nested hover-preview
        # card. Drop it (and its comment markers) from the copy: it is dead
        # weight in a hidden duplicate, and a preview-inside-preview hover
        # is not an interaction worth supporting. The original footnote at
        # the bottom of the page keeps its working book preview.
        node.css('.book-link-preview').each(&:remove)
        node.xpath('.//comment()').each(&:remove)

        node.css('[id]').each { |el| el.remove_attribute('id') }
        node.css('a').each { |a| a['tabindex'] = '-1' }
        node.css('img').each do |img|
          img['loading']  ||= 'lazy'
          img['decoding'] ||= 'async'
        end
      end
      private_class_method :neutralize_duplicates

      # Break, don't fail silently: an element outside the known sets would
      # be re-nested by the browser's parser, corrupting the paragraph.
      def self.assert_phrasing_only(node, footnote_id)
        node.css('*').each do |el|
          next if PHRASING_TAGS.include?(el.name)

          raise Jekyll::Errors::FatalException,
                "FootnotePreviewInjector: footnote '#{footnote_id}' contains " \
                "<#{el.name}>, which cannot appear in an inline hover preview. " \
                "Add it to BLOCK_TAGS (with matching .fnp-#{el.name} styles in " \
                '_previews.scss) or restructure the footnote.'
        end
      end
      private_class_method :assert_phrasing_only
    end
  end
end

Jekyll::Hooks.register [:documents, :pages], :post_render do |item|
  next unless item.output&.include?('class="footnote"')

  item.output = Jekyll::Infrastructure::FootnotePreviewInjector.inject(item.output)
end
