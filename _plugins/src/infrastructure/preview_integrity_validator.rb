# frozen_string_literal: true

require 'jekyll'

module Jekyll
  module Infrastructure
    # Fails the build when hover-preview markup has been mangled by the
    # markdown parser instead of surviving intact into the rendered page.
    #
    # Preview markup (see BookPreviewRenderer, FootnotePreviewInjector) is
    # emitted as a single line whose comment markers sit flush against raw
    # HTML tags: the character before a marker is always '>' and the
    # character after is always '<'. When that single-line contract is
    # violated (e.g. a newline inside a kramdown footnote definition ends
    # the definition mid-span), kramdown escapes the orphaned tags and the
    # rendered page contains debris like:
    #
    #   ...powerful.&lt;/span&gt;&lt;/span&gt;<!--/book-preview-->&lt;/a&gt;:
    #
    # where escaped text abuts a raw marker. Rouge-highlighted code blocks
    # cannot false-positive: they escape the markers themselves, so a raw
    # marker never appears inside one.
    #
    # @validator Hover-preview markup split by the markdown parser
    #   (escaped tag debris abutting a raw preview comment marker).
    module PreviewIntegrityValidator
      MARKER = '<!--/?(?:book|footnote)-preview-->'
      # A raw preview marker not immediately preceded by '>' or not
      # immediately followed by '<'. Context for the error message is sliced
      # after a match: capturing it in the pattern (.{0,40}) retries the
      # search at every character of every valid page.
      LEAK_PATTERN = /[^>]#{MARKER}|#{MARKER}[^<]/
      private_constant :MARKER, :LEAK_PATTERN

      # Raises when rendered HTML contains mangled preview markup.
      # @param html [String] The rendered page output.
      # @param identifier [String] Page URL or path, for the error message.
      def self.validate(html, identifier)
        return unless html.include?('-preview-->')

        match = LEAK_PATTERN.match(html)
        return unless match

        context_start = [match.begin(0) - 40, 0].max
        context = html[context_start...(match.end(0) + 40)]
        raise Jekyll::Errors::FatalException,
              "PreviewIntegrityValidator: mangled hover-preview markup in #{identifier}: " \
              "#{context.inspect}. Preview markup was split by the markdown parser — " \
              'usually a newline inside single-line preview output (see BookPreviewRenderer).'
      end
    end
  end
end

# priority: :low so it runs after the normal-priority hooks that emit and
# transform preview markup (FootnotePreviewInjector, feed stripping).
Jekyll::Hooks.register [:documents, :pages], :post_render, priority: :low do |item|
  next unless item.output_ext == '.html'
  next unless item.output

  identifier = item.respond_to?(:url) ? item.url : item.inspect
  Jekyll::Infrastructure::PreviewIntegrityValidator.validate(item.output, identifier)
end
