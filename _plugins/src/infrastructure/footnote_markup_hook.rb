# frozen_string_literal: true

require 'jekyll'

module Jekyll
  module Infrastructure
    # Presentation transforms for kramdown footnote markup, applied to
    # rendered HTML pages:
    #
    # 1. An <hr> before the footnotes section.
    # 2. A superscripted ",&#x202F;" separator between adjacent footnote
    #    references, so consecutive refs read "1, 2" instead of "12".
    #
    # Both are literal string replacements against kramdown's rendered
    # footnote markup (formerly Liquid `replace` filters in the deleted
    # `_layouts/substitute.html`). The separator pattern matches the
    # pristine `</a></sup><sup id="fnref` shape, so this hook must run
    # before FootnotePreviewInjector rewrites the inside of the <sup> —
    # hence priority: :high on the registration below.
    module FootnoteMarkupTransforms
      FOOTNOTES_DIV = '<div class="footnotes" role="doc-endnotes">'
      private_constant :FOOTNOTES_DIV

      ADJACENT_REFS = '</a></sup><sup id="fnref'
      private_constant :ADJACENT_REFS

      SEPARATED_REFS = '</a></sup><sup class="fn-separator">,&#x202F;</sup><sup id="fnref'
      private_constant :SEPARATED_REFS

      # Applies both transforms. Returns the input unchanged when the page
      # has no footnotes section.
      def self.transform(html)
        return html unless html.include?(FOOTNOTES_DIV)

        html
          .gsub(FOOTNOTES_DIV, "<hr>#{FOOTNOTES_DIV}")
          .gsub(ADJACENT_REFS, SEPARATED_REFS)
      end
    end
  end
end

# priority: :high — must precede FootnotePreviewInjector (see module docs).
Jekyll::Hooks.register [:documents, :pages], :post_render, priority: :high do |item|
  next unless item.output_ext == '.html'
  next unless item.output

  item.output = Jekyll::Infrastructure::FootnoteMarkupTransforms.transform(item.output)
end
