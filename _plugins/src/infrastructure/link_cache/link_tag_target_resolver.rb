# frozen_string_literal: true

require_relative '../tag_argument_utils'
require_relative '../text_processing_utils'
require_relative 'book_candidate_selector'
require_relative 'short_story_location_selector'

module Jekyll
  module Infrastructure
    module LinkCache
      # Resolves the targets of one link tag ({% book_link %}, {% author_link %},
      # {% short_story_link %}, {% series_link %}, {% series_text %}) without
      # rendering it, for BacklinkBuilder.
      #
      # It reads the arguments the tag parsed (`link_arguments`) and applies
      # the same lookups as the tag's resolver: archived reviews are skipped,
      # pen names resolve to the canonical author page, and `link=false`
      # links nowhere. The book-author and short-story location rules are
      # not copied here: BookCandidateSelector and ShortStoryLocationSelector
      # hold the one copy that the renderers also call.
      #
      # A variable subject cannot be resolved without rendering, so it
      # produces no target, except `page.series` on series tags. A variable
      # `author=`, `from_book=`, or `link=` stops the build: guessing its
      # value can record a backlink the rendered page does not have, or miss
      # one it does. For `link=`, the unquoted Liquid literals `true`,
      # `false`, and `nil` are values, not variables.
      class LinkTagTargetResolver
        BookSelector = Jekyll::Infrastructure::LinkCache::BookCandidateSelector
        LocationSelector = Jekyll::Infrastructure::LinkCache::ShortStoryLocationSelector
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        # The unquoted values Liquid reads as literals rather than variable
        # names. Liquid literals are case-sensitive, so `FALSE` is a variable.
        LINK_LITERALS = %w[true false nil].freeze
        private_constant :BookSelector, :LocationSelector, :TagArgs, :LINK_LITERALS

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
            extract_book_link(link_arguments(node), node, doc)
          when 'series_link', 'series_text'
            extract_series_link(link_arguments(node), node, doc)
          when 'short_story_link'
            extract_short_story_link(link_arguments(node), node, doc)
          when 'author_link'
            extract_author_link(link_arguments(node), node, doc)
          end
        end

        private

        def link_arguments(node)
          return node.link_arguments if node.respond_to?(:link_arguments)

          raise Jekyll::Errors::FatalException,
                "BacklinkBuilder: {% #{node.tag_name} %} is a parse-only stub, not the real tag; " \
                'load the tag before building backlinks.'
        end

        # Mirrors BookLinkResolver: archived reviews are never targets, and
        # BookCandidateSelector picks among same-titled books. An author
        # mismatch, or an ambiguous title with no author option (the renderer
        # raises), links nowhere.
        def extract_book_link(args, node, doc)
          author = literal_option(args, :author, node, doc)
          title = literal(args.subject)
          return nil unless title

          locs = @link_cache['books'][normalize(title)]
                 &.reject { |b| b['canonical_url']&.start_with?('/') }
          return nil unless locs&.any?

          target = BookSelector.select_book(locs, author, @link_cache['authors'])
          target.is_a?(Hash) ? [{ url: target['url'], type: 'book' }] : nil
        end

        def extract_series_link(args, node, doc)
          return nil if link_disabled?(args.options[:link], node, doc)

          title = args.subject == 'page.series' ? doc.data['series'] : literal(args.subject)
          return nil if title.nil? || title.to_s.strip.empty?

          books = @link_cache['series_map'][normalize(title)]
          return nil unless books&.any?

          books.map { |book| { url: book.url, type: 'series' } }
        end

        # Mirrors ShortStoryResolver through ShortStoryLocationSelector.
        def extract_short_story_link(args, node, doc)
          from_book = literal_option(args, :from_book, node, doc)
          title = literal(args.subject)
          return nil unless title

          locs = @link_cache['short_stories'][normalize(title)]
          return nil if locs.nil? || locs.empty?

          target = LocationSelector.select_location(locs, @link_cache['url_to_canonical_map'], from_book)
          target.is_a?(Hash) ? [{ url: target['url'], type: 'short_story' }] : nil
        end

        # Mirrors AuthorLinkResolver: pen names resolve through the 'authors'
        # cache to the canonical page, and link=false renders no link.
        def extract_author_link(args, node, doc)
          return nil if link_disabled?(args.options[:link], node, doc)

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

        # The literal value of a value option, or nil when it is absent.
        def literal_option(args, name, node, doc)
          markup = args.options[name]
          return nil if markup.nil?

          literal(markup) || raise_variable_option(name, markup, node, doc)
        end

        def raise_variable_option(name, markup, node, doc)
          raise Jekyll::Errors::FatalException,
                "BacklinkBuilder: {% #{node.raw.strip} %} in #{doc.relative_path} sets #{name}= to " \
                "the variable '#{markup}'. Backlinks are built without rendering, so they cannot " \
                "follow it; use a quoted #{name}= value."
        end

        # True when a `link=` option reads as false. A quoted value gives its
        # content, and an unquoted Liquid literal gives itself. Any other
        # unquoted markup is a variable, which stops the build. Shares
        # TagArgumentUtils.false_value? with the renderer.
        def link_disabled?(markup, node, doc)
          return false unless markup

          value = literal(markup) || (markup if LINK_LITERALS.include?(markup))
          raise_variable_option(:link, markup, node, doc) if value.nil?

          TagArgs.false_value?(value)
        end

        def normalize(title)
          Jekyll::Infrastructure::TextProcessingUtils.normalize_title(title)
        end
      end
    end
  end
end
