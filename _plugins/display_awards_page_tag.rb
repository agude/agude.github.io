# frozen_string_literal: true

# _plugins/display_awards_page_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'utils/book_list_utils'
require_relative 'utils/book_card_utils'
require_relative 'utils/text_processing_utils'

module Jekyll
  # Liquid Tag to display the entire content of the "By Award" page,
  # including a unified navigation bar, the list of books grouped by major awards,
  # and the list of "Favorite Books" posts.
  #
  # This tag consolidates the functionality of the old `display_books_by_award`
  # and `display_favorite_books_lists` tags.
  #
  # Usage: {% display_awards_page %}
  #
  class DisplayAwardsPageTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      return if markup.strip.empty?

      raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
    end

    def render(context)
      site = context.registers[:site]
      baseurl = site.config['baseurl'] || ''

      # --- Step 1: Fetch Data for Both Sections ---
      awards_data_hash = BookListUtils.get_data_for_all_books_by_award_display(site: site, context: context)
      favorites_data_hash = BookListUtils.get_data_for_favorites_lists(site: site, context: context)

      output = (awards_data_hash[:log_messages] || '') + (favorites_data_hash[:log_messages] || '')
      awards_groups = awards_data_hash[:awards_data] || []
      favorites_lists = favorites_data_hash[:favorites_lists] || []

      return output if awards_groups.empty? && favorites_lists.empty?

      # --- Step 2: Generate Unified Navigation Bar ---
      award_nav_links = []
      awards_groups.each do |award_group|
        link_text = CGI.escapeHTML(award_group[:award_name].sub(/ Award$/, ''))
        award_nav_links << "<a href=\"##{award_group[:award_slug]}\">#{link_text}</a>"
      end

      favorites_nav_links = []
      favorites_lists.each do |list_data|
        post_title = list_data[:post].data['title']
        slug = TextProcessingUtils.slugify(post_title)
        favorites_nav_links << "<a href=\"##{slug}\">#{CGI.escapeHTML(post_title)}</a>"
      end

      if award_nav_links.any? || favorites_nav_links.any?
        output << "<nav class=\"alpha-jump-links\">\n"
        output << "  <div class=\"nav-row\">#{award_nav_links.join(' &middot; ')}</div>\n" if award_nav_links.any?
        if favorites_nav_links.any?
          output << "  <div class=\"nav-row\">#{favorites_nav_links.join(' &middot; ')}</div>\n"
        end
        output << "</nav>\n"
      end

      # --- Step 3: Render "Major Awards" Section ---
      unless awards_groups.empty?
        output << "<h2>Major Awards</h2>\n"
        awards_groups.each do |award_group|
          escaped_slug = CGI.escapeHTML(award_group[:award_slug] || '')
          escaped_name = CGI.escapeHTML(award_group[:award_name] || '')

          output << "<h3 class=\"book-list-headline\" id=\"#{escaped_slug}\">#{escaped_name}</h3>\n"
          output << "<div class=\"card-grid\">\n"
          award_group[:books].each do |book|
            output << BookCardUtils.render(book, context)
          end
          output << "</div>\n"
        end
      end

      # --- Step 4: Render "My Favorite Books Lists" Section ---
      unless favorites_lists.empty?
        output << "<h2>My Favorite Books Lists</h2>\n"
        favorites_lists.each do |list_data|
          post = list_data[:post]
          books = list_data[:books]
          next if books.empty?

          post_url = "#{baseurl}#{post.url}"
          post_title = post.data['title']
          escaped_title = CGI.escapeHTML(post_title)
          slug = TextProcessingUtils.slugify(post_title)

          output << "<h3 class=\"book-list-headline\" id=\"#{slug}\"><a href=\"#{post_url}\">#{escaped_title}</a></h3>\n"
          output << "<div class=\"card-grid\">\n"
          books.each do |book|
            output << BookCardUtils.render(book, context) << "\n"
          end
          output << "</div>\n"
        end
      end

      output
    end
  end
end

Liquid::Template.register_tag('display_awards_page', Jekyll::DisplayAwardsPageTag)
