# frozen_string_literal: true

module Jekyll
  module MarkdownOutput
    # Converts card data hashes (from BookCardRenderer.extract_data and
    # ArticleCardRenderer.extract_data) into Markdown list items.
    module MarkdownCardUtils
      # Convert a Jekyll book document into a card data hash.
      # Pass author_urls: { 'Name' => '/url/' } for linked authors.
      def self.book_doc_to_card_data(doc, author_urls: {})
        authors = doc.data['book_authors']
        author_list = authors.is_a?(Array) ? authors : [authors].compact
        {
          title: doc.data['title'],
          url: doc.url,
          authors: author_list,
          author_urls: author_urls,
          rating: doc.data['rating'],
        }
      end

      # Format a numeric rating as Unicode stars (e.g. "★★★★☆").
      # Returns nil for invalid ratings.
      def self.format_stars(rating)
        rating_int = rating.to_i
        return nil unless (1..5).include?(rating_int)

        ("\u2605" * rating_int) + ("\u2606" * (5 - rating_int))
      end

      def self.render_book_card_md(data)
        line = "- [_#{data[:title]}_](#{data[:url]})"
        line += " by #{format_card_authors(data)}" if data[:authors]&.any?
        stars = format_stars(data[:rating])
        line += " --- #{stars}" if stars
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
