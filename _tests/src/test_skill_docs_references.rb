# frozen_string_literal: true

require_relative '../test_helper'

# Asserts that skill reference files match an allowlist, so implementation
# documentation goes into YARD tags on the code instead of references/.
class TestSkillDocsReferences < Minitest::Test
  REPO_ROOT = File.expand_path('../..', __dir__)
  SKILLS_DIR = File.join(REPO_ROOT, '.agents/skills')

  ALLOWED_REFERENCES = %w[
    copyedit/references/BOOK-REVIEWS.md
    copyedit/references/COLLECTIONS.md
    copyedit/references/PLUGINS.md
    copyedit/references/STYLE.md
    jekyll-site-dev/references/atproto-standard-site.md
    jekyll-site-dev/references/book-families.md
    jekyll-site-dev/references/build-performance.md
    jekyll-site-dev/references/content-authoring.md
    jekyll-site-dev/references/strict-liquid-includes.md
    jekyll-site-dev/references/markdown-output.md
  ].freeze

  def test_reference_files_match_the_allowlist
    actual = Dir.glob(File.join(SKILLS_DIR, '*/references/**/*'))
                .select { |path| File.file?(path) }
                .map { |path| path.delete_prefix("#{SKILLS_DIR}/") }
                .sort
    allowed = ALLOWED_REFERENCES.sort

    unexpected = actual - allowed
    missing = allowed - actual
    failures = []
    failures.concat(unexpected.map { |path| "Unexpected reference file: #{path}" })
    failures.concat(missing.map { |path| "Missing allowlisted reference file: #{path}" })

    assert failures.empty?, <<~MESSAGE
      #{failures.join("\n")}
      Implementation documentation belongs in YARD tags (@pattern, @gotcha, @validator, @pipeline) on the code, not in references/.
    MESSAGE
  end
end
