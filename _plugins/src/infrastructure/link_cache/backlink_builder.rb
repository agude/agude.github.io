# frozen_string_literal: true

require_relative '../text_processing_utils'

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
      # rubocop:disable Metrics/ClassLength
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

        # Simple state container for variable usage tracking.
        # Defined outside private to avoid RuboCop UselessConstantScoping warning.
        UsageTrackingState = Struct.new(
          :capture_defs,
          :total_prose_vars,
          :seen_captures,
          :prose_var_index,
          :capture_occurrence_counts,
        ) do
          def initialize(capture_defs, total_prose_vars)
            super(capture_defs, total_prose_vars, {}, 0, Hash.new(0))
          end

          def mark_capture_seen(var_name)
            occurrence = capture_occurrence_counts[var_name]
            capture_occurrence_counts[var_name] += 1

            count = 0
            capture_defs.each_with_index do |cap_def, idx|
              next unless cap_def[:var_name] == var_name

              if count == occurrence
                seen_captures[var_name] = idx
                return idx
              end
              count += 1
            end
            nil
          end

          def owning_capture_for(var_name)
            seen_captures[var_name]
          end

          def next_position_percentage
            pct = (prose_var_index.to_f / total_prose_vars * 100).round(1)
            self.prose_var_index += 1
            pct
          end
        end

        private

        def parse_liquid_safely(doc)
          Liquid::Template.parse(doc.content)
        rescue Liquid::SyntaxError => e
          Jekyll.logger.warn('BacklinkBuilder:', "Skipping #{doc.url}, malformed Liquid: #{e.message}")
          nil
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
          template = parse_liquid_safely(doc)
          return unless template

          # Extract captures containing link tags (returns array of definitions)
          capture_defs = extract_link_captures(template.root.nodelist, doc)

          # Build lookup by variable name for direct link detection
          captured_var_names = capture_defs.map { |c| c[:var_name] }.uniq

          # Find direct (non-captured) link tags
          direct_links = extract_direct_links(template.root.nodelist, doc, captured_var_names)

          # Find variable usages for position/count scoring
          usages = find_variable_usages(template.root.nodelist, capture_defs)

          # Register all links with scoring data
          register_captured_links(doc, capture_defs, usages)
          register_direct_links(doc, direct_links)
        end

        # Walk AST to find {% capture var %}...{% endcapture %} blocks containing link tags.
        # Returns array of definitions: [{ var_name:, targets: [{ url:, type: }] }, ...]
        # Multiple definitions for the same var_name are tracked separately for redefinition handling.
        def extract_link_captures(nodelist, doc, capture_defs = [])
          return capture_defs unless nodelist

          nodelist.each do |node|
            case node
            when Liquid::Capture
              process_capture_node(node, doc, capture_defs)
            when Liquid::BlockBody, Liquid::For
              # BlockBody wraps content inside conditionals/loops — walk into it
              extract_link_captures(node.nodelist, doc, capture_defs)
            when Liquid::If, Liquid::Unless, Liquid::Case
              # Walk into conditionals
              extract_from_conditional(node, doc, capture_defs)
            end
          end

          capture_defs
        end

        def process_capture_node(node, doc, capture_defs)
          var_name = node.instance_variable_get(:@to)
          links = find_links_in_nodelist(node.nodelist, doc)

          return if links.empty?

          capture_defs << { var_name: var_name, targets: links }
        end

        def extract_from_conditional(node, doc, capture_defs)
          # Liquid::If has nodelist (then) and potentially else_block
          extract_link_captures(node.nodelist, doc, capture_defs)

          # Handle else/elsif blocks
          if node.respond_to?(:else_block) && node.else_block
            extract_link_captures([node.else_block], doc, capture_defs)
          end

          # Handle Liquid::Condition blocks in Case
          return unless node.respond_to?(:blocks)

          node.blocks.each do |block|
            extract_link_captures(block.nodelist, doc, capture_defs) if block.respond_to?(:nodelist)
          end
        end

        # Find link tags within a nodelist (inside a capture)
        # IMPORTANT: Specific subclasses (If, Capture, etc.) must come BEFORE Liquid::Tag
        # because they inherit from Tag, and Ruby's case matches the first clause.
        def find_links_in_nodelist(nodelist, doc)
          links = []
          return links unless nodelist

          nodelist.each do |node|
            case node
            when Liquid::BlockBody, Liquid::Capture
              # BlockBody wraps content inside conditionals; Capture is a nested block
              links.concat(find_links_in_nodelist(node.nodelist, doc))
            when Liquid::If, Liquid::Unless, Liquid::Case, Liquid::For
              # Recurse into conditionals/loops (these inherit from Tag)
              links.concat(find_links_in_nodelist(node.nodelist, doc))
              if node.respond_to?(:else_block) && node.else_block
                links.concat(find_links_in_nodelist([node.else_block], doc))
              end
            when Liquid::Tag
              # General tags (book_link, series_link, etc.) — must be last
              link = extract_link_from_tag(node, doc)
              links.concat(link) if link
            end
          end

          links
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

        # Find direct link tags (not inside captures)
        def extract_direct_links(nodelist, doc, captured_var_names)
          links = []
          walk_for_direct_links(nodelist, doc, links, captured_var_names, false)
          links
        end

        # IMPORTANT: Specific subclasses must come BEFORE Liquid::Tag
        def walk_for_direct_links(nodelist, doc, links, captured_vars, inside_capture)
          return unless nodelist

          nodelist.each do |node|
            case node
            when Liquid::BlockBody
              walk_for_direct_links(node.nodelist, doc, links, captured_vars, inside_capture)
            when Liquid::Capture
              # Mark that we're inside a capture — don't collect as direct
              walk_for_direct_links(node.nodelist, doc, links, captured_vars, true)
            when Liquid::If, Liquid::Unless, Liquid::Case, Liquid::For
              walk_for_direct_links(node.nodelist, doc, links, captured_vars, inside_capture)
              if node.respond_to?(:else_block) && node.else_block
                walk_for_direct_links([node.else_block], doc, links, captured_vars, inside_capture)
              end
            when Liquid::Tag
              # General tags — must be last
              next if inside_capture

              link = extract_link_from_tag(node, doc)
              links.concat(link) if link
            end
          end
        end

        # Find {{ var }} usages in prose, tracking position by AST order.
        # Only counts usages AFTER the capture definition (forward refs don't count).
        # Returns hash keyed by capture_def index: { capture_idx => [positions as percentages] }
        #
        # Position is calculated as percentage through prose Variable nodes, not characters.
        # This avoids regex-based position tracking which can drift with markdown code blocks.
        def find_variable_usages(nodelist, capture_defs)
          return {} if capture_defs.empty?

          # First pass: count total prose variables for percentage calculation
          total_prose_vars = count_prose_variables(nodelist, false)
          return {} if total_prose_vars.zero?

          # Second pass: collect usages with AST-order positions
          usages = Hash.new { |h, k| h[k] = [] }
          state = UsageTrackingState.new(capture_defs, total_prose_vars)
          collect_variable_usages(nodelist, usages, state, false)
          usages
        end

        def count_prose_variables(nodelist, inside_capture)
          count = 0
          return count unless nodelist

          nodelist.each do |node|
            case node
            when Liquid::Variable
              count += 1 unless inside_capture
            when Liquid::Capture
              count += count_prose_variables(node.nodelist, true)
            when Liquid::BlockBody
              count += count_prose_variables(node.nodelist, inside_capture)
            when Liquid::If, Liquid::Unless, Liquid::Case, Liquid::For
              count += count_prose_variables(node.nodelist, inside_capture)
              if node.respond_to?(:else_block) && node.else_block
                count += count_prose_variables([node.else_block], inside_capture)
              end
            end
          end
          count
        end

        def collect_variable_usages(nodelist, usages, state, inside_capture)
          return unless nodelist

          nodelist.each do |node|
            case node
            when Liquid::Variable
              process_prose_variable(node, usages, state) unless inside_capture
            when Liquid::Capture
              process_capture_for_usage_tracking(node, state)
              collect_variable_usages(node.nodelist, usages, state, true)
            when Liquid::BlockBody
              collect_variable_usages(node.nodelist, usages, state, inside_capture)
            when Liquid::If, Liquid::Unless, Liquid::Case, Liquid::For
              collect_variable_usages(node.nodelist, usages, state, inside_capture)
              if node.respond_to?(:else_block) && node.else_block
                collect_variable_usages([node.else_block], usages, state, inside_capture)
              end
            end
          end
        end

        def process_capture_for_usage_tracking(node, state)
          var_name = node.instance_variable_get(:@to)
          state.mark_capture_seen(var_name)
        end

        def process_prose_variable(node, usages, state)
          var_name = extract_variable_name(node)
          return unless var_name

          # Check if we've seen a capture for this variable (forward ref detection)
          owning_capture_idx = state.owning_capture_for(var_name)
          position = state.next_position_percentage

          # Forward references (usage before capture) don't count
          return unless owning_capture_idx

          usages[owning_capture_idx] << position
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
      # rubocop:enable Metrics/ClassLength
    end
  end
end
