# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::UI::Tags::RenderModeTag Liquid tag.
class TestRenderModeTag < Minitest::Test
  def setup
    @site = create_site
  end

  def test_render_mode_nil
    # No register set
    context = create_context({}, { site: @site })
    output = Liquid::Template.parse('{% render_mode %}').render!(context)
    assert_equal '', output
  end

  def test_render_mode_markdown
    # Register set to :markdown (symbol)
    context = create_context({}, { site: @site, render_mode: :markdown })
    output = Liquid::Template.parse('{% render_mode %}').render!(context)
    assert_equal 'markdown', output
  end

  def test_render_mode_html
    # Register set to :html (symbol)
    context = create_context({}, { site: @site, render_mode: :html })
    output = Liquid::Template.parse('{% render_mode %}').render!(context)
    assert_equal 'html', output
  end

  def test_render_mode_string
    # Register set to "markdown" (string) - just in case
    context = create_context({}, { site: @site, render_mode: 'markdown' })
    output = Liquid::Template.parse('{% render_mode %}').render!(context)
    assert_equal 'markdown', output
  end
end
