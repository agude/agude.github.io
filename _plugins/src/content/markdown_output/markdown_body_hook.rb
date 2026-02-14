# frozen_string_literal: true

module Jekyll
  module MarkdownOutput
    # Provides methods for the :pre_render hooks that re-render each
    # document/page body through Liquid with render_mode: :markdown.
    # The result is stored in data['markdown_body'] for the assembler.
    module MarkdownBodyHook
      def self.render_markdown_body(content, _path, site, payload)
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
            render_mode: :markdown
          },
          strict_filters: site.config.dig('liquid', 'strict_filters'),
          strict_variables: site.config.dig('liquid', 'strict_variables')
        }

        # Inject render_mode into payload for includes (which can't access registers)
        payload_with_mode = payload.merge('render_mode' => 'markdown')
        template.render!(payload_with_mode, info)
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
        "#{url}.md"
      end
    end
  end
end

# Hook for collection documents (posts, books)
Jekyll::Hooks.register :documents, :pre_render do |doc, payload|
  next unless Jekyll::MarkdownOutput::MarkdownBodyHook.enabled?(doc.site)
  next unless Jekyll::MarkdownOutput::MarkdownBodyHook.eligible_document?(doc)

  begin
    doc.data['markdown_body'] = Jekyll::MarkdownOutput::MarkdownBodyHook.render_markdown_body(
      doc.content, doc.path, doc.site, payload
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
  next unless Jekyll::MarkdownOutput::MarkdownBodyHook.enabled?(page.site)
  next unless Jekyll::MarkdownOutput::MarkdownBodyHook.eligible_page?(page)

  begin
    page.data['markdown_body'] = Jekyll::MarkdownOutput::MarkdownBodyHook.render_markdown_body(
      page.content, page.path, page.site, payload
    )
    page.data['markdown_alternate_href'] = Jekyll::MarkdownOutput::MarkdownBodyHook.compute_markdown_href(page)
  rescue StandardError => e
    Jekyll.logger.warn 'MarkdownOutput:', "Failed for #{page.url}: #{e.message}"
    page.data.delete('markdown_body')
    page.data.delete('markdown_alternate_href')
  end
end
