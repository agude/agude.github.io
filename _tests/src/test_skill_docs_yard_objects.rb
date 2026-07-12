# frozen_string_literal: true

require_relative '../test_helper'
require 'yard'

# Loads a YARD registry from the same files/tags .yardopts declares, then
# asserts every `has_tag?(:...)` query and `OBJ=...` reference used in the
# skill docs actually resolves. This is the §7.1 guardrail: code-resident
# docs replace file-path references (checked by TestSkillDocsPaths) with
# code-object references, which go stale the same way if a class is
# renamed or a tag is dropped without updating the skill doc.
class TestSkillDocsYardObjects < Minitest::Test
  REPO_ROOT = File.expand_path('../..', __dir__)
  YARDOPTS_PATH = File.join(REPO_ROOT, '.yardopts')
  SKILLS_DIR = File.join(REPO_ROOT, '.claude/skills')

  # Literal placeholder text in SKILL.md ("OBJ=Jekyll::..."); not a real object.
  PLACEHOLDER_REFS = ['Jekyll::...'].freeze

  def setup
    @yardopts_lines = File.readlines(YARDOPTS_PATH, chomp: true).reject(&:empty?)
    register_custom_tags
    load_registry
  end

  def test_has_tag_queries_in_skill_docs_resolve
    missing = tag_names_in_skill_docs.reject do |tag|
      YARD::Registry.all.any? { |object| object.tag(tag) }
    end

    assert missing.empty?, "Skill docs query tags with no matching object: #{missing.join(', ')}"
  end

  def test_obj_references_in_skill_docs_resolve
    missing = obj_references_in_skill_docs.reject do |ref|
      resolved = YARD::Registry.at(ref)
      resolved && !resolved.is_a?(YARD::CodeObjects::Proxy)
    end

    assert missing.empty?, "Skill docs reference OBJ values that don't resolve: #{missing.join(', ')}"
  end

  private

  def register_custom_tags
    @yardopts_lines.each do |line|
      next unless line.start_with?('--tag ')

      tag, title = line.sub('--tag ', '').strip.split(':', 2)
      YARD::Tags::Library.define_tag(title || tag.capitalize, tag.to_sym)
    end
  end

  def load_registry
    files = @yardopts_lines.reject { |line| line.start_with?('--') }
                           .map { |file| File.join(REPO_ROOT, file) }
    YARD::Registry.clear
    YARD.parse(files)
  end

  def skill_doc_text
    @skill_doc_text ||= Dir.glob(File.join(SKILLS_DIR, '**', '*.md')).map { |f| File.read(f) }.join("\n")
  end

  def tag_names_in_skill_docs
    skill_doc_text.scan(/has_tag\?\(:(\w+)\)/).flatten.map(&:to_sym).uniq
  end

  def obj_references_in_skill_docs
    skill_doc_text.scan(/OBJ=([\w:.#]+)/).flatten.uniq - PLACEHOLDER_REFS
  end
end
