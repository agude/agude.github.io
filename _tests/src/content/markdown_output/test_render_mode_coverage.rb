# frozen_string_literal: true

require_relative '../../../test_helper'

# Ensures every custom Liquid tag either handles render_mode or is
# explicitly allowlisted.  Catches new tags that forget to add
# markdown support.
class TestRenderModeCoverage < Minitest::Test
  # Tags that intentionally skip render_mode.
  # Each must have a comment explaining why.
  ALLOWLIST = Set.new(
    [
      # --- Layout footer tags: assembler builds these sections directly via
      # Finders, so these tags are never invoked during the markdown pass. ---
      'book_backlinks_tag.rb',
      'display_previous_reviews_tag.rb',
      'related_books_tag.rb',
      'related_posts_tag.rb',
      'render_book_card_tag.rb',

      # --- Layout header tags: assembler builds author/series links directly
      # using the link cache, bypassing these tags. ---
      'display_authors_tag.rb',

      # --- Admin/statistics pages: not reader-facing content. ---
      'display_ranked_by_backlinks_tag.rb',
      'display_unreviewed_mentions_tag.rb',

      # --- Infrastructure: not content output. ---
      'log_failure_tag.rb',

      # --- llms.txt index: only used in llms.txt (plain text), never
      # rendered through the markdown pipeline. ---
      'llms_txt_index_tag.rb',
    ],
  ).freeze

  PLUGINS_ROOT = File.expand_path('../../../../_plugins/src', __dir__)

  def test_all_tags_handle_render_mode_or_are_allowlisted
    tag_files = Dir.glob(File.join(PLUGINS_ROOT, '**', '*_tag.rb'))
    assert tag_files.any?, "No tag files found in #{PLUGINS_ROOT}"

    missing = []
    tag_files.each do |path|
      basename = File.basename(path)
      next if ALLOWLIST.include?(basename)

      content = File.read(path)
      # Check for render_mode usage that isn't in a comment
      missing << basename unless content.match?(/^[^#]*render_mode/)
    end

    assert_empty missing,
                 'Tags without render_mode support must either implement it ' \
                 "or be added to ALLOWLIST with a justification:\n  " \
                 "#{missing.join("\n  ")}"
  end

  def test_allowlisted_tags_still_exist
    tag_files = Dir.glob(File.join(PLUGINS_ROOT, '**', '*_tag.rb'))
    existing = Set.new(tag_files.map { |p| File.basename(p) })

    stale = ALLOWLIST - existing
    assert_empty stale,
                 "ALLOWLIST contains tags that no longer exist — remove them:\n  " \
                 "#{stale.to_a.join("\n  ")}"
  end
end
