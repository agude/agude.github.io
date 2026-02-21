# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../markdown_body_hook'
require_relative '../markdown_card_utils'

module Jekyll
  module MarkdownOutput
    module Tags
      # Liquid tag that generates the sectioned entry list for /llms.txt.
      # Iterates eligible posts, books, and pages and formats them using
      # MarkdownCardUtils so formatting stays consistent site-wide.
      #
      # Usage: {% llms_txt_index %}
      class LlmsTxtIndexTag < Liquid::Tag
        Hook = Jekyll::MarkdownOutput::MarkdownBodyHook
        MdCards = Jekyll::MarkdownOutput::MarkdownCardUtils
        private_constant :Hook, :MdCards

        def initialize(tag_name, markup, tokens)
          super
          return if markup.strip.empty?

          raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
        end

        def render(context)
          site = context.registers[:site]
          return '' unless Hook.enabled?(site)

          base_url = site.config['url'] || ''

          blogs = collect_docs(site.posts.docs, base_url)
          books = collect_books(site.collections['books']&.docs || [], base_url)
          optional = collect_pages(site.pages, base_url)

          sections = []
          append_section(sections, '## Blog Posts', blogs)
          append_section(sections, '## Book Reviews', books)
          append_section(sections, '## Optional', optional)
          sections.join("\n")
        end

        private

        def collect_docs(docs, base_url)
          docs.filter_map do |doc|
            next unless Hook.eligible_document?(doc)

            href = Hook.compute_markdown_href(doc)
            {
              title: doc.data['title'],
              url: "#{base_url}#{href}",
              description: MdCards.extract_plain_description(doc.data, type: :article),
            }
          end
        end

        def collect_books(docs, base_url)
          docs.filter_map do |doc|
            next unless Hook.eligible_document?(doc)

            href = Hook.compute_markdown_href(doc)
            card = MdCards.book_doc_to_card_data(doc)
            card[:url] = "#{base_url}#{href}"
            card
          end
        end

        def collect_pages(pages, base_url)
          pages.filter_map do |page|
            next unless Hook.eligible_page?(page)
            next if page.name == 'llms.txt'

            href = Hook.compute_markdown_href(page)
            {
              title: page.data['title'],
              url: "#{base_url}#{href}",
              description: MdCards.extract_plain_description(page.data, type: :article),
            }
          end
        end

        def append_section(sections, heading, entries)
          return if entries.empty?

          lines = [heading]
          entries.each do |entry|
            lines << if entry[:authors]
                       MdCards.render_book_card_md(entry)
                     else
                       MdCards.render_article_card_md(entry)
                     end
          end
          lines << ''
          sections.concat(lines)
        end
      end
    end
  end
end

Liquid::Template.register_tag('llms_txt_index', Jekyll::MarkdownOutput::Tags::LlmsTxtIndexTag)
