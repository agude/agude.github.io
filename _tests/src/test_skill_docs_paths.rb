# frozen_string_literal: true

require_relative '../test_helper'

# Scans .claude/skills/**/*.md for backtick-quoted repo paths and asserts
# each referenced file still exists. Catches the most common kind of
# skill doc staleness: a file was renamed or deleted but the doc still
# points at the old path.
class TestSkillDocsPaths < Minitest::Test
  SKILLS_DIR = File.expand_path('../../.claude/skills', __dir__)
  REPO_ROOT = File.expand_path('../..', __dir__)

  KNOWN_ROOTS = %w[
    _plugins/src
    _tests
    _includes
    _layouts
    _sass
    _bin
    _scripts
    .github
    content
    ui
    infrastructure
    seo
  ].freeze

  PATH_REGEX = /`([^`]+\.\w+)`/.freeze

  def test_all_backtick_paths_exist
    missing = []

    skill_docs.each do |doc_path|
      File.readlines(doc_path).each_with_index do |line, idx|
        line.scan(PATH_REGEX).flatten.each do |path|
          next unless looks_like_repo_path?(path)

          full = File.join(REPO_ROOT, path)
          full_in_plugins = File.join(REPO_ROOT, '_plugins/src', path)

          next if File.exist?(full) || File.exist?(full_in_plugins)

          rel_doc = doc_path.sub("#{REPO_ROOT}/", '')
          missing << "#{rel_doc}:#{idx + 1} references `#{path}` which does not exist"
        end
      end
    end

    assert missing.empty?, "Stale paths in skill docs:\n  #{missing.join("\n  ")}"
  end

  private

  def skill_docs
    Dir.glob(File.join(SKILLS_DIR, '**', '*.md'))
  end

  def looks_like_repo_path?(path)
    return false if path.include?(' ')
    return false if path.start_with?('http', '#', '$', '~', '/')
    return false unless path.include?('/')
    return false if path.include?('(')
    return false if path.include?('{')
    return false if path.include?('*')

    KNOWN_ROOTS.any? { |root| path.start_with?(root) || path.include?("/#{root}/") }
  end
end
