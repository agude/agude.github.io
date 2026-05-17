# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::Infrastructure::LinkCache::LiquidAstWalker
#
# Verifies the generic AST walker correctly visits nodes and tracks context.
class TestLiquidAstWalker < Minitest::Test
  def setup
    # Ensure stub tags are registered for parsing
    Jekyll::Infrastructure::LinkCache::BacklinkBuilder.ensure_stub_tags_registered
  end

  def test_visits_variables_in_prose
    template = Liquid::Template.parse('Hello {{ name }}!')
    visited = []

    walker = Jekyll::Infrastructure::LinkCache::LiquidAstWalker.new(
      on_variable: ->(node, _ctx) { visited << extract_var_name(node) },
    )
    walker.walk(template.root.nodelist)

    assert_equal ['name'], visited
  end

  def test_visits_tags
    template = Liquid::Template.parse("{% book_link 'Test' %}")
    visited = []

    walker = Jekyll::Infrastructure::LinkCache::LiquidAstWalker.new(
      on_tag: ->(node, _ctx) { visited << node.tag_name },
    )
    walker.walk(template.root.nodelist)

    assert_equal ['book_link'], visited
  end

  def test_visits_captures
    template = Liquid::Template.parse('{% capture foo %}bar{% endcapture %}')
    visited = []

    walker = Jekyll::Infrastructure::LinkCache::LiquidAstWalker.new(
      on_capture: ->(node, _ctx) { visited << node.instance_variable_get(:@to) },
    )
    walker.walk(template.root.nodelist)

    assert_equal ['foo'], visited
  end

  def test_tracks_inside_capture_context
    template = Liquid::Template.parse(<<~LIQUID)
      {{ outside }}
      {% capture foo %}{{ inside }}{% endcapture %}
      {{ also_outside }}
    LIQUID
    inside_capture = []

    walker = Jekyll::Infrastructure::LinkCache::LiquidAstWalker.new(
      on_variable: ->(node, ctx) { inside_capture << ctx[:inside_capture] },
    )
    walker.walk(template.root.nodelist)

    assert_equal [false, true, false], inside_capture
  end

  def test_walks_into_conditionals
    template = Liquid::Template.parse('{% if true %}{{ inner }}{% endif %}')
    visited = []

    walker = Jekyll::Infrastructure::LinkCache::LiquidAstWalker.new(
      on_variable: ->(node, _ctx) { visited << extract_var_name(node) },
    )
    walker.walk(template.root.nodelist)

    assert_equal ['inner'], visited
  end

  def test_walks_into_else_blocks
    template = Liquid::Template.parse('{% if false %}{{ then_var }}{% else %}{{ else_var }}{% endif %}')
    visited = []

    walker = Jekyll::Infrastructure::LinkCache::LiquidAstWalker.new(
      on_variable: ->(node, _ctx) { visited << extract_var_name(node) },
    )
    walker.walk(template.root.nodelist)

    assert_includes visited, 'then_var'
    assert_includes visited, 'else_var'
  end

  def test_walks_into_for_loops
    template = Liquid::Template.parse('{% for i in items %}{{ i }}{% endfor %}')
    visited = []

    walker = Jekyll::Infrastructure::LinkCache::LiquidAstWalker.new(
      on_variable: ->(node, _ctx) { visited << extract_var_name(node) },
    )
    walker.walk(template.root.nodelist)

    assert_equal ['i'], visited
  end

  def test_nested_captures
    template = Liquid::Template.parse(<<~LIQUID)
      {% capture outer %}
        {% capture inner %}{{ deeply_nested }}{% endcapture %}
      {% endcapture %}
    LIQUID
    captures = []

    walker = Jekyll::Infrastructure::LinkCache::LiquidAstWalker.new(
      on_capture: ->(node, _ctx) { captures << node.instance_variable_get(:@to) },
    )
    walker.walk(template.root.nodelist)

    assert_equal %w[outer inner], captures
  end

  def test_handler_receives_context_hash
    template = Liquid::Template.parse('{{ var }}')
    received_context = nil

    walker = Jekyll::Infrastructure::LinkCache::LiquidAstWalker.new(
      on_variable: ->(_node, ctx) { received_context = ctx },
    )
    walker.walk(template.root.nodelist, { custom: 'data' })

    assert_equal 'data', received_context[:custom]
    assert_equal false, received_context[:inside_capture]
  end

  def test_no_handlers_walks_without_error
    template = Liquid::Template.parse('{{ var }}{% if true %}{% book_link "X" %}{% endif %}')

    walker = Jekyll::Infrastructure::LinkCache::LiquidAstWalker.new
    walker.walk(template.root.nodelist)
  end

  def test_find_tags_in_extracts_matching_tags
    template = Liquid::Template.parse(<<~LIQUID)
      {% book_link "A" %}
      {% if true %}{% series_link "B" %}{% endif %}
      {% author_link "C" %}
    LIQUID
    link_tags = %w[book_link series_link author_link]

    tags = Jekyll::Infrastructure::LinkCache::LiquidAstWalker.find_tags_in(
      template.root.nodelist,
    ) { |node| link_tags.include?(node.tag_name) }

    assert_equal 3, tags.length
    assert_equal %w[book_link series_link author_link], tags.map(&:tag_name)
  end

  def test_find_tags_in_walks_into_nested_captures
    template = Liquid::Template.parse(<<~LIQUID)
      {% capture outer %}
        {% capture inner %}{% book_link "Nested" %}{% endcapture %}
      {% endcapture %}
    LIQUID

    tags = Jekyll::Infrastructure::LinkCache::LiquidAstWalker.find_tags_in(
      template.root.nodelist,
    ) { |node| node.tag_name == 'book_link' }

    assert_equal 1, tags.length
  end

  private

  def extract_var_name(node)
    name_obj = node.instance_variable_get(:@name)
    case name_obj
    when Liquid::VariableLookup then name_obj.name
    when String then name_obj
    end
  end
end
