# frozen_string_literal: true

require 'cgi'
require_relative '../core/book_card_renderer'
require_relative '../../../infrastructure/text_processing_utils'

module Jekyll
  module Books
    module AwardsPage
      # Renders the awards page as HTML.
      class HtmlRenderer
        def initialize(context, data)
          @context = context
          @site = context.registers[:site]
          @baseurl = @site.config['baseurl'] || ''
          @awards_groups = data[:awards_groups]
          @favorites_lists = data[:favorites_lists]
          @log_messages = data[:log_messages]
        end

        def render
          return @log_messages if empty_data?

          output = +@log_messages
          output << render_navigation
          output << render_awards_section
          output << render_favorites_section
          output
        end

        private

        def empty_data?
          @awards_groups.empty? && @favorites_lists.empty?
        end

        def render_navigation
          award_links = generate_award_links
          fav_links = generate_favorite_links

          return '' if award_links.empty? && fav_links.empty?

          html = +"<nav class=\"alpha-jump-links\">\n"
          html << "  <div class=\"nav-row\">#{award_links.join(' &middot; ')}</div>\n" if award_links.any?
          if fav_links.any?
            fav_content = fav_links.join(' &middot; ')
            html << "  <div class=\"nav-row\"><span class=\"nav-label\">Best of:</span> #{fav_content}</div>\n"
          end
          html << "</nav>\n"
        end

        def generate_award_links
          @awards_groups.map do |group|
            text = CGI.escapeHTML(group[:award_name].sub(/ Award$/, ''))
            "<a href=\"##{group[:award_slug]}\">#{text}</a>"
          end
        end

        def generate_favorite_links
          displayable_favorites.map do |list|
            title = list[:post].data['title']
            slug = Jekyll::Infrastructure::TextProcessingUtils.slugify(title)
            year = list[:post].data['is_favorites_list']
            link_text = year ? year.to_s : title
            "<a href=\"##{slug}\">#{CGI.escapeHTML(link_text)}</a>"
          end
        end

        def displayable_favorites
          @favorites_lists.select { |list| list[:books].any? }
        end

        def render_awards_section
          return '' if @awards_groups.empty?

          html = +"<h2>Major Awards</h2>\n"
          @awards_groups.each do |group|
            slug = CGI.escapeHTML(group[:award_slug] || '')
            name = CGI.escapeHTML(group[:award_name] || '')

            html << "<h3 class=\"book-list-headline\" id=\"#{slug}\">#{name}</h3>\n"
            html << render_book_grid(group[:books], append_newline: false)
          end
          html
        end

        def render_favorites_section
          return '' if displayable_favorites.empty?

          html = +"<h2>My Favorite Books Lists</h2>\n"
          displayable_favorites.each do |list|
            html << render_favorite_list_header(list[:post])
            html << render_book_grid(list[:books], append_newline: true)
          end
          html
        end

        def render_favorite_list_header(post)
          url = "#{@baseurl}#{post.url}"
          title = CGI.escapeHTML(post.data['title'])
          slug = Jekyll::Infrastructure::TextProcessingUtils.slugify(post.data['title'])

          "<h3 class=\"book-list-headline\" id=\"#{slug}\"><a href=\"#{url}\">#{title}</a></h3>\n"
        end

        def render_book_grid(books, append_newline:)
          html = +"<ul class=\"card-grid\">\n"
          books.each do |book|
            html << Jekyll::Books::Core::BookCardRenderer.render(book, @context)
            html << "\n" if append_newline
          end
          html << "</ul>\n"
        end
      end
    end
  end
end
