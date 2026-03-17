# frozen_string_literal: true

# _tests/plugins/test_display_tag_renderable.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/display_tag_renderable'

# A minimal test class that includes the mixin.
class TestRenderable
  include Jekyll::UI::DisplayTagRenderable

  attr_reader :markdown_data

  # Expose the private method for testing
  public :render_display_tag

  private

  def render_markdown(data)
    @markdown_data = data
    "markdown:#{data[:title]}"
  end
end

# Tests for Jekyll::UI::DisplayTagRenderable mixin.
class TestDisplayTagRenderable < Minitest::Test
  def setup
    @obj = TestRenderable.new
  end

  def test_delegates_to_render_markdown_when_render_mode_is_markdown
    context = create_context({}, { render_mode: :markdown })
    data = { title: 'Test', log_messages: 'some log' }

    result = @obj.render_display_tag(context, data) { raise 'should not yield' }

    assert_equal 'markdown:Test', result
    assert_equal data, @obj.markdown_data
  end

  def test_yields_for_html_and_prepends_log_messages
    context = create_context({}, {})
    data = { log_messages: '<!-- log -->', items: [1, 2] }

    result = @obj.render_display_tag(context, data) { |d| "<ul>#{d[:items].size}</ul>" }

    assert_equal '<!-- log --><ul>2</ul>', result
  end

  def test_handles_nil_log_messages
    context = create_context({}, {})
    data = { items: ['a'] }

    result = @obj.render_display_tag(context, data) { |_d| '<p>hello</p>' }

    assert_equal '<p>hello</p>', result
  end

  def test_handles_empty_log_messages
    context = create_context({}, {})
    data = { log_messages: '', items: [] }

    result = @obj.render_display_tag(context, data) { |_d| '<div></div>' }

    assert_equal '<div></div>', result
  end

  def test_md_cards_constant_is_available_in_mixin
    assert Jekyll::UI::DisplayTagRenderable.const_defined?(:MdCards, false)
  end
end
