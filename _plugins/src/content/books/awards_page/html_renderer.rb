# frozen_string_literal: true

require 'cgi'
require_relative '../lists/book_list_renderer_utils'
require_relative '../../../infrastructure/text_processing_utils'

module Jekyll
  module Books
    module AwardsPage
      # Renders the awards page as HTML.
      class HtmlRenderer
        ListsRenderer = Jekyll::Books::Lists::BookListRendererUtils
        private_constant :ListsRenderer

        def initialize(context, data)
          @context = context
          @site = context.registers[:site]
          @baseurl = @site.config['baseurl'] || ''
          @awards_groups = data[:awards_groups]
          @favorites_lists = data[:favorites_lists]
        end

        def render
          return '' if @awards_groups.empty? && @favorites_lists.empty?

          render_navigation + render_awards_section + render_favorites_section
        end

        private

        def render_navigation
          award_links = generate_award_links
          fav_links = generate_favorite_links

          return '' if award_links.empty? && fav_links.empty?

          rows = []
          rows << "<div class=\"nav-row\">#{award_links.join(' &middot; ')}</div>" if award_links.any?
          if fav_links.any?
            fav_content = fav_links.join(' &middot; ')
            rows << "<div class=\"nav-row\"><span class=\"nav-label\">Best of:</span> #{fav_content}</div>"
          end
          ListsRenderer.render_navigation(rows, separator: "\n  ")
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
            html << ListsRenderer.render_headline(group[:award_name], group[:award_slug], level: 3)
            html << ListsRenderer.render_card_grid(group[:books], @context, append_newline: false)
          end
          html
        end

        def render_favorites_section
          return '' if displayable_favorites.empty?

          html = +"<h2>My Favorite Books Lists</h2>\n"
          displayable_favorites.each do |list|
            html << render_favorite_list_header(list[:post])
            html << ListsRenderer.render_card_grid(list[:books], @context)
          end
          html
        end

        def render_favorite_list_header(post)
          url = "#{@baseurl}#{post.url}"
          title = CGI.escapeHTML(post.data['title'])
          slug = Jekyll::Infrastructure::TextProcessingUtils.slugify(post.data['title'])

          "<h3 class=\"book-list-headline\" id=\"#{slug}\"><a href=\"#{url}\">#{title}</a></h3>\n"
        end
      end
    end
  end
end
