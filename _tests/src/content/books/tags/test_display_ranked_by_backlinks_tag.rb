# frozen_string_literal: true

# _tests/plugins/test_display_ranked_by_backlinks_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/tags/display_ranked_by_backlinks_tag'

# Tests for Jekyll::Books::Tags::DisplayRankedByBacklinksTag Liquid tag.
#
# Uses real Finder and Renderer with mock site data, stubbing only
# BookLinkResolver (the leaf dependency) so assertions check actual
# tag behavior rather than mocked return values.
class TestDisplayRankedByBacklinksTag < Minitest::Test
  def setup
    @book_a = create_doc(
      { 'title' => 'Hyperion', 'date' => Time.parse('2024-01-01'), 'authors' => ['Dan Simmons'] },
      '/books/hyperion/',
      'content',
      nil,
      MockCollection.new(nil, 'books'),
    )
    @book_b = create_doc(
      { 'title' => 'Dune', 'date' => Time.parse('2024-02-01'), 'authors' => ['Frank Herbert'] },
      '/books/dune/',
      'content',
      nil,
      MockCollection.new(nil, 'books'),
    )
  end

  def render_tag(context)
    Liquid::Template.parse('{% display_ranked_by_backlinks %}').render!(context)
  end

  def test_renders_ranked_list_with_real_data
    site = build_site_with_backlinks(
      '/books/hyperion/' => ['/books/dune/'],
      '/books/dune/' => ['/books/hyperion/', '/some-post/'],
    )
    context = create_context({}, { site: site })

    output = stub_resolver { render_tag(context) }

    assert_includes output, '<ol class="ranked-list">'
    assert_includes output, '</ol>'
    assert_includes output, '2 mentions'
    assert_includes output, '1 mention'
    # Dune (2 mentions) should appear before Hyperion (1 mention)
    dune_pos = output.index('Dune')
    hyperion_pos = output.index('Hyperion')
    assert dune_pos < hyperion_pos, 'Dune (2 mentions) should rank above Hyperion (1 mention)'
  end

  def test_renders_empty_message_when_no_backlinks
    site = build_site_with_backlinks({})
    context = create_context({}, { site: site })

    output = stub_resolver { render_tag(context) }

    assert_includes output, '<p>No books have been mentioned yet.</p>'
    refute_includes output, '<ol'
  end

  def test_renders_empty_message_when_backlinks_exist_but_no_matching_books
    site = build_site_with_backlinks('/books/nonexistent/' => ['/some-post/'])
    context = create_context({}, { site: site })

    output = stub_resolver { render_tag(context) }

    assert_includes output, '<p>No books have been mentioned yet.</p>'
  end

  def test_prepends_error_log_when_prerequisites_missing
    site = create_site({})
    # Remove the link_cache to trigger the prerequisites check
    site.data.delete('link_cache')
    site.config['plugin_logging']['RANKED_BY_BACKLINKS'] = true
    context = create_context({}, { site: site })

    output = Jekyll.stub(:logger, silent_logger) { render_tag(context) }

    assert_match(/RANKED_BY_BACKLINKS_FAILURE/, output)
    assert_includes output, '<p>No books have been mentioned yet.</p>'
  end

  def test_single_mention_uses_singular_text
    site = build_site_with_backlinks('/books/hyperion/' => ['/books/dune/'])
    context = create_context({}, { site: site })

    output = stub_resolver { render_tag(context) }

    assert_includes output, '1 mention'
    refute_includes output, '1 mentions'
  end

  FakeResolver = Struct.new(:context) do
    def render_from_data(title, _url, cite: true) # rubocop:disable Lint/UnusedMethodArgument
      "<a>#{title}</a>"
    end
  end

  private

  def build_site_with_backlinks(backlinks_hash)
    site = create_site(
      { 'url' => 'http://example.com' },
      { 'books' => [@book_a, @book_b] },
    )
    site.data['link_cache']['backlinks'] = backlinks_hash
    site
  end

  def stub_resolver(&)
    Jekyll::Books::Core::BookLinkResolver.stub(
      :new,
      ->(_context) { FakeResolver.new },
      &
    )
  end
end
