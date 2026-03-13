# frozen_string_literal: true

# _tests/plugins/utils/test_display_authors_util.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/authors/display_authors_util'

# Tests for Jekyll::Authors::DisplayAuthorsUtil module.
#
# Verifies that the utility correctly processes author lists and generates
# HTML output with proper linking and formatting.
class TestDisplayAuthorsUtil < Minitest::Test
  def setup
    @site = create_site({ 'url' => 'http://example.com' })
    @context = create_context({}, { site: @site })
  end

  # Helper to stub AuthorLinkResolver so resolve returns predictable output
  def with_stub_resolver(&)
    resolver = Object.new
    resolver.define_singleton_method(:resolve) do |name, _override, _possessive, link: true|
      "<a href=\"/authors/#{name.downcase.gsub(' ', '-')}.html\">#{name}</a>"
    end
    Jekyll::Authors::AuthorLinkResolver.stub(:new, resolver, &)
  end

  # --- Single Author Tests ---

  def test_single_author_linked
    with_stub_resolver do
      result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
        author_input: 'Isaac Asimov',
        context: @context,
        linked: true,
      )

      assert_equal '<a href="/authors/isaac-asimov.html">Isaac Asimov</a>', result
    end
  end

  def test_single_author_not_linked
    result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
      author_input: 'Isaac Asimov',
      context: @context,
      linked: false,
    )

    assert_equal '<span class="author-name">Isaac Asimov</span>', result
  end

  def test_single_author_from_array
    with_stub_resolver do
      result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
        author_input: ['Isaac Asimov'],
        context: @context,
        linked: true,
      )

      assert_equal '<a href="/authors/isaac-asimov.html">Isaac Asimov</a>', result
    end
  end

  def test_single_author_with_special_characters
    with_stub_resolver do
      result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
        author_input: 'Ursula K. Le Guin',
        context: @context,
        linked: true,
      )

      assert_equal '<a href="/authors/ursula-k.-le-guin.html">Ursula K. Le Guin</a>', result
    end
  end

  # --- Two Authors Tests ---

  def test_two_authors_linked
    with_stub_resolver do
      result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
        author_input: ['Isaac Asimov', 'Robert Silverberg'],
        context: @context,
        linked: true,
      )

      expected = '<a href="/authors/isaac-asimov.html">Isaac Asimov</a> and ' \
                 '<a href="/authors/robert-silverberg.html">Robert Silverberg</a>'
      assert_equal expected, result
    end
  end

  def test_two_authors_not_linked
    result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
      author_input: ['Isaac Asimov', 'Robert Silverberg'],
      context: @context,
      linked: false,
    )

    expected = '<span class="author-name">Isaac Asimov</span> and ' \
               '<span class="author-name">Robert Silverberg</span>'
    assert_equal expected, result
  end

  # --- Three Authors Tests ---

  def test_three_authors_linked
    with_stub_resolver do
      result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
        author_input: ['Isaac Asimov', 'Robert Silverberg', 'Arthur C. Clarke'],
        context: @context,
        linked: true,
      )

      expected = '<a href="/authors/isaac-asimov.html">Isaac Asimov</a>, ' \
                 '<a href="/authors/robert-silverberg.html">Robert Silverberg</a>, and ' \
                 '<a href="/authors/arthur-c.-clarke.html">Arthur C. Clarke</a>'
      assert_equal expected, result
    end
  end

  def test_three_authors_not_linked
    result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
      author_input: ['Isaac Asimov', 'Robert Silverberg', 'Arthur C. Clarke'],
      context: @context,
      linked: false,
    )

    expected = '<span class="author-name">Isaac Asimov</span>, ' \
               '<span class="author-name">Robert Silverberg</span>, and ' \
               '<span class="author-name">Arthur C. Clarke</span>'
    assert_equal expected, result
  end

  # --- Four Authors Tests ---

  def test_four_authors_linked
    with_stub_resolver do
      result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
        author_input: ['Isaac Asimov', 'Robert Silverberg', 'Arthur C. Clarke', 'Frederik Pohl'],
        context: @context,
        linked: true,
      )

      expected = '<a href="/authors/isaac-asimov.html">Isaac Asimov</a>, ' \
                 '<a href="/authors/robert-silverberg.html">Robert Silverberg</a>, ' \
                 '<a href="/authors/arthur-c.-clarke.html">Arthur C. Clarke</a>, and ' \
                 '<a href="/authors/frederik-pohl.html">Frederik Pohl</a>'
      assert_equal expected, result
    end
  end

  def test_four_authors_not_linked
    result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
      author_input: ['Isaac Asimov', 'Robert Silverberg', 'Arthur C. Clarke', 'Frederik Pohl'],
      context: @context,
      linked: false,
    )

    expected = '<span class="author-name">Isaac Asimov</span>, ' \
               '<span class="author-name">Robert Silverberg</span>, ' \
               '<span class="author-name">Arthur C. Clarke</span>, and ' \
               '<span class="author-name">Frederik Pohl</span>'
    assert_equal expected, result
  end

  # --- Et Al Tests ---

  def test_et_al_after_one
    with_stub_resolver do
      result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
        author_input: ['Isaac Asimov', 'Robert Silverberg'],
        context: @context,
        linked: true,
        etal_after: 1,
      )

      expected = '<a href="/authors/isaac-asimov.html">Isaac Asimov</a> <abbr class="etal">et al.</abbr>'
      assert_equal expected, result
    end
  end

  def test_et_al_after_two
    with_stub_resolver do
      result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
        author_input: ['Isaac Asimov', 'Robert Silverberg', 'Arthur C. Clarke'],
        context: @context,
        linked: true,
        etal_after: 2,
      )

      expected = '<a href="/authors/isaac-asimov.html">Isaac Asimov</a> <abbr class="etal">et al.</abbr>'
      assert_equal expected, result
    end
  end

  def test_et_al_after_three
    with_stub_resolver do
      result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
        author_input: ['Isaac Asimov', 'Robert Silverberg', 'Arthur C. Clarke', 'Frederik Pohl'],
        context: @context,
        linked: true,
        etal_after: 3,
      )

      expected = '<a href="/authors/isaac-asimov.html">Isaac Asimov</a> <abbr class="etal">et al.</abbr>'
      assert_equal expected, result
    end
  end

  def test_et_al_does_not_truncate_when_threshold_equals_author_count
    with_stub_resolver do
      result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
        author_input: ['Isaac Asimov', 'Robert Silverberg'],
        context: @context,
        linked: true,
        etal_after: 2,
      )

      expected = '<a href="/authors/isaac-asimov.html">Isaac Asimov</a> and ' \
                 '<a href="/authors/robert-silverberg.html">Robert Silverberg</a>'
      assert_equal expected, result
    end
  end

  def test_et_al_does_not_truncate_when_threshold_exceeds_author_count
    with_stub_resolver do
      result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
        author_input: ['Isaac Asimov', 'Robert Silverberg'],
        context: @context,
        linked: true,
        etal_after: 5,
      )

      expected = '<a href="/authors/isaac-asimov.html">Isaac Asimov</a> and ' \
                 '<a href="/authors/robert-silverberg.html">Robert Silverberg</a>'
      assert_equal expected, result
    end
  end

  def test_et_al_not_linked
    result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
      author_input: ['Isaac Asimov', 'Robert Silverberg', 'Arthur C. Clarke'],
      context: @context,
      linked: false,
      etal_after: 2,
    )

    expected = '<span class="author-name">Isaac Asimov</span> <abbr class="etal">et al.</abbr>'
    assert_equal expected, result
  end

  def test_et_al_with_zero_threshold_shows_all
    with_stub_resolver do
      result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
        author_input: ['Isaac Asimov', 'Robert Silverberg'],
        context: @context,
        linked: true,
        etal_after: 0,
      )

      expected = '<a href="/authors/isaac-asimov.html">Isaac Asimov</a> and ' \
                 '<a href="/authors/robert-silverberg.html">Robert Silverberg</a>'
      assert_equal expected, result
    end
  end

  def test_et_al_with_negative_threshold_shows_all
    with_stub_resolver do
      result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
        author_input: ['Isaac Asimov', 'Robert Silverberg'],
        context: @context,
        linked: true,
        etal_after: -1,
      )

      expected = '<a href="/authors/isaac-asimov.html">Isaac Asimov</a> and ' \
                 '<a href="/authors/robert-silverberg.html">Robert Silverberg</a>'
      assert_equal expected, result
    end
  end

  # --- String Input Tests ---

  def test_string_input_single_author
    with_stub_resolver do
      result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
        author_input: 'Isaac Asimov',
        context: @context,
        linked: true,
      )

      expected = '<a href="/authors/isaac-asimov.html">Isaac Asimov</a>'
      assert_equal expected, result
    end
  end

  # --- Edge Cases ---

  def test_empty_string_returns_empty
    result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
      author_input: '',
      context: @context,
      linked: true,
    )

    assert_equal '', result
  end

  def test_empty_array_returns_empty
    result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
      author_input: [],
      context: @context,
      linked: true,
    )

    assert_equal '', result
  end

  def test_nil_input_returns_empty
    result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
      author_input: nil,
      context: @context,
      linked: true,
    )

    assert_equal '', result
  end

  def test_linked_defaults_to_true
    with_stub_resolver do
      result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
        author_input: 'Isaac Asimov',
        context: @context,
      )

      assert_equal '<a href="/authors/isaac-asimov.html">Isaac Asimov</a>', result
    end
  end

  def test_etal_after_defaults_to_nil
    with_stub_resolver do
      result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
        author_input: ['Isaac Asimov', 'Robert Silverberg'],
        context: @context,
        linked: true,
      )

      expected = '<a href="/authors/isaac-asimov.html">Isaac Asimov</a> and ' \
                 '<a href="/authors/robert-silverberg.html">Robert Silverberg</a>'
      assert_equal expected, result
    end
  end

  # --- HTML Escaping Tests ---

  def test_unlinked_authors_are_html_escaped
    result = Jekyll::Authors::DisplayAuthorsUtil.render_author_list(
      author_input: '<script>alert("xss")</script>',
      context: @context,
      linked: false,
    )

    assert_equal '<span class="author-name">&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;</span>', result
  end
end
