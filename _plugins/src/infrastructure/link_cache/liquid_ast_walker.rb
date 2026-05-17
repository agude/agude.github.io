# frozen_string_literal: true

module Jekyll
  module Infrastructure
    module LinkCache
      # Generic walker for Liquid AST nodes.
      #
      # Handles the recursive traversal of Liquid templates, calling registered
      # handlers for each node type. Tracks context (e.g., inside_capture) so
      # handlers can make decisions based on where they are in the tree.
      #
      # Usage:
      #   walker = LiquidAstWalker.new(
      #     on_variable: ->(node, ctx) { ... },
      #     on_capture: ->(node, ctx) { ... },
      #     on_tag: ->(node, ctx) { ... },
      #   )
      #   walker.walk(template.root.nodelist)
      #
      # The on_capture handler receives the Capture node before its children are
      # walked. Use find_tags_in to extract tags from the capture's contents.
      #
      class LiquidAstWalker
        # Find all tags matching a filter within a nodelist (including nested structures).
        # Useful for extracting link tags from inside a capture.
        def self.find_tags_in(nodelist, &filter)
          tags = []
          collector = new(on_tag: ->(node, _ctx) { tags << node if filter.call(node) })
          collector.walk(nodelist)
          tags
        end

        def initialize(on_variable: nil, on_capture: nil, on_tag: nil)
          @on_variable = on_variable
          @on_capture = on_capture
          @on_tag = on_tag
        end

        def walk(nodelist, context = {})
          context = { inside_capture: false }.merge(context)
          walk_nodelist(nodelist, context)
        end

        private

        def walk_nodelist(nodelist, context)
          return unless nodelist

          nodelist.each { |node| visit(node, context) }
        end

        # IMPORTANT: Specific subclasses must come BEFORE Liquid::Tag
        # because they inherit from Tag, and Ruby's case matches first.
        def visit(node, context)
          case node
          when Liquid::Variable
            @on_variable&.call(node, context)
          when Liquid::Capture
            visit_capture(node, context)
          when Liquid::BlockBody, Liquid::For
            walk_nodelist(node.nodelist, context)
          when Liquid::If, Liquid::Unless, Liquid::Case
            visit_conditional(node, context)
          when Liquid::Tag
            @on_tag&.call(node, context)
          end
        end

        def visit_capture(node, context)
          @on_capture&.call(node, context)
          walk_nodelist(node.nodelist, context.merge(inside_capture: true))
        end

        def visit_conditional(node, context)
          walk_nodelist(node.nodelist, context)

          walk_nodelist([node.else_block], context) if node.respond_to?(:else_block) && node.else_block

          return unless node.respond_to?(:blocks)

          node.blocks.each do |block|
            walk_nodelist(block.nodelist, context) if block.respond_to?(:nodelist)
          end
        end
      end
    end
  end
end
