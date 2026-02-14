# frozen_string_literal: true

require_relative '../../infrastructure/generated_static_file'
require_relative '../../infrastructure/markdown_whitespace_normalizer'
require_relative 'markdown_body_hook'

module Jekyll
  module MarkdownOutput
    # Assembles final .md files from markdown_body data set by the
    # :pre_render hooks. Runs as a :site, :post_render hook after all
    # documents and pages have been rendered.
    module MarkdownOutputAssembler
      Normalizer = Jekyll::Infrastructure::MarkdownWhitespaceNormalizer
      private_constant :Normalizer

      def self.assemble_all(site)
        return unless MarkdownBodyHook.enabled?(site)

        process_items(site, site.posts.docs)
        process_items(site, site.collections['books']&.docs || [])
        process_items(site, site.pages)
      end

      def self.process_items(site, items)
        items.each do |item|
          next unless item.data['markdown_body']

          md_content = assemble_markdown(item)
          add_static_file(site, item, md_content)
        end
      end

      def self.assemble_markdown(item)
        sections = []
        sections << build_header(item)
        sections << item.data['markdown_body']
        raw = sections.compact.reject { |s| s.to_s.strip.empty? }.join("\n\n")
        Normalizer.normalize(raw)
      end

      def self.build_header(item)
        layout = item.data['layout']
        case layout
        when 'post' then build_post_header(item)
        when 'book' then build_book_header(item)
        else             build_title_only_header(item)
        end
      end

      def self.build_post_header(item)
        title = item.data['title']
        date = item.data['date']
        categories = item.data['categories'] || []

        lines = ["# #{title}"]
        meta_parts = []
        meta_parts << "*#{format_date(date)}*" if date
        meta_parts << categories.map { |c| "##{c}" }.join(', ') unless categories.empty?
        lines << meta_parts.join(' | ') unless meta_parts.empty?
        lines.join("\n\n")
      end

      def self.build_book_header(item)
        title = item.data['title']
        authors = item.data['book_authors']
        series = item.data['series']
        book_number = item.data['book_number']
        rating = item.data['rating']

        lines = ["# #{title}"]
        details = []
        details << format_authors(authors) if authors
        details << format_series(series, book_number) if series
        details << format_rating(rating) if rating
        lines << details.join("\n") unless details.empty?
        lines << '## Review'
        lines.join("\n\n")
      end

      def self.build_title_only_header(item)
        "# #{item.data['title']}"
      end

      def self.add_static_file(site, item, content)
        href = item.data['markdown_alternate_href']
        dir = File.dirname(href)
        name = File.basename(href)
        file = Jekyll::Infrastructure::GeneratedStaticFile.new(site, dir, name, content)
        site.static_files << file
      end

      # --- Private helpers ---

      def self.format_date(date)
        date.strftime('%B %-d, %Y')
      rescue StandardError
        date.to_s
      end
      private_class_method :format_date

      def self.format_authors(authors)
        author_list = authors.is_a?(Array) ? authors : [authors]
        "by #{author_list.join(' and ')}"
      end
      private_class_method :format_authors

      def self.format_series(series, book_number)
        return "#{series} series" unless book_number

        "Book #{book_number} of #{series}"
      end
      private_class_method :format_series

      def self.format_rating(rating)
        rating_int = rating.to_i
        return nil unless (1..5).include?(rating_int)

        ("\u2605" * rating_int) + ("\u2606" * (5 - rating_int))
      end
      private_class_method :format_rating
    end
  end
end

# Hook: runs after all documents/pages have been rendered
Jekyll::Hooks.register :site, :post_render do |site|
  Jekyll::MarkdownOutput::MarkdownOutputAssembler.assemble_all(site)
end
