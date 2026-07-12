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
    #
    # Tags with extra pre/post logic define their own `render` and call
    # `render_display_tag(context, data)` directly instead of relying on
    # the finder/renderer hooks above.
    #
    # Simple tags with no finder (e.g. a single conditional) branch inline
    # instead of using this mixin:
    #
    #   if context.registers[:render_mode] == :markdown
    #     "_#{text}_"
    #   else
    #     "<cite class=\"#{css}\">#{text}</cite>"
    #   end
    #
    # @pattern Render mode branching: tags check
    #   `context.registers[:render_mode]` to emit HTML or Markdown. Finders
    #   (extract/structure data, no HTML) and Renderers (data hash -> HTML,
    #   no data fetching) stay separate so each is independently testable;
    #   this mixin is the shared "build finder -> find -> render" flow for
    #   display tags built that way.
    #
    # Dependencies are aliased as private constants (`MdCards`, `TagArgs`
    # above) to avoid polluting the including class's namespace — the same
    # convention `LinkTagBase` and its subclasses use.
    #
    # Testing: stub both finder and renderer to verify the tag wires them
    # together, without exercising either's real logic:
    #
    #   mock_finder = Minitest::Mock.new
    #   mock_finder.expect :find, { year_groups: [...], log_messages: '' }
    #   mock_renderer = Minitest::Mock.new
    #   mock_renderer.expect :render, '<h1>HTML</h1>'
    #   FinderClass.stub :new, ->(_) { mock_finder } do
    #     RendererClass.stub :new, ->(ctx, data) { mock_renderer } do
    #       output = Liquid::Template.parse('{% display_tag %}').render!(context)
    #     end
    #   end
    #
    # Testing render_mode: :markdown — create a context with that render
    # register set and assert no HTML in the output:
    #
    #   md_context = create_context({}, { site: site, page: doc, render_mode: :markdown })
    #   output = Liquid::Template.parse('{% display_tag %}').render!(md_context)
    #   assert_match(/^## /, output)
    #   refute_match(/<div/, output)
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
