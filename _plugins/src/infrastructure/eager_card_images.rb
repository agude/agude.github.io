# frozen_string_literal: true

require 'jekyll'
require_relative 'front_matter_image'
require_relative 'html_scan'

module Jekyll
  module Infrastructure
    # Loads the first card images on a card-list page eagerly.
    #
    # CardRendererUtils marks every card image `loading="lazy"`, because
    # index pages list over a hundred cards. A lazy image is fetched only
    # after layout, so when a card image is the Largest Contentful Paint
    # element, lazy loading delays it. Measured in November 2026, it is on
    # author and series pages at every width, and on /books/ and several
    # /books/by-*/ pages on desktop; the LCP image was always the first or
    # second card.
    #
    # The rule is structural: a page whose first `<img>` is a card image is
    # a card-list page, and its first EAGER_COUNT card images lose
    # `loading="lazy"` and the `auto, ` prefix of their `sizes` (`auto` is
    # valid only on a lazy image). Today that matches the indexes and the
    # topic, author, and series pages. It also matches a post with
    # `hide_lead_image: true` whose first image is an inline card.
    #
    # Card images are found forward from the `card-element` wrapper that
    # CardRendererUtils writes, so attribute lengths do not matter. No hook
    # priority is needed: ImageDimensionsInjector keeps a tag's own `sizes`,
    # so either order gives the same output.
    #
    # @validator A card image on a card-list page without
    #   `loading="lazy"`, or a page where TOKEN recognizes fewer card images
    #   than LOOSE_CARD_IMAGE finds: the card markup changed, and this hook
    #   would otherwise leave those cards lazy without a word.
    module EagerCardImages
      EAGER_COUNT = 2

      # A comment, a raw-text element, a card image with the markup before
      # it, any other <img> start tag, or any other start tag (HtmlScan).
      TOKEN = /
        #{HtmlScan::SKIPPED}
        | (?<prefix><div\ class="card-element\ [^"]*">\s*#{HtmlScan.start_tag('a')}\s*)
          (?<card>#{HtmlScan.start_tag('img')})
        | (?<img>#{HtmlScan.start_tag('img')})
        | #{HtmlScan::OTHER_START_TAG}
      /xi
      # Any <img> inside a card's image wrapper, whatever comes between. The
      # wrapper is found with the shared tokenizer, so a wrapper inside a
      # comment, a script, or an attribute value is not counted. The span
      # after it is not tokenized: a commented-out or quoted `<img` there
      # still counts and stops the build with a false mismatch, which is
      # loud rather than silent. The text wrapper (`card-text`) is excluded:
      # its excerpt can hold a book-link preview, whose cover is an <img>
      # but not a card image.
      LOOSE_CARD_IMAGE = %r{
        #{HtmlScan::SKIPPED}
        | (?<loose><div\ class="card-element\ (?!card-text")[^"]*">(?:(?!</div>).)*?<img\b)
        | #{HtmlScan::OTHER_START_TAG}
      }xim
      LAZY = /\s+loading="lazy"/
      AUTO_SIZES = /(\ssizes=")auto,\s*/
      private_constant :TOKEN, :LOOSE_CARD_IMAGE, :LAZY, :AUTO_SIZES

      # @param item [Jekyll::Document, Jekyll::Page]
      # @return [Boolean] True for HTML output that contains a card.
      def self.applies_to?(item)
        item.output_ext == '.html' && item.output.to_s.include?('class="card-element ')
      end

      # @param html [String] A rendered page.
      # @param source [String, nil] Names the page in error messages.
      # @return [String] The page, with its first card images eager when it
      #   is a card-list page.
      def self.apply(html, source: nil)
        first = true
        remaining = EAGER_COUNT
        cards = 0
        output = html.gsub(TOKEN) do
          match = Regexp.last_match
          cards += 1 if match[:card]
          image = match[:img] || match[:card]
          next match[0] unless image && remaining.positive?

          remaining = 0 if first && !match[:card]
          first = false
          next match[0] unless match[:card] && remaining.positive?

          remaining -= 1
          match[:prefix] + eager(match[:card], source)
        end
        check_cards_recognized(html, cards, source)
        output
      end

      def self.check_cards_recognized(html, cards, source)
        found = html.to_enum(:scan, LOOSE_CARD_IMAGE).count { Regexp.last_match[:loose] }
        return if cards == found

        where = source ? " in '#{source}'" : ''
        raise Jekyll::Errors::FatalException,
              "EagerCardImages: recognized #{cards} of #{found} card images#{where}; " \
              'CardRendererUtils changed its markup, so update TOKEN.'
      end
      private_class_method :check_cards_recognized

      def self.eager(tag, source)
        unless tag.match?(LAZY)
          where = source ? " in '#{source}'" : ''
          raise Jekyll::Errors::FatalException,
                "EagerCardImages: card image #{tag} is not loading=\"lazy\"#{where}; " \
                'CardRendererUtils changed its markup.'
        end

        tag.sub(LAZY, '').sub(AUTO_SIZES, '\1')
      end
      private_class_method :eager
    end
  end
end

Jekyll::Hooks.register [:documents, :pages], :post_render do |item|
  next unless Jekyll::Infrastructure::EagerCardImages.applies_to?(item)

  item.output = Jekyll::Infrastructure::EagerCardImages.apply(
    item.output, source: Jekyll::Infrastructure::FrontMatterImage.source_name(item),
  )
end
