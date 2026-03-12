# frozen_string_literal: true

require_relative '../../infrastructure/text_processing_utils'
require_relative '../../ui/cards/card_data_extractor_utils'

module Jekyll
  module MarkdownOutput
    # Converts card data hashes (from BookCardRenderer.extract_data and
    # ArticleCardRenderer.extract_data) into Markdown list items.
    module MarkdownCardUtils
      Text = Jekyll::Infrastructure::TextProcessingUtils

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
          description: extract_plain_description(doc.data, type: :book),
        }
      end

      # Extract a plain-text description from a Jekyll data hash.
      # Reuses CardDataExtractorUtils for HTML extraction, then strips tags.
      def self.extract_plain_description(data_source, type: :article)
        html = Jekyll::UI::Cards::CardDataExtractorUtils.extract_description_html(
          data_source, type: type,
        )
        return nil if html.empty?

        text = Text.strip_tags(html).gsub(/\s+/, ' ').strip
        text.empty? ? nil : text
      end

      # Format a numeric rating as Unicode stars (e.g. "★★★★☆").
      # Returns nil for invalid ratings.
      def self.format_stars(rating)
        rating_int = rating.to_i
        return nil unless (1..5).include?(rating_int)

        ("\u2605" * rating_int) + ("\u2606" * (5 - rating_int))
      end

      def self.render_book_card_md(data)
        line = "- [_#{Text.escape_link_text(data[:title])}_](#{Text.escape_url(data[:url])})"
        line += " by #{format_card_authors(data)}" if data[:authors]&.any?
        stars = format_stars(data[:rating])
        line += " --- #{stars}" if stars
        line += ": #{data[:description]}" if data[:description]
        line
      end

      def self.format_card_authors(data)
        urls = data[:author_urls] || {}
        data[:authors].map do |name|
          url = urls[name]
          url ? "[#{Text.escape_link_text(name)}](#{Text.escape_url(url)})" : name
        end.join(', ')
      end
      private_class_method :format_card_authors

      def self.render_article_card_md(data)
        line = "- [#{Text.escape_link_text(data[:title])}](#{Text.escape_url(data[:url])})"
        line += ": #{data[:description]}" if data[:description]
        line
      end
    end
  end
end
