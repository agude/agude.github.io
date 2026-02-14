# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/short_stories/short_story_link_util'

# Tests for Jekyll::ShortStories::ShortStoryLinkUtils.
#
# Verifies that the utility module correctly uses ShortStoryLinkFinder + LinkFormatter.
class TestShortStoryLinkUtils < Minitest::Test
  Utils = Jekyll::ShortStories::ShortStoryLinkUtils

  def setup
    @story_entry = {
      'title' => 'The Last Question',
      'url' => '/books/robot-dreams/',
      'slug' => 'the-last-question',
      'parent_book_title' => 'Robot Dreams'
    }
    @site = create_site_with_link_cache({
                                          'short_stories' => {
                                            'the last question' => [@story_entry]
                                          }
                                        })
    @page = create_doc({}, '/current.html')
    @context = create_context({}, { site: @site, page: @page })
  end

  # --- Format Parameter Tests ---

  def test_render_with_format_html_returns_html
    result = Utils.render_short_story_link('The Last Question', @context, format: :html)
    assert_match %r{<a href="/books/robot-dreams/#the-last-question">}, result
    assert_match %r{<cite class="short-story-title">The Last Question</cite>}, result
  end

  def test_render_with_format_markdown_returns_markdown
    result = Utils.render_short_story_link('The Last Question', @context, format: :markdown)
    assert_equal '[*The Last Question*](/books/robot-dreams/#the-last-question)', result
  end

  def test_render_without_format_uses_context_mode
    # Default context has no markdown_mode, should return HTML
    result = Utils.render_short_story_link('The Last Question', @context)
    assert_match(/<a href=/, result)
    assert_match(/<cite class="short-story-title">/, result)
  end

  def test_render_with_markdown_context_returns_markdown
    md_context = create_context({}, { site: @site, page: @page, markdown_mode: true })
    result = Utils.render_short_story_link('The Last Question', md_context)
    assert_equal '[*The Last Question*](/books/robot-dreams/#the-last-question)', result
  end

  def test_render_with_format_overrides_context_mode
    # Even with markdown_mode: true, format: :html should return HTML
    md_context = create_context({}, { site: @site, page: @page, markdown_mode: true })
    result = Utils.render_short_story_link('The Last Question', md_context, format: :html)
    assert_match(/<a href=/, result)
    assert_match(/<cite class="short-story-title">/, result)
  end

  # --- From Book Filter Tests ---

  def test_render_with_from_book_filter
    site = create_site_with_link_cache({
                                         'short_stories' => {
                                           'nightfall' => [
                                             { 'title' => 'Nightfall', 'url' => '/books/nightfall-stories/', 'slug' => 'nightfall',
                                               'parent_book_title' => 'Nightfall and Other Stories' },
                                             { 'title' => 'Nightfall', 'url' => '/books/asimov-collection/', 'slug' => 'nightfall',
                                               'parent_book_title' => 'The Asimov Collection' }
                                           ]
                                         }
                                       })
    context = create_context({}, { site: site, page: @page })

    result = Utils.render_short_story_link('Nightfall', context, 'Nightfall and Other Stories', format: :html)
    assert_match %r{href="/books/nightfall-stories/#nightfall"}, result
  end

  # --- Unknown Story Tests ---

  def test_render_unknown_story_html_returns_cite_only
    result = Utils.render_short_story_link('Unknown Story', @context, format: :html)
    assert_equal '<cite class="short-story-title">Unknown Story</cite>', result
    refute_match(/<a href=/, result)
  end

  def test_render_unknown_story_markdown_returns_italic_only
    result = Utils.render_short_story_link('Unknown Story', @context, format: :markdown)
    assert_equal '*Unknown Story*', result
  end

  # --- Helper Method Tests ---

  def test_build_story_cite_element
    result = Utils._build_story_cite_element('Test Story')
    assert_equal '<cite class="short-story-title">Test Story</cite>', result
  end
end
