# frozen_string_literal: true

module Jekyll
  module Infrastructure
    module LinkCache
      # Validates canonical_url values and rejects a canonical book page that
      # also points to another canonical page. Consumers read the value
      # verbatim, so a local canonical_url must exactly match the target page's
      # URL, including its trailing slash.
      #
      # @validator Book referenced as a canonical target by another book also
      #   has `canonical_url` set (copy-paste error).
      # @validator Book `canonical_url` is not a string or not a local path, has surrounding
      #   whitespace, or names a book page with a different trailing slash
      #   than its url.
      class BookFamilyValidator
        def initialize(site)
          @site = site
        end

        def validate
          check_canonical_format
          errors = find_violations
          raise_if_errors(errors)
        end

        private

        # canonical_url is read verbatim by the link cache, book identity,
        # and SEO code, so a local value must spell the target's url exactly.
        # Normalize only to find a possible target; reject whitespace and
        # trailing-slash differences before consumers can split the family.
        def check_canonical_format
          return unless @site.collections.key?('books')

          docs = @site.collections['books'].docs
          url_by_normalized = docs.to_h { |doc| [normalize_url(doc.url), doc.url] }
          docs.each do |book|
            value = book.data['canonical_url']
            next if value.nil?

            problem = canonical_format_problem(value, url_by_normalized)
            next unless problem

            raise Jekyll::Errors::FatalException,
                  "BookFamilyValidator: canonical_url in '#{book.relative_path}' #{problem}"
          end
        end

        def canonical_format_problem(value, url_by_normalized)
          unless value.is_a?(String)
            return "is not a string: #{value.inspect}. Use a path on this site, such as /books/<name>/."
          end
          return "has leading or trailing whitespace: #{value.inspect}. Remove the whitespace." if value != value.strip
          unless local_path?(value)
            return "is not a local path: #{value.inspect}. Use a path on this site, such as /books/<name>/."
          end

          target = url_by_normalized[normalize_url(value)]
          return if target.nil? || target == value

          "is #{value.inspect}, but the book page's url is #{target.inspect}. Use #{target.inspect}."
        end

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

        # "//host/..." is protocol-relative, so it names another site.
        def local_path?(value)
          value.start_with?('/') && !value.start_with?('//')
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
