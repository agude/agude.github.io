# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/markdown_output/markdown_html_converter'

# Source HTML cleanup cases found in the generated Markdown audit.
class TestMarkdownHtmlSourceAudit < Minitest::Test
  def test_localization_article_does_not_leave_a_malformed_nowrap_span
    path = File.expand_path('../../../../_posts/2017-08-07-lab41_object_localization_without_deep_learning.md', __dir__)
    item = File.read(path)[/^1\. An .*?(?=\n2\.)/m]
    refute_nil item

    output = Jekyll::MarkdownOutput::MarkdownHtmlConverter.convert(item)

    refute_match(%r{</?span\b}i, output)
    assert_includes output, '[Single Shot MultiBox Detector (SSD)][ssd],[^liu] performed poorly.'
  end
end
