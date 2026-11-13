# frozen_string_literal: true

require 'jekyll'
require_relative 'html_attributes'
require_relative 'html_scan'

module Jekyll
  module Infrastructure
    # Makes every `<pre>` in rendered HTML a labeled, keyboard-focusable
    # region: `tabindex="0" role="region" aria-label="Python code"`.
    #
    # A code block wider than the column scrolls horizontally (`pre {
    # overflow: auto }`). A keyboard user can scroll it only after focusing
    # it, and Safari does not make scrollers focusable on its own. Static
    # HTML cannot tell which blocks overflow, so every block gets the
    # attributes; one that fits costs one extra Tab stop. `role="region"`
    # with a label lets a screen reader announce the focused block.
    #
    # The label names the language from the wrapper kramdown and Rouge emit:
    #   <div class="language-python highlighter-rouge"><div class="highlight">
    #   <pre class="highlight">
    # Plain-text fences and a `<pre>` without that wrapper get "Code block".
    #
    # Hook order: priority :low, after FootnotePreviewInjector. That
    # injector copies a footnote's body into a hidden, aria-hidden preview
    # and renames the copy's `<pre>` to a span; running later keeps the
    # tab stop and region role out of the copy. The footnote itself, at the
    # bottom of the page, keeps its `<pre>` and is labeled here.
    #
    # The full HTML is never parsed and reserialized: a quote-aware scan
    # finds each `<pre>` start tag and rewrites it in place, as in
    # ImageDimensionsInjector. Comments and the raw-text elements `script`,
    # `style`, and `textarea` are passed through unchanged.
    #
    # @validator A `<pre>` that already has a `tabindex`, `role`, or
    #   `aria-label` attribute, with or without a value, or a code fence in a language missing from
    #   LANGUAGE_NAMES. Add the language there to give it a spoken name.
    module CodeBlockRegionInjector
      # Spoken names for fence languages. `nil` means plain text.
      LANGUAGE_NAMES = {
        'bash' => 'Bash',
        'cpp' => 'C++',
        'html' => 'HTML',
        'liquid' => 'Liquid',
        'plaintext' => nil,
        'python' => 'Python',
        'shell' => 'Shell',
        'sql' => 'SQL',
        'text' => nil,
        'vim' => 'Vim script',
        'yaml' => 'YAML',
      }.freeze

      # One token per match: a comment, a raw-text element, a `<pre>` start
      # tag with its optional Rouge wrapper, or any other start tag
      # (HtmlScan).
      TOKEN = /
        #{HtmlScan::SKIPPED}
        | (?<wrapper><div\sclass="language-(?<language>[^"\s]+)\shighlighter-rouge">\s*
            <div\sclass="highlight">\s*)?
          (?<pre>#{HtmlScan.start_tag('pre')})
        | #{HtmlScan::OTHER_START_TAG}
      /xi
      PRE_START = /<pre\b/i
      ADDED = %w[tabindex role aria-label].freeze
      DEFAULT_LABEL = 'Code block'
      private_constant :TOKEN, :PRE_START, :ADDED, :DEFAULT_LABEL

      # @param item [Jekyll::Document, Jekyll::Page]
      # @return [Boolean] True for HTML output that may contain a `<pre>`.
      def self.applies_to?(item)
        item.output_ext == '.html' && item.output.to_s.match?(PRE_START)
      end

      # @param html [String] A rendered page.
      # @param source [String, nil] Names the page in error messages.
      # @return [String] The page with every `<pre>` made a labeled region.
      def self.inject(html, source: nil)
        html.gsub(TOKEN) do
          match = Regexp.last_match
          next match[0] unless match[:pre]

          "#{match[:wrapper]}#{region_tag(match[:pre], match[:language], source)}"
        end
      end

      def self.region_tag(tag, language, source)
        set = ADDED & HtmlAttributes.parse(tag).keys
        fail_with(source, "#{tag} sets #{set.join(', ')}; CodeBlockRegionInjector adds them") if set.any?

        attributes = %( tabindex="0" role="region" aria-label="#{label(language, source)}")
        tag.sub(%r{\s*/?>\z}) { |close| "#{attributes}#{close}" }
      end
      private_class_method :region_tag

      # @return [String] "<Language> code", or DEFAULT_LABEL for plain text
      #   and a `<pre>` without a Rouge wrapper.
      def self.label(language, source)
        return DEFAULT_LABEL unless language

        key = language.downcase
        unless LANGUAGE_NAMES.key?(key)
          fail_with(source, "code fence language '#{language}' has no spoken name; add it to LANGUAGE_NAMES")
        end

        name = LANGUAGE_NAMES[key]
        name ? "#{name} code" : DEFAULT_LABEL
      end
      private_class_method :label

      def self.fail_with(source, problem)
        where = source ? " in '#{source}'" : ''
        raise Jekyll::Errors::FatalException, "CodeBlockRegionInjector: #{problem}#{where}."
      end
      private_class_method :fail_with
    end
  end
end

Jekyll::Hooks.register [:documents, :pages], :post_render, priority: :low do |item|
  next unless Jekyll::Infrastructure::CodeBlockRegionInjector.applies_to?(item)

  item.output = Jekyll::Infrastructure::CodeBlockRegionInjector.inject(
    item.output, source: item.relative_path,
  )
end
