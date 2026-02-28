# frozen_string_literal: true

module Jekyll
  module Infrastructure
    module LinkCache
      # Validates that canonical book pages do not have canonical_url in front
      # matter. A canonical page is one that other books reference via their
      # canonical_url field. If the target itself also has canonical_url,
      # find_candidates will reject it and book_link resolution silently breaks.
      class BookFamilyValidator
        def initialize(site)
          @site = site
        end

        def validate
          errors = find_violations
          raise_if_errors(errors)
        end

        private

        def find_violations
          return [] unless @site.collections.key?('books')

          books = @site.collections['books'].docs.reject { |b| b.data['published'] == false }

          # URLs that other books point to as their canonical page.
          # Filter to local paths only — external URLs are not our pages.
          canonical_targets = books
                              .filter_map { |b| b.data['canonical_url'] }
                              .select { |url| url.start_with?('/') }
                              .to_set { |url| normalize_url(url) }

          books.each_with_object([]) do |book, errors|
            next unless canonical_targets.include?(normalize_url(book.url))
            next unless book.data['canonical_url']

            errors << { path: book.relative_path, url: book.url }
          end
        end

        def normalize_url(url)
          url.chomp('/')
        end

        def raise_if_errors(errors)
          return if errors.empty?

          msg = +'BookFamilyValidator: Canonical book pages must not have ' \
                 '`canonical_url` in front matter. These pages are referenced ' \
                 'as canonical targets by other books but also set canonical_url ' \
                 "themselves. Remove `canonical_url` from:\n"
          errors.each do |error|
            msg << "  - #{error[:path]} (url: #{error[:url]})\n"
          end
          raise Jekyll::Errors::FatalException, msg
        end
      end
    end
  end
end
