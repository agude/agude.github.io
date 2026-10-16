# frozen_string_literal: true

require_relative '../text_processing_utils'
require_relative 'author_lookup'

module Jekyll
  module Infrastructure
    module LinkCache
      # Resolves the targets of one link tag ({% book_link %}, {% author_link %},
      # {% short_story_link %}, {% series_link %}, {% series_text %}) without
      # rendering it, for BacklinkBuilder.
      #
      # It reads the arguments the tag parsed (`link_arguments`) and applies
      # the same lookups as the tag's resolver: archived reviews are skipped,
      # `author=` disambiguates books, pen names resolve to the canonical
      # author page, `from_book=` picks a short story, and `link=false` links
      # nowhere. Variable arguments cannot be resolved without rendering, so
      # they produce no target, except `page.series` on series tags.
      class LinkTagTargetResolver
        AuthorLookup = Jekyll::Infrastructure::LinkCache::AuthorLookup
        private_constant :AuthorLookup

        # @param link_cache [Hash] the site link cache.
        # @param url_to_doc [Hash] URL => book document or author page.
        def initialize(link_cache, url_to_doc)
          @link_cache = link_cache
          @url_to_doc = url_to_doc
        end

        # The link targets of one tag node, or nil. Reads the arguments the
        # tag itself parsed, so the builder and the renderer see the same
        # subject and options.
        def targets(node, doc)
          case node.tag_name
          when 'book_link'
            extract_book_link(link_arguments(node))
          when 'series_link', 'series_text'
            extract_series_link(link_arguments(node), doc)
          when 'short_story_link'
            extract_short_story_link(link_arguments(node))
          when 'author_link'
            extract_author_link(link_arguments(node))
          end
        end

        private

        def link_arguments(node)
          return node.link_arguments if node.respond_to?(:link_arguments)

          raise Jekyll::Errors::FatalException,
                "BacklinkBuilder: {% #{node.tag_name} %} is a parse-only stub, not the real tag; " \
                'load the tag before building backlinks.'
        end

        # Mirrors BookLinkResolver: archived reviews are never targets, an
        # author option picks among same-titled books, and an ambiguous
        # title with no author option links nowhere (the renderer raises).
        def extract_book_link(args)
          title = literal(args.subject)
          return nil unless title

          locs = @link_cache['books'][normalize(title)]
                 &.reject { |b| b['canonical_url']&.start_with?('/') }
          return nil unless locs&.any?

          target = select_book(locs, literal(args.options[:author]))
          target && [{ url: target['url'], type: 'book' }]
        end

        def select_book(locs, author)
          return (locs.length == 1 ? locs.first : nil) if author.nil? || author.strip.empty?

          authors = @link_cache['authors'] || {}
          wanted = AuthorLookup.canonical_author(author, authors)
          locs.find do |book|
            Array(book['authors']).any? do |name|
              AuthorLookup.canonical_author(name, authors)&.casecmp?(wanted)
            end
          end
        end

        def extract_series_link(args, doc)
          return nil if link_disabled?(args.options[:link])

          title = args.subject == 'page.series' ? doc.data['series'] : literal(args.subject)
          return nil if title.nil? || title.to_s.strip.empty?

          books = @link_cache['series_map'][normalize(title)]
          return nil unless books&.any?

          books.map { |book| { url: book.url, type: 'series' } }
        end

        def extract_short_story_link(args)
          title = literal(args.subject)
          return nil unless title

          locs = @link_cache['short_stories'][normalize(title)]
          return nil unless locs

          target = find_target_story(locs, literal(args.options[:from_book]))
          return nil unless target

          [{ url: target['url'], type: 'short_story' }]
        end

        # Mirrors AuthorLinkResolver: pen names resolve through the 'authors'
        # cache to the canonical page, and link=false renders no link.
        def extract_author_link(args)
          return nil if link_disabled?(args.options[:link])

          name = literal(args.subject)
          return nil unless name

          entry = (@link_cache['authors'] || {})[normalize(name)]
          return nil unless entry && @url_to_doc[entry['url']]

          [{ url: entry['url'], type: 'author' }]
        end

        # The content of a quoted literal, or nil for a variable, which the
        # builder cannot resolve without rendering.
        def literal(markup)
          markup&.match(/\A(['"])(.*)\1\z/m)&.[](2)
        end

        # True when a `link=` option is the literal false, quoted or not.
        def link_disabled?(markup)
          return false unless markup

          (literal(markup) || markup).strip.casecmp?('false')
        end

        def find_target_story(locs, from_book)
          if from_book && !from_book.strip.empty?
            locs.find { |l| l['parent_book_title'].casecmp(from_book).zero? }
          elsif locs.map { |l| l['url'] }.uniq.length == 1
            locs.first
          end
        end

        def normalize(title)
          Jekyll::Infrastructure::TextProcessingUtils.normalize_title(title)
        end
      end
    end
  end
end
