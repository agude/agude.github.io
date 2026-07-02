# frozen_string_literal: true

require_relative '../cards/markdown_card_utils'

module Jekyll
  module UI
    # Mixin for display tags that support render_mode branching.
    #
    # Provides `render_display_tag(context, data)` which checks render_mode
    # and either calls `render_markdown(data)` (which the including class
    # must define) or yields for HTML rendering, prepending any log messages.
    #
    # Also exposes the `MdCards` constant so including classes don't need
    # their own alias.
    module DisplayTagRenderable
      MdCards = Jekyll::UI::Cards::MarkdownCardUtils
      private_constant :MdCards

      private

      def render_display_tag(context, data)
        if context.registers[:render_mode] == :markdown
          render_markdown(data)
        else
          output = +(data[:log_messages] || '')
          output << yield(data)
        end
      end
    end
  end
end
