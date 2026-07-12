# frozen_string_literal: true

require 'cgi'
require_relative 'markdown_html_converter'

module Jekyll
  module MarkdownOutput
    # Provides methods for the :pre_render hooks that re-render each
    # document/page body through Liquid with render_mode: :markdown.
    # The result is stored in data['markdown_body'] for the assembler.
    #
    # Entry point for the markdown output pipeline, which generates a clean
    # `.md` twin of every eligible page plus a `/llms.txt` index.
    #
    # Data flow:
    #
    #   PRE-RENDER (:documents/:pages, :pre_render)  [this file]
    #     - Eligibility check -> standalone Liquid::Template.parse()
    #     - render_mode: :markdown -> tags emit Markdown instead of HTML
    #     - Stores data['markdown_body'] + data['markdown_alternate_href']
    #
    #   POST-RENDER (:site, :post_render)  [markdown_output_assembler.rb]
    #     - For each item with markdown_body: header (post/book/generic) +
    #       body + footer (related content)
    #       -> MarkdownWhitespaceNormalizer -> GeneratedStaticFile (.md)
    #
    #   LLMS.TXT (Liquid tag on the /llms.txt page)  [tags/llms_txt_index_tag.rb]
    #     - {% llms_txt_index %} iterates eligible items -> sectioned index
    #
    # Tags branch HTML vs. Markdown output on `context.registers[:render_mode]`
    # (see `Jekyll::Infrastructure::Links::LinkTagBase` and
    # `Jekyll::UI::DisplayTagRenderable` for the two implementing patterns).
    # Formatting for Markdown output lives in
    # `Jekyll::UI::Cards::MarkdownCardUtils` (cards) and
    # `Jekyll::Infrastructure::Links::MarkdownLinkFormatter` (links).
    #
    # Controlled by `enable_markdown_output` (default: true); documents/pages
    # opt out with `markdown_output: false` in front matter.
    #
    # @pipeline markdown output: pre-render -> post-render assembly -> llms.txt
    # @gotcha `Document#to_liquid` returns a live `DocumentDrop` (delegates
    #   `[]` to `data`), but `Page#to_liquid` returns a plain `Hash`
    #   (snapshot at call time). Jekyll's `Renderer#run` calls `to_liquid`
    #   via `assign_pages!` *before* the `:pre_render` hook fires, so data
    #   set in the `:pages` hook below is visible to Documents but not
    #   Pages unless also injected into `payload['page']` directly (see the
    #   `:pages` hook's `markdown_alternate_href` assignment).
    module MarkdownBodyHook
      # Layout-driven pages keep their display tags in the layout template,
      # not in page.content. We append the relevant snippet so the markdown
      # pass picks them up.
      # Intro text mirrors the HTML layouts so both outputs stay in sync.
      LAYOUT_TAG_SNIPPETS = {
        'author_page' => "Below you'll find short reviews of {{ page.title }}'s books:\n\n" \
                         '{% display_books_by_author page.title %}',
        'series_page' => "Below you'll find short reviews of the books from the series: {{ page.title }}\n\n" \
                         '{% display_books_for_series page.title %}',
        'category' => '{% assign topic = page | optional: "category-name" %}{% display_category_posts topic=topic %}',
      }.freeze

      def self.content_with_layout_tags(content, item)
        snippet = LAYOUT_TAG_SNIPPETS[item.data['layout']]
        return content unless snippet

        body = content.to_s.strip
        return snippet if body.empty?

        "#{body}\n\n#{snippet}"
      end

      # @gotcha Uses `Liquid::Template.parse()` directly (not
      #   `site.liquid_renderer`) because Jekyll caches templates by
      #   filename and `render()` mutates `@registers` with `merge!()`.
      #   Using the site renderer would leak `render_mode: :markdown` into
      #   the HTML pass ("cache pollution").
      # @gotcha `render_mode` must always be defined in the Liquid payload
      #   (set to `'html'` by default in the pre-render hooks below) —
      #   strict Liquid variable mode raises if it's ever missing.
      def self.render_markdown_body(content, site, payload)
        # Parse a standalone template instead of using site.liquid_renderer.
        # Jekyll 4 caches templates by filename via ||=, and Liquid's render
        # mutates the cached template's @registers with merge!.  If we used
        # the site renderer here, render_mode: :markdown would leak into the
        # cached template's registers and persist into Jekyll's own HTML
        # rendering pass, causing every link tag to emit Markdown instead of
        # HTML.
        template = Liquid::Template.parse(content, line_numbers: true)
        info = {
          registers: {
            site: site,
            page: payload['page'],
            render_mode: :markdown,
          },
          strict_filters: site.config.dig('liquid', 'strict_filters'),
          strict_variables: site.config.dig('liquid', 'strict_variables'),
        }

        # Liquid's {% assign %} writes directly into the payload hash passed
        # to render!. We temporarily set render_mode='markdown' for this
        # pass, then restore the original value so the caller's payload
        # (used by Jekyll for the HTML render) isn't polluted.
        original_render_mode = payload['render_mode']
        begin
          payload['render_mode'] = 'markdown'
          rendered = template.render!(payload, info)
          MarkdownHtmlConverter.convert(rendered)
        ensure
          payload['render_mode'] = original_render_mode
        end
      end

      def self.enabled?(site)
        return false unless site

        site.config.fetch('enable_markdown_output', true)
      end

      # Both documents and pages use the same opt-out field.
      def self.eligible?(item)
        return false unless item.data.is_a?(Hash)
        return false if item.data['markdown_output'] == false

        true
      end

      def self.eligible_document?(doc)
        return false unless doc.respond_to?(:collection)
        return false unless %w[posts books].include?(doc.collection&.label)

        eligible?(doc)
      end

      def self.eligible_page?(page)
        return false unless eligible?(page)
        return false unless page.data['layout']
        return false if page.data['layout'] == 'redirect'
        return false if page.ext && !['.html', '.md'].include?(page.ext)

        true
      end

      def self.compute_markdown_href(item)
        url = item.url
        return '/index.md' if url == '/'

        url = url.chomp('/')
        url = url.sub(%r{\.[^./]+\z}, '') # strip file extension if present
        # Jekyll percent-encodes page URLs but writes directories with UTF-8.
        # Decode so the .md filename matches the directory encoding.
        "#{CGI.unescape(url)}.md"
      end
    end
  end
