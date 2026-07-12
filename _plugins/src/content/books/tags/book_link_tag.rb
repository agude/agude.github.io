# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../core/book_link_resolver'
require_relative '../../../infrastructure/links/link_tag_base'

module Jekyll
  module Books
    module Tags
      # Liquid tag for creating a link to a book page, wrapped in <cite>.
      # Supports optional display text override, author disambiguation, and
      # cite toggle. Arguments can be in flexible order after the title.
      #
      # Usage: {% book_link "Title" [link_text="Display Text"] [author="Author Name"] [cite=false] %}
      #        {% book_link variable [link_text=var2] [author=var3] %}
      #
      # @see Jekyll::Infrastructure::Links::LinkTagBase for the shared tag
      #   structure pattern this is the canonical example of.
      class BookLinkTag < Jekyll::Infrastructure::Links::LinkTagBase
        self.subject = 'book title'
        self.resolver_class = Jekyll::Books::Core::BookLinkResolver
        self.option_spec = { link_text: :value, author: :value, cite: :value }

        private

        def resolver_arguments(context)
          positional = [
            subject_value(context),
            option_value(:link_text, context),
            option_value(:author, context),
          ]
          [positional, { cite: option_enabled?(:cite, context) }]
        end

        def markdown_italic?(data)
          data[:cite]
        end
      end
    end
  end
end

# Register the tag with Liquid so Jekyll recognizes {% book_link ... %}
Liquid::Template.register_tag('book_link', Jekyll::Books::Tags::BookLinkTag)
