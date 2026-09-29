# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/awards_page/markdown_renderer'

# Tests Markdown output from prepared awards-page data.
class TestAwardsPageMarkdownRenderer < Minitest::Test
  def test_renders_award_and_favorite_sections
    book = create_doc({ 'title' => 'Example Book' }, '/books/example.html')
    post = create_doc({ 'title' => 'Favorite Books' }, '/blog/favorites.html')
    data = {
      awards_groups: [{ award_name: 'Hugo Award', books: [book] }],
      favorites_lists: [{ post: post, books: [book] }],
      log_messages: '',
    }

    output = Jekyll::Books::AwardsPage::MarkdownRenderer.new(data).render

    assert_includes output, '## Major Awards'
    assert_includes output, '### Hugo Award'
    assert_includes output, '## My Favorite Books Lists'
    assert_includes output, '### [Favorite Books](/blog/favorites.html)'
  end
end
