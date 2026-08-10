# frozen_string_literal: true

require_relative '../test_helper'
require_relative 'bin_script_helper'

# Covers _bin/check_strict.rb, the CI gate that renders every document under
# strict Liquid so a typo'd variable fails the build instead of silently
# rendering as an empty string.
#
# The fixture is a standalone Jekyll site in a temp directory: no _plugins/,
# no gem plugins, so the script's own behaviour is what is under test rather
# than this site's content.
class TestCheckStrict < Minitest::Test
  include BinScriptHelper

  SCRIPT = 'check_strict.rb'

  CONFIG = <<~YAML
    title: Fixture Site
    url: "https://example.com"
  YAML

  def strict_site(dir)
    write_fixture(dir, '_config.yml', CONFIG)
    yield dir
  end

  def page(front_matter: "title: Page\n", body: 'Body text.')
    "---\n#{front_matter}---\n\n#{body}\n"
  end

  def test_clean_site_passes
    in_fixture_dir do |dir|
      strict_site(dir) do
        write_fixture(dir, 'index.md', page(body: 'Site is {{ site.title }}.'))
      end

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
      assert_includes output, 'Success: All documents passed strict rendering check.'
    end
  end

  def test_undefined_variable_fails_and_names_the_file
    in_fixture_dir do |dir|
      strict_site(dir) do
        write_fixture(dir, 'index.md', page(body: 'Value is {{ nonexistent_variable }}.'))
      end

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, 'Found Liquid rendering errors in strict mode:'
      assert_includes output, 'index.md'
      assert_includes output, 'nonexistent_variable'
    end
  end

  def test_undefined_variable_in_a_collection_document_fails
    in_fixture_dir do |dir|
      strict_site(dir) do
        write_fixture(dir, '_posts/2026-01-01-post.md', page(body: '{{ undefined_in_post }}'))
      end

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, '2026-01-01-post.md'
    end
  end

  def test_generated_feed_and_sitemap_templates_are_excluded
    # jekyll-feed's feed/books.xml references an undefined `lang`, which would
    # otherwise crash the whole check. The exclusion list is the workaround;
    # if it stops matching, this test fails.
    in_fixture_dir do |dir|
      strict_site(dir) do
        write_fixture(dir, 'index.md', page)
        write_fixture(dir, 'feed.xml', page(body: '{{ undefined_in_feed }}'))
        write_fixture(dir, 'sitemap.xml', page(body: '{{ undefined_in_sitemap }}'))
        write_fixture(dir, 'feed/books.xml', page(body: '{{ undefined_in_books_feed }}'))
      end

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
    end
  end

  def test_vendored_files_are_excluded
    in_fixture_dir do |dir|
      strict_site(dir) do
        write_fixture(dir, 'index.md', page)
        write_fixture(dir, 'vendor/bundle/thing.md', page(body: '{{ undefined_in_vendor }}'))
      end

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
    end
  end

  def test_every_failing_document_is_reported_not_just_the_first
    in_fixture_dir do |dir|
      strict_site(dir) do
        write_fixture(dir, 'one.md', page(body: '{{ undefined_one }}'))
        write_fixture(dir, 'two.md', page(body: '{{ undefined_two }}'))
      end

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, 'one.md'
      assert_includes output, 'two.md'
    end
  end
end
