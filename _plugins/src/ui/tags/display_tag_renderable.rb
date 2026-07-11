# frozen_string_literal: true

require_relative '../cards/markdown_card_utils'
require_relative '../../infrastructure/tag_argument_utils'

module Jekyll
  module UI
    # Mixin for display tags that support render_mode branching.
    #
    # Provides `render_display_tag(context, data)` which checks render_mode
    # and either calls `render_markdown(data)` (which the including class
    # must define) or yields for HTML rendering, prepending any log messages.
    #
    # Tags whose flow is "build finder -> find -> render" can instead rely
    # on the mixin's `render(context)` and define the hooks:
    #
    # - finder_for(context)      -> a Finder whose `find` returns the data hash
    # - renderer_for(context, d) -> the HTML string for the data hash
    # - render_markdown(data)    -> the Markdown string for the data hash
    #
    # `resolve_filter_value(markup, context)` resolves a tag argument and
    # normalizes it for finder filters: non-blank values are stringified,
    # while nil/blank values pass through unchanged so the finder can log
    # the empty-filter failure itself.
    #
    # Also exposes the `MdCards` constant so including classes don't need
    # their own alias.
    module DisplayTagRenderable
      MdCards = Jekyll::UI::Cards::MarkdownCardUtils
      TagArgs = Jekyll::Infrastructure::TagArgumentUtils
      private_constant :MdCards, :TagArgs

      def render(context)
        data = finder_for(context).find
        render_display_tag(context, data) do |d|
          renderer_for(context, d)
        end
      end

      private

      # --- Hooks (defaults raise so a missing implementation fails with
      # a named contract error, matching LinkTagBase) ---

      def finder_for(_context)
        raise NotImplementedError, "#{self.class} must implement finder_for"
      end

      def renderer_for(_context, _data)
        raise NotImplementedError, "#{self.class} must implement renderer_for"
      end

      def render_markdown(_data)
        raise NotImplementedError, "#{self.class} must implement render_markdown"
      end

      def render_display_tag(context, data)
        if context.registers[:render_mode] == :markdown
          render_markdown(data)
        else
          output = +(data[:log_messages] || '')
          output << yield(data)
        end
      end

      def resolve_filter_value(markup, context)
        value = TagArgs.resolve_value(markup, context)
        return value unless value
        return value if value.to_s.strip.empty?

        value.to_s
      end
    end
  end
end
