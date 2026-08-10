# frozen_string_literal: true

require_relative '../test_helper'
require_relative 'bin_script_helper'

# Covers _bin/check_reference_links.rb end to end. The scanning rules are
# unit-tested in test_reference_link_scanner.rb; what this file pins is the
# wiring: which documents get scanned, that front-matter line offsets reach
# the printed output, and that every kind of problem fails the build.
class TestCheckReferenceLinks < Minitest::Test
  include BinScriptHelper

  SCRIPT = 'check_reference_links.rb'

  CONFIG = <<~YAML
    title: Fixture Site
    url: "https://example.com"
  YAML

  def reference_site(dir)
    write_fixture(dir, '_config.yml', CONFIG)
    yield dir
  end

  def page(body)
    "---\ntitle: Page\n---\n\n#{body}"
  end

  def test_clean_site_passes
    in_fixture_dir do |dir|
      reference_site(dir) do
        write_fixture(dir, 'index.md', page("See [the docs][docs].\n\n[docs]: https://example.com\n"))
      end

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
      assert_includes output, 'Success: All documents passed reference link check.'
    end
  end

  def test_undefined_reference_fails_with_a_real_file_line_number
    in_fixture_dir do |dir|
      reference_site(dir) do
        # Front matter is 3 lines, blank line is 4, so the link is on line 5.
        write_fixture(dir, 'index.md', page("See [the docs][docs].\n"))
      end

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, 'index.md:5: undefined reference link [docs]'
    end
  end

  def test_duplicate_definition_fails
    in_fixture_dir do |dir|
      reference_site(dir) do
        body = "See [a][dup].\n\n[dup]: https://one.example\n[dup]: https://two.example\n"
        write_fixture(dir, 'index.md', page(body))
      end

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, 'duplicate link definition [dup]'
    end
  end

  def test_orphaned_definition_fails
    # An orphan usually means a link was set up and never attached, which is
    # invisible on the rendered page — the prose just quietly is not a link.
    in_fixture_dir do |dir|
      reference_site(dir) do
        write_fixture(dir, 'index.md', page("Nothing links here.\n\n[unused]: https://example.com\n"))
      end

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, 'orphaned link definition [unused]'
    end
  end

  def test_collection_documents_are_scanned
    in_fixture_dir do |dir|
      reference_site(dir) do
        write_fixture(dir, '_posts/2026-01-01-post.md', page("See [the docs][missing].\n"))
      end

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, '2026-01-01-post.md'
    end
  end

  def test_non_markdown_files_are_skipped
    in_fixture_dir do |dir|
      reference_site(dir) do
        write_fixture(dir, 'index.md', page("Fine.\n"))
        write_fixture(dir, 'feed.xml', page("See [the docs][missing].\n"))
      end

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
    end
  end

  def test_vendored_files_are_skipped
    in_fixture_dir do |dir|
      reference_site(dir) do
        write_fixture(dir, 'index.md', page("Fine.\n"))
        write_fixture(dir, 'vendor/bundle/thing.md', page("See [the docs][missing].\n"))
      end

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
    end
  end
end
