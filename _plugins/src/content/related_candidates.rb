# frozen_string_literal: true

module Jekyll
  module Content
    # Shared selection rules for the collection and configured fallback lists.
    module RelatedCandidates
      # @gotcha Jekyll decides which future documents to write using site.time.
      def self.select(documents, excluded_urls, now)
        documents.select do |document|
          next unless yield(document)
          next if document.data['published'] == false
          next if excluded_urls.include?(document.url)
          next unless document.date

          document.date.to_time.to_i <= now
        end
      end

      def self.limit(documents, maximum)
        documents.uniq(&:url).slice(0, maximum)
      end
    end
  end
end
