# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../awards_page/finder'
require_relative '../awards_page/html_renderer'
require_relative '../awards_page/markdown_renderer'

# Liquid Tag to display the entire content of the "By Award" page,
# including a unified navigation bar, the list of books grouped by major awards,
# and the list of "Favorite Books" posts.
#
# This tag consolidates the functionality of the old `display_books_by_award`
# and `display_favorite_books_lists` tags.
#
# Usage: {% display_awards_page %}
module Jekyll
  module Books
    module Tags
      # Liquid tag for rendering the complete awards page content.
      # Displays major awards and favorite books lists with unified navigation.
      class DisplayAwardsPageTag < Liquid::Tag
        def initialize(tag_name, markup, tokens)
          super
          return if markup.strip.empty?

          raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
        end

        def render(context)
          data = Jekyll::Books::AwardsPage::Finder.new(context).find
          if context.registers[:render_mode] == :markdown
            Jekyll::Books::AwardsPage::MarkdownRenderer.new(data).render
          else
            Jekyll::Books::AwardsPage::HtmlRenderer.new(context, data).render
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('display_awards_page', Jekyll::Books::Tags::DisplayAwardsPageTag)
