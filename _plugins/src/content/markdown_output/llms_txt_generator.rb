# frozen_string_literal: true

require_relative '../../infrastructure/generated_static_file'

module Jekyll
  module MarkdownOutput
    # Generates /llms.txt at site root, indexing all generated .md files.
    # Runs as a :site, :post_render hook after MarkdownOutputAssembler.
    #
    # Groups entries by type:
    #   - Blog Posts
    #   - Book Reviews
    #   - Optional (author pages, series pages, category pages, etc.)
    #
    # Follows the llms.txt spec: absolute URLs, descriptions where available.
    module LlmsTxtGenerator
      def self.generate(site)
        return unless MarkdownBodyHook.enabled?(site)

        entries = collect_entries(site)
        return if entries.empty?

        content = build_llms_txt(site, entries)
        file = Jekyll::Infrastructure::GeneratedStaticFile.new(site, '/', 'llms.txt', content)
        site.static_files << file
      end

      def self.collect_entries(site)
        entries = []
        collect_from_docs(entries, site.posts.docs, :blog)
        collect_from_docs(entries, site.collections['books']&.docs || [], :book)
        collect_from_pages(entries, site.pages)
        entries
      end

      def self.collect_from_docs(entries, docs, type)
        docs.each do |doc|
          next unless doc.data['markdown_alternate_href']

          entries << build_entry(doc, type)
        end
      end

      def self.collect_from_pages(entries, pages)
        pages.each do |page|
          next unless page.data['markdown_alternate_href']

          entries << build_entry(page, :optional)
        end
      end

      def self.build_entry(item, type)
        {
          type: type,
          title: item.data['title'] || '',
          href: item.data['markdown_alternate_href'],
          description: extract_description(item),
        }
      end

      def self.extract_description(item)
        desc = item.data['description']
        return desc.strip if desc && !desc.strip.empty?

        excerpt = item.data['excerpt']
        return nil unless excerpt

        text = excerpt.respond_to?(:output) ? excerpt.output : excerpt.to_s
        text = text.gsub(/<[^>]+>/, '').strip
        return nil if text.empty?

        text
      end

      def self.build_llms_txt(site, entries)
        base_url = site.config['url'] || ''
        lines = []
        lines << "# #{site.config['title'] || site.config['name'] || 'Site'}"
        lines << ''

        site_desc = site.config['description']
        if site_desc && !site_desc.strip.empty?
          lines << "> #{site_desc.strip}"
          lines << ''
        end

        grouped = entries.group_by { |e| e[:type] }

        append_section(lines, '## Blog Posts', grouped[:blog], base_url)
        append_section(lines, '## Book Reviews', grouped[:book], base_url)
        append_section(lines, '## Optional', grouped[:optional], base_url)

        lines.join("\n")
      end

      def self.append_section(lines, heading, entries, base_url)
        return unless entries && !entries.empty?

        lines << heading
        entries.each do |entry|
          url = "#{base_url}#{entry[:href]}"
          line = "- [#{entry[:title]}](#{url})"
          line += ": #{entry[:description]}" if entry[:description]
          lines << line
        end
        lines << ''
      end

      private_class_method :collect_entries,
                           :collect_from_docs,
                           :collect_from_pages,
                           :build_entry,
                           :extract_description,
                           :build_llms_txt,
                           :append_section
    end
  end
end
