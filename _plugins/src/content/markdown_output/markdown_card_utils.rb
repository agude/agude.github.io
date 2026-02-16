# frozen_string_literal: true

# _plugins/src/content/markdown_output/markdown_card_utils.rb

module Jekyll
  module MarkdownOutput
    # Converts card data hashes (from BookCardRenderer.extract_data and
    # ArticleCardRenderer.extract_data) into Markdown list items.
    module MarkdownCardUtils
      def self.render_book_card_md(data)
        line = "- [_#{data[:title]}_](#{data[:url]})"
        line += " by #{format_card_authors(data)}" if data[:authors]&.any?
        if data[:rating]
          filled = data[:rating].to_i
          empty = 5 - filled
          stars = ("\u2605" * filled) + ("\u2606" * empty)
          line += " --- #{stars}"
        end
        line
      end

      def self.format_card_authors(data)
        urls = data[:author_urls] || {}
        data[:authors].map do |name|
          url = urls[name]
          url ? "[#{name}](#{url})" : name
        end.join(', ')
      end
      private_class_method :format_card_authors

      def self.render_article_card_md(data)
        "- [#{data[:title]}](#{data[:url]})"
      end
    end
  end
end
