# frozen_string_literal: true

require_relative '../../../test_helper'

# Ensures every reader-facing tag has a Markdown behavior test. The test
# suite runs those tests; scanning plugin source for the word render_mode
# could pass even when the tag never emits Markdown.
class TestRenderModeCoverage < Minitest::Test
  # Tags that intentionally skip render_mode.
  # Each must have a comment explaining why.
  ALLOWLIST = Set.new(
    [
      # --- Layout footer tags: assembler builds these sections directly via
      # Finders, so these tags are never invoked during the markdown pass. ---
      'content/books/tags/book_backlinks_tag.rb',
      'content/books/tags/display_previous_reviews_tag.rb',
      'content/books/tags/related_books_tag.rb',
      'content/posts/tags/related_posts_tag.rb',
      'content/books/tags/render_book_card_tag.rb',

      # --- Layout header tags: assembler builds author/series links directly
      # using the link cache, bypassing these tags. ---
      'content/authors/tags/display_authors_tag.rb',

      # --- Admin/statistics pages: not reader-facing content. ---
      'content/books/tags/display_ranked_by_backlinks_tag.rb',
      'content/books/tags/display_unreviewed_mentions_tag.rb',

      # --- Infrastructure: not content output. ---
      'infrastructure/log_failure_tag.rb',

      # --- llms.txt index: only used in llms.txt (plain text), never
      # rendered through the markdown pipeline. ---
      'content/markdown_output/tags/llms_txt_index_tag.rb',

      # --- Media title tags: render_mode handled by base class
      # CiteTitleTag (cite_title_tag.rb). ---
      'ui/tags/game_title_tag.rb',
      'ui/tags/movie_title_tag.rb',
      'ui/tags/tv_show_title_tag.rb',

      # --- Link tags: render_mode handled by base class
      # LinkTagBase (infrastructure/links/link_tag_base.rb). ---
      'content/authors/tags/author_link_tag.rb',
      'content/books/tags/book_link_tag.rb',
      'content/series/tags/series_link_tag.rb',
      'content/short_stories/tags/short_story_link_tag.rb',
    ],
  ).freeze

  PLUGINS_ROOT = File.expand_path('../../../../_plugins/src', __dir__)
  TESTS_ROOT = File.expand_path('../../', __dir__)

  def test_all_reader_facing_tags_have_markdown_behavior_tests
    tag_files = Dir.glob(File.join(PLUGINS_ROOT, '**', '*_tag.rb'))
    assert tag_files.any?, "No tag files found in #{PLUGINS_ROOT}"

    missing = []
    tag_files.each do |path|
      relative_path = path.delete_prefix("#{PLUGINS_ROOT}/")
      next if ALLOWLIST.include?(relative_path)

      test_path = File.join(TESTS_ROOT, File.dirname(relative_path), "test_#{File.basename(path)}")
      test_methods = File.exist?(test_path) ? File.read(test_path).scan(/^\s*def (test_\w+)/).flatten : []
      missing << relative_path unless test_methods.any? { |name| name.match?(/markdown|render_mode/) }
    end

    assert_empty missing,
                 'Reader-facing tags need a Markdown behavior test ' \
                 "or an ALLOWLIST justification:\n  " \
                 "#{missing.join("\n  ")}"
  end

  def test_allowlisted_tags_still_exist
    tag_files = Dir.glob(File.join(PLUGINS_ROOT, '**', '*_tag.rb'))
    existing = Set.new(tag_files.map { |path| path.delete_prefix("#{PLUGINS_ROOT}/") })

    stale = ALLOWLIST - existing
    assert_empty stale,
                 "ALLOWLIST contains tags that no longer exist — remove them:\n  " \
                 "#{stale.to_a.join("\n  ")}"
  end
end
