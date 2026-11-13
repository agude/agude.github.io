# frozen_string_literal: true

module Jekyll
  module Infrastructure
    # Regexp pieces for the tokenizers that post-render hooks use to find
    # start tags in rendered HTML without parsing and reserializing it.
    #
    # @pattern A tokenizer is one alternation, written as a literal by its
    #   caller and scanned with `gsub` or `scan`:
    #
    #     TOKEN = /
    #       #{HtmlScan::SKIPPED}
    #       | (?<img>#{HtmlScan.start_tag('img')})
    #       | #{HtmlScan::OTHER_START_TAG}
    #     /xi
    #
    #   SKIPPED comes first, so a tag inside a comment or a raw-text element
    #   (`script`, `style`, `textarea`) is passed over. The caller's own
    #   groups come next: alternatives are tried in order at each position,
    #   so a caller group that starts with a tag (EagerCardImages' card
    #   `<div>`) wins over OTHER_START_TAG. OTHER_START_TAG comes last and
    #   consumes every remaining start tag whole, so markup quoted inside an
    #   attribute value (`data-example='<img src="...">'`) is never read as
    #   a tag. The caller handles a match only when one of its groups is set.
    #
    #   Interpolated Regexps keep their own flags, so the pieces are
    #   case-insensitive and SKIPPED matches across lines whatever flags the
    #   caller's literal has. Callers use `xi`, adding `m` only when their
    #   own pattern uses `.` across lines (EagerCardImages'
    #   LOOSE_CARD_IMAGE).
    #
    # @gotcha SKIPPED defines the named group `raw`; a caller must not name
    #   a group `raw`.
    # @gotcha In a caller's `x`-mode literal, an unescaped `#` that is not
    #   `#{...}` starts a comment and silently drops the rest of the line.
    #   Escape it (`\#`), and a literal space too (`\ `), or use `\s`.
    #
    # Used by ImageDimensionsInjector, CodeBlockRegionInjector,
    # InlineSvgValidator, and EagerCardImages. HtmlAttributes reads the
    # attributes of a tag found this way.
    module HtmlScan
      # A start tag's attributes, quoted values consumed whole, so a value
      # may contain `>`.
      ATTRIBUTES = /(?:[^>"']|"[^"]*"|'[^']*')*/
      # Comments and raw-text elements, whose contents hold no live markup.
      # The element name must end the tag name, as in start_tag: with `\b`,
      # a custom element such as `<script-loader>` would be read as raw text
      # and everything up to the next `</script>` skipped.
      SKIPPED = %r{<!--.*?--> | <(?<raw>script|style|textarea)(?=[\s/>]).*?</\k<raw>\s*>}xim
      OTHER_START_TAG = %r{<[a-z][^\s/>]*#{ATTRIBUTES}>}i

      # The name must end at whitespace, `/`, or `>`: a `\b` boundary would
      # also match a custom element such as `<svg-icon>`, since `-` is not a
      # word character.
      #
      # @param name [String] A tag name, such as "img".
      # @return [Regexp] That start tag, with its attributes.
      def self.start_tag(name)
        %r{<#{Regexp.escape(name)}(?=[\s/>])#{ATTRIBUTES}>}i
      end
    end
  end
end
