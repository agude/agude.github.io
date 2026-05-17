# frozen_string_literal: true

require_relative '../text_processing_utils'
require_relative 'liquid_ast_walker'

module Jekyll
  module Infrastructure
    module LinkCache
      # Builds backlink and forward link data by parsing Liquid AST.
      #
      # Scans book content for link tags (book_link, series_link, short_story_link,
      # author_link) to build:
      # - backlinks: which books reference this book (for display in backlink sections)
      # - forward_links: which books this book references (with usage scoring)
      #
      # Usage scoring tracks how link captures are used in prose:
      # - count: number of {{ var }} usages after the capture definition
      # - min_position: earliest usage position as percentage of prose length
      #
      class BacklinkBuilder
        LINK_TYPE_PRIORITY = { 'book' => 4, 'author' => 3, 'short_story' => 2, 'series' => 1 }.freeze
        LINK_FALSE_PATTERN = /link\s*=\s*(?:'false'|"false"|false)/

        # Link tag patterns for AST extraction
        LINK_TAGS = %w[book_link series_link series_text short_story_link author_link].freeze

        # Register stub tags so Liquid can parse content without Jekyll context
        def self.ensure_stub_tags_registered
          return if @stub_tags_registered

          # Only register if the tag isn't already registered (Jekyll may have registered the real one)
          LINK_TAGS.each do |tag_name|
            next if Liquid::Template.tags[tag_name]

            Liquid::Template.register_tag(tag_name, Class.new(Liquid::Tag))
          end
          @stub_tags_registered = true
        end

        def initialize(site, link_cache, maps)
          @site = site
          @link_cache = link_cache
          @maps = maps
          @backlinks = Hash.new { |h, k| h[k] = {} }
          @forward_links = Hash.new { |h, k| h[k] = {} }
        end

        def build
          return unless @link_cache['books']&.any? && @site.collections.key?('books')

          build_url_to_doc_map

          @site.collections['books'].docs.each do |source_doc|
            scan_doc_with_ast(source_doc)
          end

          finalize_links
        end

        # Result of walking a Liquid AST to extract link data.
        ScanResult = Struct.new(:capture_defs, :direct_links, :prose_vars, keyword_init: true) do
          def compute_usages
            return {} if prose_vars.empty?

            usages = Hash.new { |h, k| h[k] = [] }
            total = prose_vars.length

            prose_vars.each_with_index do |var_info, idx|
              next unless var_info[:owning_capture_idx]

              position_pct = (idx.to_f / total * 100).round(1)
              usages[var_info[:owning_capture_idx]] << position_pct
            end

            usages
          end
        end

        # State container for AST walking. Encapsulates handler logic.
        class ScanState
          attr_reader :capture_defs, :direct_links, :prose_vars

          def initialize(builder, doc)
            @builder = builder
            @doc = doc
            @capture_defs = []
            @direct_links = []
            @prose_vars = []
            @seen_captures = {}
            @capture_occurrence_counts = Hash.new(0)
          end

          def handle_capture(node, _ctx)
            var_name = node.instance_variable_get(:@to)
            links = @builder.send(:extract_links_from_capture, node.nodelist, @doc)

            update_capture_tracking(var_name)
            @capture_defs << { var_name: var_name, targets: links } unless links.empty?
          end

          def handle_tag(node, ctx)
            return if ctx[:inside_capture]

            link = @builder.send(:extract_link_from_tag, node, @doc)
            @direct_links.concat(link) if link
          end

          def handle_variable(node, ctx)
            return if ctx[:inside_capture]

            var_name = @builder.send(:extract_variable_name, node)
            return unless var_name

            @prose_vars << { var_name: var_name, owning_capture_idx: @seen_captures[var_name] }
          end

          private

          def update_capture_tracking(var_name)
            occurrence = @capture_occurrence_counts[var_name]
            @capture_occurrence_counts[var_name] += 1
            cap_idx = @capture_defs.length

            count = 0
            @capture_defs.each_with_index do |cd, idx|
              next unless cd[:var_name] == var_name

              count += 1 if count < occurrence
              @seen_captures[var_name] = idx if count == occurrence
            end
            @seen_captures[var_name] = cap_idx
          end
        end

        private

        def parse_liquid_or_raise(doc)
          Liquid::Template.parse(doc.content)
        rescue Liquid::SyntaxError => e
          raise Jekyll::Errors::FatalException,
                "BacklinkBuilder: malformed Liquid in #{doc.url}: #{e.message}"
        end

        def build_url_to_doc_map
          @url_to_doc = {}
          @site.collections['books'].docs.each { |doc| @url_to_doc[doc.url] = doc }

          # Author pages added by URL for unified lookup in add_link
          @author_by_title = {}
          @site.pages.each do |page|
            next unless page.data['layout'] == 'author_page'

            @author_by_title[normalize(page.data['title'])] = page
            @url_to_doc[page.url] = page
          end
        end

        # Parse document content with Liquid AST to extract link information.
        def scan_doc_with_ast(doc)
          return unless doc.respond_to?(:content) && doc.content && !doc.content.empty?

          self.class.ensure_stub_tags_registered
          template = parse_liquid_or_raise(doc)

          result = walk_ast_for_links(template.root.nodelist, doc)
          usages = result.compute_usages

          register_captured_links(doc, result.capture_defs, usages)
          register_direct_links(doc, result.direct_links)
        end

        # Single-pass AST walk that extracts all link-related data.
        def walk_ast_for_links(nodelist, doc)
          state = ScanState.new(self, doc)

          walker = LiquidAstWalker.new(
            on_capture: ->(node, ctx) { state.handle_capture(node, ctx) },
            on_tag: ->(node, ctx) { state.handle_tag(node, ctx) },
            on_variable: ->(node, ctx) { state.handle_variable(node, ctx) },
          )

          walker.walk(nodelist)

          ScanResult.new(
            capture_defs: state.capture_defs,
            direct_links: state.direct_links,
            prose_vars: state.prose_vars,
          )
        end

        def extract_links_from_capture(nodelist, doc)
          tags = LiquidAstWalker.find_tags_in(nodelist) { |n| LINK_TAGS.include?(n.tag_name) }
          tags.flat_map { |tag| extract_link_from_tag(tag, doc) }.compact
        end

        # Extract link info from a tag node
        def extract_link_from_tag(node, doc)
          tag_name = node.tag_name
          return nil unless LINK_TAGS.include?(tag_name)

          markup = node.instance_variable_get(:@markup) || ''

          case tag_name
          when 'book_link'
            extract_book_link(markup)
          when 'series_link', 'series_text'
            extract_series_link(markup, doc)
          when 'short_story_link'
            extract_short_story_link(markup)
          when 'author_link'
            extract_author_link(markup)
          end
        end

        def extract_book_link(markup)
          title = extract_quoted_string(markup)
          return nil unless title

          locs = @link_cache['books'][normalize(title)]
          return nil unless locs

          [{ url: locs.first['url'], type: 'book' }]
        end

        def extract_series_link(markup, doc)
          return nil if markup.match?(LINK_FALSE_PATTERN)

          title = if markup.include?('page.series')
                    doc.data['series']
                  else
                    extract_quoted_string(markup)
                  end

          return nil if title.nil? || title.to_s.strip.empty?

          books = @link_cache['series_map'][normalize(title)]
          return nil unless books&.any?

          books.map { |book| { url: book.url, type: 'series' } }
        end

        def extract_short_story_link(markup)
          title = extract_quoted_string(markup)
          return nil unless title

          from_book = markup.match(/from_book=["']([^"']+)["']/)&.[](1)

          locs = @link_cache['short_stories'][normalize(title)]
          return nil unless locs

          target = find_target_story(locs, from_book)
          return nil unless target

          [{ url: target['url'], type: 'short_story' }]
        end

        def extract_author_link(markup)
          title = extract_quoted_string(markup)
          return nil unless title

          author_page = @author_by_title[normalize(title)]
          return nil unless author_page

          [{ url: author_page.url, type: 'author' }]
        end

        def extract_quoted_string(markup)
          match = markup.match(/['"]([^'"]+)['"]/)
          match&.[](1)
        end

        def extract_variable_name(node)
          # Liquid::Variable stores the name in @name (VariableLookup) or as a string
          name_obj = node.instance_variable_get(:@name)
          case name_obj
          when Liquid::VariableLookup
            name_obj.name
          when String
            name_obj
          end
        end

        def register_captured_links(doc, capture_defs, usages)
          target_scores = Hash.new { |h, k| h[k] = { count: 0, min_position: nil, type: nil } }

          capture_defs.each_with_index do |cap_def, cap_idx|
            cap_usages = usages[cap_idx] || []
            cap_def[:targets].each { |link| accumulate_link_score(target_scores, link, cap_usages) }
          end

          target_scores.each do |url, scores|
            count = scores[:count].positive? ? scores[:count] : nil
            add_link(url, doc, scores[:type], count, scores[:min_position])
          end
        end

        def accumulate_link_score(target_scores, link, cap_usages)
          url = link[:url]
          type = link[:type]

          current_type = target_scores[url][:type]
          if current_type.nil? || LINK_TYPE_PRIORITY[type] > LINK_TYPE_PRIORITY[current_type]
            target_scores[url][:type] = type
          end

          return unless cap_usages.any?

          target_scores[url][:count] += cap_usages.length
          min_pos = cap_usages.min
          current_min = target_scores[url][:min_position]
          target_scores[url][:min_position] = current_min.nil? ? min_pos : [current_min, min_pos].min
        end

        def register_direct_links(doc, links)
          links.each do |link|
            # Direct links have no capture-based scoring
            add_link(link[:url], doc, link[:type], nil, nil)
          end
        end

        def add_link(target_url, source_doc, type, count, min_position)
          return if source_doc.url == target_url

          # Update backlinks (no scoring data)
          existing_back = @backlinks[target_url][source_doc.url]
          new_p = LINK_TYPE_PRIORITY[type]

          if existing_back.nil? || new_p > LINK_TYPE_PRIORITY[existing_back[:type]]
            @backlinks[target_url][source_doc.url] = { source: source_doc, type: type }
          end

          # Update forward links (with scoring data)
          target_doc = @url_to_doc[target_url]
          return unless target_doc

          existing_fwd = @forward_links[source_doc.url][target_url]

          if existing_fwd.nil?
            @forward_links[source_doc.url][target_url] = {
              target: target_doc,
              type: type,
              count: count,
              min_position: min_position,
            }
          elsif new_p > LINK_TYPE_PRIORITY[existing_fwd[:type]]
            # Upgrade type, merge scoring
            @forward_links[source_doc.url][target_url][:type] = type
            merge_scoring(existing_fwd, count, min_position)
          else
            # Same or lower priority — just merge scoring
            merge_scoring(existing_fwd, count, min_position)
          end
        end

        def merge_scoring(existing, count, min_position)
          existing[:count] = (existing[:count] || 0) + count if count

          return unless min_position

          existing[:min_position] = if existing[:min_position]
                                      [existing[:min_position], min_position].min
                                    else
                                      min_position
                                    end
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

        def finalize_links
          final_back = {}
          @backlinks.each { |target, sources| final_back[target] = sources.values }
          @link_cache['backlinks'] = final_back

          final_forward = {}
          @forward_links.each { |source, targets| final_forward[source] = targets.values }
          @link_cache['forward_links'] = final_forward
        end
      end
    end
  end
end