end

# Hook for collection documents (posts, books)
Jekyll::Hooks.register :documents, :pre_render do |doc, payload|
  # Unconditionally set render_mode='html' for the HTML render pass.
  # Templates check this to conditionally output HTML-only markup.
  # We overwrite (not ||=) because render_markdown_body restores the prior
  # value after its pass — if that prior value was nil, we need 'html' here.
  payload['render_mode'] = 'html' if payload

  next unless Jekyll::MarkdownOutput::MarkdownBodyHook.enabled?(doc.site)
  next unless Jekyll::MarkdownOutput::MarkdownBodyHook.eligible_document?(doc)

  begin
    doc.data['markdown_body'] = Jekyll::MarkdownOutput::MarkdownBodyHook.render_markdown_body(
      doc.content, doc.site, payload,
    )
    doc.data['markdown_alternate_href'] = Jekyll::MarkdownOutput::MarkdownBodyHook.compute_markdown_href(doc)
  rescue StandardError => e
    Jekyll.logger.warn 'MarkdownOutput:', "Failed for #{doc.url}: #{e.message}"
    doc.data.delete('markdown_body')
    doc.data.delete('markdown_alternate_href')
  end
end

# Hook for standalone pages (author, series, category, root pages, etc.)
Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  # See :documents hook above for why we unconditionally set 'html'.
  payload['render_mode'] = 'html' if payload

  next unless Jekyll::MarkdownOutput::MarkdownBodyHook.enabled?(page.site)
  next unless Jekyll::MarkdownOutput::MarkdownBodyHook.eligible_page?(page)

  begin
    content = Jekyll::MarkdownOutput::MarkdownBodyHook.content_with_layout_tags(page.content, page)
    page.data['markdown_body'] = Jekyll::MarkdownOutput::MarkdownBodyHook.render_markdown_body(
      content, page.site, payload,
    )
    href = Jekyll::MarkdownOutput::MarkdownBodyHook.compute_markdown_href(page)
    page.data['markdown_alternate_href'] = href
    # Page#to_liquid returns a Hash snapshot (unlike Document's live Drop),
    # so the payload's 'page' won't see data changes made after assign_pages!.
    # Inject into the payload directly so layouts/includes can access it.
    payload['page']['markdown_alternate_href'] = href if payload
  rescue StandardError => e
    Jekyll.logger.warn 'MarkdownOutput:', "Failed for #{page.url}: #{e.message}"
    page.data.delete('markdown_body')
    page.data.delete('markdown_alternate_href')
    payload['page']&.delete('markdown_alternate_href') if payload
  end
end
