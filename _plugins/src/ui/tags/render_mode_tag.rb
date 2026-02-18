# frozen_string_literal: true

module Jekyll
  module UI
    module Tags
      # A simple tag that outputs the current render_mode from the registers.
      # Usage: {% render_mode %}
      # Result: "markdown" or "html" (or empty string if not set)
      class RenderModeTag < Liquid::Tag
        def render(context)
          context.registers[:render_mode].to_s
        end
      end
    end
  end
end

Liquid::Template.register_tag('render_mode', Jekyll::UI::Tags::RenderModeTag)
