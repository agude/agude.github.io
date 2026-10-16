# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for LinkTagTargetResolver: the targets of one link tag, resolved
# from the tag's own parsed arguments without rendering it.
class TestLinkTagTargetResolver < Minitest::Test
  Resolver = Jekyll::Infrastructure::LinkCache::LinkTagTargetResolver

  def setup
    @author_page = create_doc({ 'title' => 'Ann Author', 'layout' => 'author_page' }, '/books/authors/ann/')
    @link_cache = {
      'books' => {
        'dune' => [{ 'url' => '/books/dune/', 'authors' => ['Ann Author'] }],
        'twin' => [
          { 'url' => '/books/twin-one/', 'authors' => ['Ann Author'] },
          { 'url' => '/books/twin-two/', 'authors' => ['Bob Author'] },
        ],
      },
      'authors' => { 'ann author' => { 'url' => '/books/authors/ann/', 'title' => 'Ann Author' } },
      'series_map' => {},
      'short_stories' => {},
    }
    @resolver = Resolver.new(@link_cache, { '/books/authors/ann/' => @author_page })
    @doc = create_doc({ 'series' => nil }, '/books/source/')
  end

  def targets(markup)
    node = Liquid::Template.parse(markup).root.nodelist.first
    @resolver.targets(node, @doc)
  end

  def test_quoted_book_title_resolves
    assert_equal [{ url: '/books/dune/', type: 'book' }], targets("{% book_link 'Dune' %}")
  end

  def test_variable_subject_has_no_target
    assert_nil targets('{% book_link some_title link_text="Dune" %}')
  end

  def test_ambiguous_title_without_author_has_no_target
    assert_nil targets('{% book_link "Twin" %}')
  end

  def test_author_option_picks_the_matching_book
    assert_equal [{ url: '/books/twin-two/', type: 'book' }], targets('{% book_link "Twin" author="Bob Author" %}')
  end

  def test_link_false_in_any_quoting_has_no_author_target
    ['link=false', "link='false'", 'link="false"', 'link=" false "', 'link="FALSE"'].each do |option|
      assert_nil targets(%({% author_link "Ann Author" #{option} %})), option
    end
  end

  def test_author_link_resolves_through_author_cache
    assert_equal [{ url: '/books/authors/ann/', type: 'author' }], targets('{% author_link "Ann Author" possessive %}')
  end

  def test_unknown_tag_has_no_target
    assert_nil targets('{% citation author_last="Doe" %}')
  end

  def test_variable_author_raises_naming_document_and_tag
    @doc.relative_path = '_books/source.md'
    error = assert_raises(Jekyll::Errors::FatalException) { targets('{% book_link "Dune" author=who %}') }
    assert_includes error.message, '_books/source.md'
    assert_includes error.message, '{% book_link "Dune" author=who %}'
  end

  def test_variable_from_book_raises_even_when_story_is_unknown
    error = assert_raises(Jekyll::Errors::FatalException) do
      targets('{% short_story_link "Unknown" from_book=book %}')
    end
    assert_includes error.message, 'from_book='
  end

  def test_quoted_options_do_not_raise
    assert_equal [{ url: '/books/dune/', type: 'book' }], targets('{% book_link "Dune" author="Ann Author" %}')
    assert_nil targets('{% short_story_link "Unknown" from_book="Dune" %}')
  end

  def test_stub_tag_node_raises
    stub_node = Struct.new(:tag_name).new('book_link')
    error = assert_raises(Jekyll::Errors::FatalException) { @resolver.targets(stub_node, @doc) }
    assert_includes error.message, 'book_link'
  end
end
