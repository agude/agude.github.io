# frozen_string_literal: true

require_relative '../test_helper'

# Enforces the domain layering of _plugins/src: dependencies flow
# content -> (ui, infrastructure) and seo/ui -> infrastructure only.
# Catches a require_relative that reintroduces an inverted dependency
# (e.g. a ui file requiring from content).
#
# Only require_relative edges are checked. Jekyll auto-requires every
# plugin file, so a bare constant reference across domains would still
# work at runtime without appearing here — keep requires explicit.
class TestArchitecture < Minitest::Test
  PLUGINS_ROOT = File.expand_path('../../_plugins/src', __dir__)

  # Which domains each domain may require from. A new edge here is an
  # architectural decision — add it deliberately, with a comment.
  ALLOWED_DEPENDENCIES = {
    'infrastructure' => %w[infrastructure],
    'ui' => %w[ui infrastructure],
    'seo' => %w[seo infrastructure],
    'content' => %w[content ui infrastructure],
  }.freeze

  REQUIRE_RELATIVE = /^\s*require_relative\s+['"]([^'"]+)['"]/

  def each_require_edge
    Dir.glob(File.join(PLUGINS_ROOT, '**', '*.rb')).each do |path|
      source_domain = domain_of(path)
      File.readlines(path).each do |line|
        match = line.match(REQUIRE_RELATIVE)
        next unless match

        target = File.expand_path(match[1], File.dirname(path))
        target += '.rb' unless target.end_with?('.rb')
        yield path, source_domain, target
      end
    end
  end

  def domain_of(path)
    relative = path.delete_prefix("#{PLUGINS_ROOT}/")
    relative.split('/').first
  end

  def test_require_targets_exist
    missing = []
    each_require_edge do |path, _domain, target|
      missing << "#{short(path)} -> #{short(target)}" unless File.exist?(target)
    end

    assert_empty missing,
                 "require_relative targets that do not exist:\n  " \
                 "#{missing.join("\n  ")}"
  end

  def test_domain_dependencies_flow_downward
    violations = []
    each_require_edge do |path, source_domain, target|
      unless target.start_with?("#{PLUGINS_ROOT}/")
        violations << "#{short(path)} requires outside _plugins/src: #{target}"
        next
      end

      target_domain = domain_of(target)
      allowed = ALLOWED_DEPENDENCIES.fetch(source_domain)
      unless allowed.include?(target_domain)
        violations << "#{short(path)} (#{source_domain}) -> #{short(target)} (#{target_domain})"
      end
    end

    assert_empty violations,
                 'Cross-domain requires that violate the layering ' \
                 "(content -> ui -> infrastructure; seo -> infrastructure):\n  " \
                 "#{violations.join("\n  ")}"
  end

  def test_dependency_rules_cover_exactly_the_domains_on_disk
    on_disk = Dir.children(PLUGINS_ROOT)
                 .select { |entry| File.directory?(File.join(PLUGINS_ROOT, entry)) }
                 .sort

    assert_equal(
      ALLOWED_DEPENDENCIES.keys.sort,
      on_disk,
      'Domains under _plugins/src and ALLOWED_DEPENDENCIES have ' \
      'diverged — update the rules table deliberately.',
    )
  end

  private

  def short(path)
    path.delete_prefix("#{PLUGINS_ROOT}/")
  end
end
