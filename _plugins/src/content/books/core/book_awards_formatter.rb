# frozen_string_literal: true

require_relative '../../../infrastructure/text_processing_utils'

module Jekyll
  module Books
    module Core
      # Formats book awards and favorites mentions as Markdown text.
      class BookAwardsFormatter
        MdText = Jekyll::Infrastructure::TextProcessingUtils
        private_constant :MdText

        def initialize(awards, mentions)
          @awards = awards
          @mentions = mentions
        end

        def render
          parts = format_awards + format_mentions
          return nil if parts.empty?

          "Awards: #{parts.join(', ')}"
        end

        private

        def format_awards
          return [] unless @awards.is_a?(Array) && !@awards.empty?

          @awards.sort.map do |award|
            label = award.split.map(&:capitalize).join(' ')
            slug = Jekyll::Utils.slugify(award)
            "[#{MdText.escape_link_text(label)}](/books/by-award/##{slug}-award)"
          end
        end

        def format_mentions
          return [] unless @mentions.is_a?(Array) && !@mentions.empty?

          @mentions.sort_by { |p| p.data['is_favorites_list'].to_s }.reverse.map do |post|
            year = post.data['is_favorites_list']
            "[#{MdText.escape_link_text("#{year} Favorites")}](#{MdText.escape_url(post.url)})"
          end
        end
      end
    end
  end
end
