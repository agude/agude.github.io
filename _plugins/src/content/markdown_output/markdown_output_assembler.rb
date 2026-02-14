# frozen_string_literal: true

require_relative '../../infrastructure/generated_static_file'
require_relative '../../infrastructure/markdown_whitespace_normalizer'
require_relative '../books/backlinks/finder'
require_relative '../books/related/finder'
require_relative '../books/reviews/finder'
require_relative '../posts/related/finder'
require_relative 'markdown_body_hook'
require_relative 'markdown_card_utils'
require_relative 'llms_txt_generator'

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

          md_content = assemble_markdown(item, site: site)
          add_static_file(site, item, md_content)
        end
      end

      def self.assemble_markdown(item, site: nil)
        sections = []
        sections << build_header(item)
        sections << item.data['markdown_body']
        sections << build_book_footer(site, item) if site && item.data['layout'] == 'book'
        sections << build_post_footer(site, item) if site && item.data['layout'] == 'post'
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

      # --- Book footer sections (related, backlinks, previous reviews) ---

      def self.build_book_footer(site, item)
        page = page_data_for(item)
        sections = []
        sections << build_related_books_section(site, page)
        sections << build_backlinks_section(site, page)
        sections << build_previous_reviews_section(site, page)
        sections.compact.reject { |s| s.to_s.strip.empty? }.join("\n\n")
      end

      MAX_RELATED_BOOKS = 6
      private_constant :MAX_RELATED_BOOKS

      def self.build_related_books_section(site, item)
        result = Jekyll::Books::Related::Finder.new(site, item, MAX_RELATED_BOOKS).find
        books = result[:books]
        return nil if books.empty?

        lines = ['## Related Books']
        books.each { |book| lines << MarkdownCardUtils.render_book_card_md(book_doc_to_card_data(book)) }
        lines.join("\n")
      end

      def self.build_backlinks_section(site, item)
        result = Jekyll::Books::Backlinks::Finder.new(site, item).find
        backlinks = result[:backlinks]
        return nil if backlinks.empty?

        lines = ['## Mentioned In']
        backlinks.each { |title, url, _type| lines << "- [#{title}](#{url})" }
        lines.join("\n")
      end

      def self.build_previous_reviews_section(site, item)
        result = Jekyll::Books::Reviews::Finder.new(site, item).find
        reviews = result[:reviews]
        return nil if reviews.empty?

        lines = ['## Previous Reviews']
        reviews.each { |review| lines << MarkdownCardUtils.render_book_card_md(book_doc_to_card_data(review)) }
        lines.join("\n")
      end

      # --- Post footer sections (related posts) ---

      MAX_RELATED_POSTS = 6
      private_constant :MAX_RELATED_POSTS

      def self.build_post_footer(site, item)
        page = page_data_for(item)
        build_related_posts_section(site, page)
      end

      def self.build_related_posts_section(site, page)
        result = Jekyll::Posts::Related::Finder.new(site, page, MAX_RELATED_POSTS).find
        posts = result[:posts]
        return nil if posts.empty?

        lines = ['## Related Posts']
        posts.each { |post| lines << MarkdownCardUtils.render_article_card_md(post_doc_to_card_data(post)) }
        lines.join("\n")
      end

      def self.post_doc_to_card_data(doc)
        { title: doc.data['title'], url: doc.url }
      end
      private_class_method :post_doc_to_card_data

      def self.book_doc_to_card_data(doc)
        authors = doc.data['book_authors']
        author_list = authors.is_a?(Array) ? authors : [authors].compact
        {
          title: doc.data['title'],
          url: doc.url,
          authors: author_list,
          rating: doc.data['rating']
        }
      end
      private_class_method :book_doc_to_card_data

      def self.add_static_file(site, item, content)
        href = item.data['markdown_alternate_href']
        dir = File.dirname(href)
        name = File.basename(href)
        file = Jekyll::Infrastructure::GeneratedStaticFile.new(site, dir, name, content)
        site.static_files << file
      end

      # --- Private helpers ---

      # Build a page-data hash compatible with Finder prerequisite checks.
      # Finders expect page['url'], page['title'], etc. via hash access,
      # but Jekyll::Document stores url as a method, not in data[].
      def self.page_data_for(item)
        item.data.merge('url' => item.url)
      end
      private_class_method :page_data_for

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
  Jekyll::MarkdownOutput::LlmsTxtGenerator.generate(site)
end
