# frozen_string_literal: true

require 'jekyll'
require_relative 'html_attributes'
require_relative 'html_scan'

module Jekyll
  module Infrastructure
    # Stops the build when an inline `<svg>` is neither hidden from
    # assistive technology nor named. Every inline SVG on the site is an
    # icon next to text that already says what it is (a social link, the
    # heading anchor), so it should carry `aria-hidden="true"`. An SVG that
    # conveys meaning on its own needs `role="img"` and an `aria-label`.
    #
    # An unhidden, unnamed icon is read as an unlabeled graphic, or its
    # path data is ignored silently, depending on the screen reader.
    #
    # SVGs inside comments and the raw-text elements `script`, `style`, and
    # `textarea` are skipped. An SVG loaded through `<img>` is not inline
    # and needs `alt` instead; html-proofer checks that.
    #
    # @validator An inline `<svg>` without `aria-hidden="true"` and
    #   without both `role="img"` and a non-empty `aria-label`.
    module InlineSvgValidator
      # A comment, a raw-text element, an <svg> start tag, or any other
      # start tag (HtmlScan).
      TOKEN = /
        #{HtmlScan::SKIPPED}
        | (?<svg>#{HtmlScan.start_tag('svg')})
        | #{HtmlScan::OTHER_START_TAG}
      /xi
      SVG_START = /<svg\b/i
      private_constant :TOKEN, :SVG_START

      # @param item [Jekyll::Document, Jekyll::Page]
      # @return [Boolean] True for HTML output that may contain an `<svg>`.
      def self.applies_to?(item)
        item.output_ext == '.html' && item.output.to_s.match?(SVG_START)
      end

      # @param html [String] A rendered page.
      # @param source [String, nil] Names the page in error messages.
      # @return [nil]
      # @raise [Jekyll::Errors::FatalException] At the first inline SVG
      #   that is neither hidden nor named.
      def self.validate(html, source: nil)
        html.scan(TOKEN) do
          tag = Regexp.last_match[:svg]
          next if tag.nil?

          attributes = HtmlAttributes.parse(tag)
          next if accessible?(attributes)

          fail_with(attributes, source)
        end
        nil
      end

      def self.accessible?(attributes)
        return true if attributes['aria-hidden'] == 'true'

        attributes['role'] == 'img' && !attributes['aria-label'].to_s.strip.empty?
      end
      private_class_method :accessible?

      # Names the SVG by its class, since its markup is mostly path data.
      def self.fail_with(attributes, source)
        name = attributes['class'] ? %(<svg class="#{attributes['class']}">) : '<svg> with no class'
        where = source ? " in '#{source}'" : ''
        raise Jekyll::Errors::FatalException,
              "InlineSvgValidator: #{name} needs aria-hidden=\"true\" (decorative) " \
              "or role=\"img\" with an aria-label (meaningful)#{where}."
      end
      private_class_method :fail_with
    end
  end
end

Jekyll::Hooks.register [:documents, :pages], :post_render, priority: :low do |item|
  next unless Jekyll::Infrastructure::InlineSvgValidator.applies_to?(item)

  Jekyll::Infrastructure::InlineSvgValidator.validate(item.output, source: item.relative_path)
end
