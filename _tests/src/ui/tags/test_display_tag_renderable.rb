# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/display_tag_renderable'

# A minimal test class that includes the mixin.
class TestRenderable
  include Jekyll::UI::DisplayTagRenderable

  attr_reader :markdown_data

  # Expose the private methods for testing
  public :render_display_tag, :resolve_filter_value

  private

  def render_markdown(data)
    @markdown_data = data
    "markdown:#{data[:title]}"
  end
end

# A finder-backed tag body exercising the mixin's render flow.
class TestFinderRenderable
  include Jekyll::UI::DisplayTagRenderable

  FakeFinder = Struct.new(:data) do
    def find
      data
    end
  end

  def initialize(data)
    @data = data
  end

  private

  def finder_for(_context)
    FakeFinder.new(@data)
  end

  def renderer_for(_context, data)
    "<div>#{data[:items].size}</div>"
  end

  def render_markdown(data)
    "markdown items:#{data[:items].size}"
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

  # --- render (finder_for / renderer_for hooks) ---

  def test_render_finds_and_renders_html_with_log_messages
    context = create_context({}, {})
    tag = TestFinderRenderable.new({ items: [1, 2, 3], log_messages: '<!-- log -->' })

    assert_equal '<!-- log --><div>3</div>', tag.render(context)
  end

  def test_render_delegates_to_render_markdown_in_markdown_mode
    context = create_context({}, { render_mode: :markdown })
    tag = TestFinderRenderable.new({ items: [1, 2] })

    assert_equal 'markdown items:2', tag.render(context)
  end

  # --- Hook defaults (contract errors) ---

  def test_render_raises_named_error_when_finder_for_missing
    bare = Class.new { include Jekyll::UI::DisplayTagRenderable }.new

    err = assert_raises(NotImplementedError) { bare.render(create_context({}, {})) }
    assert_match 'must implement finder_for', err.message
  end

  def test_render_raises_named_error_when_renderer_for_missing
    klass = Class.new do
      include Jekyll::UI::DisplayTagRenderable

      private

      def finder_for(_context)
        TestFinderRenderable::FakeFinder.new({})
      end
    end

    err = assert_raises(NotImplementedError) { klass.new.render(create_context({}, {})) }
    assert_match 'must implement renderer_for', err.message
  end

  def test_render_markdown_default_raises_named_error
    bare = Class.new { include Jekyll::UI::DisplayTagRenderable }.new
    context = create_context({}, { render_mode: :markdown })

    err = assert_raises(NotImplementedError) { bare.send(:render_display_tag, context, {}) }
    assert_match 'must implement render_markdown', err.message
  end

  # --- resolve_filter_value ---

  def test_resolve_filter_value_stringifies_non_blank_values
    context = create_context({ 'num_var' => 42 }, {})
    assert_equal 'Jane Doe', @obj.resolve_filter_value("'Jane Doe'", context)
    assert_equal '42', @obj.resolve_filter_value('num_var', context)
  end

  def test_resolve_filter_value_passes_nil_and_blank_through
    context = create_context({ 'blank_var' => '   ', 'nil_var' => nil }, {})
    assert_nil @obj.resolve_filter_value('nil_var', context)
    assert_equal '   ', @obj.resolve_filter_value('blank_var', context)
  end

  def test_resolve_filter_value_passes_false_through_unstringified
    context = create_context({ 'false_var' => false }, {})
    assert_equal false, @obj.resolve_filter_value('false_var', context)
  end
end
