# frozen_string_literal: true

require_relative 'liquid_ast_walker'
require_relative 'link_tag_target_resolver'

module Jekyll
  module Infrastructure
    module LinkCache
      # Builds backlink and forward link data by parsing Liquid AST.
      #
      # Scans book content for link tags (book_link, series_link, short_story_link,
      # author_link) to build:
      # - backlinks: which books reference this book (with usage scoring)
      # - forward_links: which books this book references (with usage scoring)
      #
      # Usage scoring tracks how link captures are used in prose:
      # - count: number of {{ var }} usages after the capture definition
      # - min_position: earliest usage position as percentage of prose length
      #
      # Both directions use the same scoring data — when Book A mentions Book B,
      # the count/position from A's content appears in both A's forward link to B
      # and B's backlink from A.
      #
      class BacklinkBuilder
        LINK_TYPE_PRIORITY = { 'book' => 4, 'author' => 3, 'short_story' => 2, 'series' => 1 }.freeze

        # Link tag patterns for AST extraction
        LINK_TAGS = %w[book_link series_link series_text short_story_link author_link].freeze

        # Direct link types (book, short_story) get position preference over indirect (series).
        DIRECT_LINK_TYPES = %w[book short_story].freeze

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
          @targets = LinkTagTargetResolver.new(@link_cache, @url_to_doc)

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
          end

          def handle_capture(node, _ctx)
            var_name = node.instance_variable_get(:@to)
            links = @builder.send(:extract_links_from_capture, node.nodelist, @doc)

            # A capture always rebinds its variable. One with no resolvable
            # targets (plain text, unresolved books/authors) binds it to nil,
            # so later {{ var }} usages attach to nothing: neither to an
            # earlier capture of the same name nor to the next valid capture.
            if links.empty?
              @seen_captures[var_name] = nil
              return
            end

            update_capture_tracking(var_name)
            @capture_defs << { var_name: var_name, targets: links }
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
            @seen_captures[var_name] = @capture_defs.length
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
          @site.pages.each do |page|
            @url_to_doc[page.url] = page if page.data['layout'] == 'author_page'
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

        def extract_link_from_tag(node, doc)
          @targets.targets(node, doc)
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
          target_scores = Hash.new do |h, k|
            h[k] = { count: 0, min_position: nil, direct_min_position: nil, type: nil }
          end

          capture_defs.each_with_index do |cap_def, cap_idx|
            cap_usages = usages[cap_idx] || []
            cap_def[:targets].each { |link| accumulate_link_score(target_scores, link, cap_usages) }
          end

          target_scores.each do |url, scores|
            count = scores[:count].positive? ? scores[:count] : nil
            add_link(url, doc, scores[:type], count, scores[:min_position], scores[:direct_min_position])
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

          # Also track direct link positions (book/short_story) for sorting preference
          return unless DIRECT_LINK_TYPES.include?(type)

          current_direct = target_scores[url][:direct_min_position]
          target_scores[url][:direct_min_position] = current_direct.nil? ? min_pos : [current_direct, min_pos].min
        end

        def register_direct_links(doc, links)
          links.each do |link|
            # Direct links have no capture-based scoring
            add_link(link[:url], doc, link[:type], nil, nil, nil)
          end
        end

        def add_link(target_url, source_doc, type, count, min_position, direct_min_position)
          return if source_doc.url == target_url

          update_backlink(target_url, source_doc, type, count, min_position, direct_min_position)
          update_forward_link(target_url, source_doc, type, count, min_position, direct_min_position)
        end

        def update_backlink(target_url, source_doc, type, count, min_position, direct_min_position)
          existing = @backlinks[target_url][source_doc.url]

          if existing.nil?
            @backlinks[target_url][source_doc.url] = {
              source: source_doc,
              type: type,
              count: count,
              min_position: min_position,
              direct_min_position: direct_min_position,
            }
          else
            merge_entry(existing, type, count, min_position, direct_min_position)
          end
        end

        def update_forward_link(target_url, source_doc, type, count, min_position, direct_min_position)
          target_doc = @url_to_doc[target_url]
          return unless target_doc

          existing = @forward_links[source_doc.url][target_url]

          if existing.nil?
            @forward_links[source_doc.url][target_url] = {
              target: target_doc,
              type: type,
              count: count,
              min_position: min_position,
              direct_min_position: direct_min_position,
            }
          else
            merge_entry(existing, type, count, min_position, direct_min_position)
          end
        end

        def merge_entry(existing, type, count, min_position, direct_min_position)
          existing[:type] = type if LINK_TYPE_PRIORITY[type] > LINK_TYPE_PRIORITY[existing[:type]]
          existing[:count] = (existing[:count] || 0) + count if count
          merge_min(:min_position, existing, min_position)
          merge_min(:direct_min_position, existing, direct_min_position)
        end

        def merge_min(key, existing, new_value)
          return unless new_value

          existing[key] = existing[key] ? [existing[key], new_value].min : new_value
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
