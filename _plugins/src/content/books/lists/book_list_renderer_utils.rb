# frozen_string_literal: true

require 'cgi'
require_relative '../../series/series_link_resolver'
require_relative '../core/book_card_renderer'
require_relative '../../../infrastructure/text_processing_utils'
require_relative '../../../ui/cards/markdown_card_utils'

module Jekyll
  module Books
    module Lists
      # @pattern Render finder-ordered groups with shared headings, navigation, and card grids.
      module BookListRendererUtils
        MdCards = Jekyll::UI::Cards::MarkdownCardUtils
        Text = Jekyll::Infrastructure::TextProcessingUtils
        private_constant :MdCards, :Text

        # @gotcha Prefix series anchors with the author slug on the by-author index.
        #   The same series can occur under multiple authors.
        def self.render_book_groups_html(data, context, generate_nav: false, id_prefix: nil)
          output = (data[:log_messages] || '').dup
          standalone = data[:standalone_books]
          series_groups = data[:series_groups]
          return output if standalone.empty? && series_groups.empty?

          anchors = {}
          level = id_prefix ? 3 : 2
          content = +''
          if standalone.any?
            standalone_id = id_prefix ? "standalone-books-#{id_prefix}" : 'standalone-books'
            anchors['#'] = standalone_id
            content << render_headline('Standalone Books', standalone_id, level: level)
            content << render_card_grid(standalone, context)
          end
          series_groups.each do |group|
            name = group[:name]
            slug = Text.slugify(name)
            slug = "#{id_prefix}--#{slug}" if id_prefix
            register_series_anchor(anchors, name, slug) if generate_nav

            link = Jekyll::Series::SeriesLinkResolver.new(context).resolve(name, nil)
            content << "<h#{level} class=\"series-title\" id=\"#{slug}\">#{link}</h#{level}>\n"
            content << render_card_grid(group[:books], context)
          end

          output << render_alpha_nav(anchors, include_hash: true) if generate_nav
          output << content
        end

        def self.render_by_title_html(groups, context)
          return '' if groups.empty?

          anchors = {}
          sections = render_sections_html(groups, :letter) do |group|
            letter = group[:letter]
            slug = letter == '#' ? 'letter-hash' : "letter-#{letter.downcase}"
            anchors[letter] = slug
            [slug, render_card_grid(group[:books], context)]
          end
          render_alpha_nav(anchors, include_hash: true) + sections
        end

        def self.render_by_year_html(groups, context)
          return '' if groups.empty?

          links = []
          sections = render_sections_html(groups, :year) do |group|
            year = group[:year]
            slug = "year-#{year}"
            links << "<a href=\"##{CGI.escapeHTML(slug)}\">#{CGI.escapeHTML(year)}</a>"
            [slug, render_card_grid(group[:books], context)]
          end
          render_navigation(links, separator: ' &middot; ') + sections
        end

        def self.render_sections_html(groups, label_key)
          groups.map do |group|
            slug, content = yield group
            render_headline(group[label_key], slug) + content
          end.join
        end

        def self.render_headline(label, slug, level: 2)
          "<h#{level} class=\"book-list-headline\" id=\"#{CGI.escapeHTML(slug)}\">" \
            "#{CGI.escapeHTML(label)}</h#{level}>\n"
        end

        def self.render_alpha_nav(anchors, include_hash: false)
          letters = ('A'..'Z').to_a
          letters.unshift('#') if include_hash
          links = letters.map do |letter|
            if anchors.key?(letter)
              "<a href=\"##{CGI.escapeHTML(anchors[letter])}\">#{letter}</a>"
            else
              "<span>#{letter}</span>"
            end
          end
          render_navigation(links, separator: ' ')
        end

        def self.render_navigation(links, separator:)
          "<nav class=\"alpha-jump-links\">\n  #{links.join(separator)}\n</nav>\n"
        end

        def self.render_card_grid(books, context, append_newline: true)
          html = +"<ul class=\"card-grid\">\n"
          books.each do |book|
            html << Jekyll::Books::Core::BookCardRenderer.render(book, context)
            html << "\n" if append_newline
          end
          html << "</ul>\n"
        end

        def self.render_sections_markdown(groups, label_key)
          groups.flat_map { |group| ["## #{group[label_key]}", *yield(group)] }.join("\n")
        end

        def self.render_cards_markdown(books)
          books.map { |book| MdCards.render_card_md(MdCards.book_doc_to_card_data(book), book: true) }
        end

        def self.register_series_anchor(anchors, name, slug)
          sort_key = Text.normalize_title(name, strip_articles: true).sub(/^series\s+/, '').strip
          letter = sort_key.empty? ? '#' : sort_key[0].upcase
          anchors[letter] ||= slug
        end
        private_class_method :register_series_anchor
      end
    end
  end
end
