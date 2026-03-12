# frozen_string_literal: true

require_relative '../../infrastructure/generated_static_file'
require_relative '../../infrastructure/markdown_whitespace_normalizer'
require_relative '../books/backlinks/finder'
require_relative '../books/related/finder'
require_relative '../books/reviews/finder'
require_relative '../posts/related/finder'
require_relative '../../infrastructure/text_processing_utils'
require_relative 'markdown_body_hook'
require_relative 'markdown_card_utils'
require_relative 'markdown_link_formatter'
require_relative '../books/core/book_awards_formatter'
require_relative 'tags/llms_txt_index_tag'

module Jekyll
  module MarkdownOutput
    # Assembles final .md files from markdown_body data set by the
    # :pre_render hooks. Runs as a :site, :post_render hook after all
    # documents and pages have been rendered.
    module MarkdownOutputAssembler
      Normalizer = Jekyll::Infrastructure::MarkdownWhitespaceNormalizer
      Text = Jekyll::Infrastructure::TextProcessingUtils
      MdLink = Jekyll::MarkdownOutput::MarkdownLinkFormatter
      private_constant :Normalizer, :Text, :MdLink

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
        sections << build_header(item, site: site)
        sections << item.data['markdown_body']
        sections << build_book_footer(site, item) if site && item.data['layout'] == 'book'
        sections << build_post_footer(site, item) if site && item.data['layout'] == 'post'
        raw = sections.compact.reject { |s| s.to_s.strip.empty? }.join("\n\n")
        Normalizer.normalize(raw)
      end

      def self.build_header(item, site: nil)
        layout = item.data['layout']
        case layout
        when 'post'     then build_post_header(item)
        when 'book'     then build_book_header(item, site)
        when 'category' then build_category_header(item)
        when 'resume'   then nil
        else                 build_title_only_header(item)
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

      def self.build_book_header(item, site)
        title = item.data['title']
        authors = item.data['book_authors']
        series = item.data['series']
        book_number = item.data['book_number']
        rating = item.data['rating']
        image = item.data['image']
        cache = site&.data&.dig('link_cache') || {}

        lines = ["# #{title}"]
        lines << "![Book cover of #{Text.escape_link_text(title)}](#{Text.escape_url(image)})" if image
        details = []
        details << format_authors(authors, cache) if authors
        details << format_series(series, book_number, cache) if series
        details << format_awards(item, site) if site
        details << format_rating(rating) if rating
        details.compact!
        lines << details.join("\n") unless details.empty?
        lines << '## Review'
        lines.join("\n\n")
      end

      def self.build_category_header(item)
        title = item.data['category-title'] || item.data['title']
        "# Topic: #{title}"
      end

      def self.build_title_only_header(item)
        "# #{item.data['title']}"
      end

      # --- Book footer sections (related, backlinks, previous reviews) ---

      def self.build_book_footer(site, item)
        page = page_data_for(item)
        sections = []
        sections << build_backlinks_section(site, page)
        sections << build_previous_reviews_section(site, page)
        sections << build_related_books_section(site, page)
        sections.compact.reject { |s| s.to_s.strip.empty? }.join("\n\n")
      end

      def self.build_related_books_section(site, item)
        result = Jekyll::Books::Related::Finder.new(site, item).find
        books = result[:books]
        return nil if books.empty?

        cache = site.data['link_cache'] || {}
        lines = ['## Related Books']
        books.each do |book|
          authors = book.data['book_authors']
          author_list = authors.is_a?(Array) ? authors : [authors].compact
          author_urls = resolve_author_urls(author_list, cache)
          card_data = MarkdownCardUtils.book_doc_to_card_data(book, author_urls: author_urls)
          lines << MarkdownCardUtils.render_book_card_md(card_data)
        end
        lines.join("\n")
      end

      def self.build_backlinks_section(site, item)
        result = Jekyll::Books::Backlinks::Finder.new(site, item).find
        backlinks = result[:backlinks]
        return nil if backlinks.empty?

        has_series = false
        lines = ["## Reviews that mention _#{item['title']}_"]
        backlinks.each do |title, url, type|
          entry = MdLink.format_link({ status: :found, url: url, display_text: title }, italic: true)
          if type == 'series'
            entry = "- #{entry}\u2020"
            has_series = true
          else
            entry = "- #{entry}"
          end
          lines << entry
        end
        lines << '' << "\u2020 _Mentioned via a link to the series._" if has_series
        lines.join("\n")
      end

      def self.build_previous_reviews_section(site, item)
        result = Jekyll::Books::Reviews::Finder.new(site, item).find
        reviews = result[:reviews]
        return nil if reviews.empty?

        cache = site.data['link_cache'] || {}
        lines = ['## Previous Reviews']
        reviews.each do |review|
          authors = review.data['book_authors']
          author_list = authors.is_a?(Array) ? authors : [authors].compact
          author_urls = resolve_author_urls(author_list, cache)
          card_data = MarkdownCardUtils.book_doc_to_card_data(review, author_urls: author_urls)
          lines << MarkdownCardUtils.render_book_card_md(card_data)
        end
        lines.join("\n")
      end

      # --- Post footer sections (related posts) ---

      def self.build_post_footer(site, item)
        page = page_data_for(item)
        build_related_posts_section(site, page)
      end

      def self.build_related_posts_section(site, page)
        result = Jekyll::Posts::Related::Finder.new(site, page).find
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

      def self.resolve_author_urls(author_list, cache)
        author_cache = cache['authors'] || {}
        urls = {}
        author_list.each do |name|
          data = author_cache[Text.normalize_title(name)]
          urls[name] = data['url'] if data
        end
        urls
      end
      private_class_method :resolve_author_urls

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
      rescue NoMethodError, ArgumentError
        date.to_s
      end
      private_class_method :format_date

      def self.format_authors(authors, cache)
        author_list = authors.is_a?(Array) ? authors : [authors]
        formatted = author_list.map { |name| format_author_name(name, cache) }
        "by #{formatted.join(' and ')}"
      end
      private_class_method :format_authors

      def self.format_author_name(name, cache)
        author_cache = cache['authors'] || {}
        normalized = Text.normalize_title(name)
        data = author_cache[normalized]
        return name unless data

        MdLink.format_link({ status: :found, url: data['url'], display_text: data['title'] || name })
      end
      private_class_method :format_author_name

      def self.format_series(series, book_number, cache)
        series_name = format_series_name(series, cache)
        return "#{series_name} series" unless book_number

        "Book #{book_number} of #{series_name}"
      end
      private_class_method :format_series

      def self.format_series_name(name, cache)
        series_cache = cache['series'] || {}
        normalized = Text.normalize_title(name)
        data = series_cache[normalized]
        return name unless data

        MdLink.format_link({ status: :found, url: data['url'], display_text: data['title'] || name })
      end
      private_class_method :format_series_name

      def self.format_awards(item, site)
        awards = item.data['awards']
        mentions = site.data.dig('link_cache', 'favorites_mentions', item.url)
        Jekyll::Books::Core::BookAwardsFormatter.new(awards, mentions).render
      end
      private_class_method :format_awards

      def self.format_rating(rating)
        MarkdownCardUtils.format_stars(rating)
      end
      private_class_method :format_rating
    end
  end
end

# Hook: runs after all documents/pages have been rendered
Jekyll::Hooks.register :site, :post_render do |site|
  Jekyll::MarkdownOutput::MarkdownOutputAssembler.assemble_all(site)
end
