# frozen_string_literal: true

require_relative '../test_helper'
require_relative 'bin_script_helper'

# Covers _bin/check_html_structure.sh, the CI gate that proves Jekyll
# actually rendered each page: a missing doctype means a broken layout
# chain, and a leading `---` means front matter shipped verbatim.
class TestCheckHtmlStructure < Minitest::Test
  include BinScriptHelper

  SCRIPT = 'check_html_structure.sh'

  def test_well_formed_pages_pass
    in_fixture_dir do |dir|
      write_fixture(dir, '_site/index.html', html_page)
      write_fixture(dir, '_site/books/index.html', html_page)

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
      assert_includes output, 'All HTML structure checks passed.'
    end
  end

  def test_missing_doctype_fails
    in_fixture_dir do |dir|
      write_fixture(dir, '_site/index.html', html_page)
      write_fixture(dir, '_site/broken.html', "<html><body>No doctype.</body></html>\n")

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, 'missing <!DOCTYPE html>'
      assert_includes output, '_site/broken.html'
    end
  end

  def test_raw_front_matter_fails
    in_fixture_dir do |dir|
      write_fixture(dir, '_site/leaked.html', "---\nlayout: post\n---\n<p>Body.</p>\n")

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, '_site/leaked.html'
    end
  end

  def test_empty_html_file_fails
    in_fixture_dir do |dir|
      write_fixture(dir, '_site/index.html', html_page)
      write_fixture(dir, '_site/empty.html', '')

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, '_site/empty.html'
    end
  end

  def test_a_site_with_no_html_at_all_fails
    # An empty _site means the build produced nothing; passing it silently
    # would let every later gate wave through a site that does not exist.
    in_fixture_dir do |dir|
      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, 'no HTML files'
    end
  end

  def test_triple_dash_inside_a_page_is_not_front_matter
    in_fixture_dir do |dir|
      write_fixture(dir, '_site/code.html', html_page(body: "<pre><code>---\nkey: value\n---</code></pre>"))

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
    end
  end
end
