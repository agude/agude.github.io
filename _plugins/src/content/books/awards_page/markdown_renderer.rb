# frozen_string_literal: true

require_relative '../../../ui/cards/markdown_card_utils'

module Jekyll
  module Books
    module AwardsPage
      # Markdown renderer for awards page content
      class MarkdownRenderer
        MdCards = Jekyll::UI::Cards::MarkdownCardUtils
        private_constant :MdCards

        def initialize(data)
          @awards_groups = data[:awards_groups]
          @favorites_lists = data[:favorites_lists]
        end

        def render
          lines = []
          lines.concat(render_awards)
          lines.concat(render_favorites)
          lines.join("\n")
        end

        private

        def render_awards
          return [] if @awards_groups.empty?

          lines = ['## Major Awards']
          @awards_groups.each do |group|
            lines << "### #{group[:award_name]}"
            (group[:books] || []).each do |book|
              lines << MdCards.render_book_card_md(MdCards.book_doc_to_card_data(book))
            end
          end
          lines
        end

        def render_favorites
          displayable = @favorites_lists.select { |l| (l[:books] || []).any? }
          return [] if displayable.empty?

          lines = ['## My Favorite Books Lists']
          displayable.each do |list|
            title = list[:post].data['title']
            lines << "### [#{title}](#{list[:post].url})"
            list[:books].each { |book| lines << MdCards.render_book_card_md(MdCards.book_doc_to_card_data(book)) }
          end
          lines
        end
      end
    end
  end
end
