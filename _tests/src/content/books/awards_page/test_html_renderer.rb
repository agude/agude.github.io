# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/awards_page/html_renderer'

# Tests HTML output from prepared awards-page data.
class TestAwardsPageHtmlRenderer < Minitest::Test
  def test_returns_logs_when_both_sections_are_empty
    context = create_context({}, { site: create_site })
    data = { awards_groups: [], favorites_lists: [], log_messages: '<!-- missing data -->' }

    assert_equal '<!-- missing data -->', Jekyll::Books::AwardsPage::HtmlRenderer.new(context, data).render
  end
end
