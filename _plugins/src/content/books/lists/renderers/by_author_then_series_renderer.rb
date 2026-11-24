# frozen_string_literal: true

# Tested by: _tests/src/content/books/tags/test_display_book_lists_tag.rb

require_relative '../book_list_renderer_utils'

module Jekyll
  module Books
    module Lists
      module Renderers
        # Renders author navigation and the standalone and series groups under each author.
        class ByAuthorThenSeriesRenderer
          Html = Jekyll::Books::Lists::BookListRendererUtils
          private_constant :Html

          def initialize(context, data)
            @context = context
            @authors_data = data[:authors_data] || []
          end

          def render
            return '' if @authors_data.empty?

            anchors = {}
            sections = Html.render_sections_html(@authors_data, :author_name) do |author|
              name = author[:author_name]
              slug = author_slug(name)
              anchors[name[0].upcase] ||= slug
              [slug, Html.render_book_groups_html(author, @context, id_prefix: slug)]
            end
            Html.render_alpha_nav(anchors) + sections
          end

          private

          def author_slug(name)
            name.downcase.strip
                .gsub(/\s+/, '-')
                .gsub(/[^\w-]+/, '')
                .gsub(/--+/, '-')
                .gsub(/^-+|-+$/, '')
          end
        end
      end
    end
  end
end
