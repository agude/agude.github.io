# frozen_string_literal: true

require_relative '../test_helper'
require_relative 'bin_script_helper'

# Covers _bin/check_rebuild_diff.rb, which lets main skip re-running the site
# gates on its second build. It must fail on any change other than added
# document link tags.
class TestCheckRebuildDiff < Minitest::Test
  include BinScriptHelper

  SCRIPT = 'check_rebuild_diff.rb'
  HEAD = '<head> <title>T</title> </head>'
  LINKED = '<head> <title>T</title> <link rel="site.standard.document" href="at://did/x/1"> </head>'

  def run_check(first_files, second_files)
    in_fixture_dir do |dir|
      first_files.each { |path, content| write_fixture(dir, "first/#{path}", content) }
      second_files.each { |path, content| write_fixture(dir, "second/#{path}", content) }
      yield(*run_bin_script(SCRIPT, dir, 'first', 'second'))
    end
  end

  def test_added_document_links_pass
    first = { 'a/index.html' => HEAD, 'feed.xml' => '<feed/>' }
    run_check(first, first.merge('a/index.html' => LINKED)) do |output, status|
      assert_predicate status, :success?, output
      assert_includes output, 'OK: 2 files'
    end
  end

  def test_other_content_change_fails
    run_check({ 'a/index.html' => HEAD }, { 'a/index.html' => LINKED.sub('T', 'U') }) do |output, status|
      refute_predicate status, :success?
      assert_includes output, 'differs beyond document link tags: a/index.html'
    end
  end

  def test_added_and_removed_files_fail
    run_check({ 'old.html' => HEAD, '.well-known/x' => 'p' }, { 'new.html' => HEAD, '.well-known/x' => 'p' }) do |output, status|
      refute_predicate status, :success?
      assert_includes output, 'only in the first build: old.html'
      assert_includes output, 'only in the second build: new.html'
    end
  end

  def test_document_link_in_first_build_fails
    run_check({ 'a/index.html' => LINKED }, { 'a/index.html' => LINKED }) do |output, status|
      refute_predicate status, :success?
      assert_includes output, 'first build already has a document link tag'
    end
  end

  def test_binary_files_compare_bytes
    png = "\x89PNG\r\n\x1A\n\xFF".b
    run_check({ 'i.png' => png }, { 'i.png' => "#{png}x" }) do |output, status|
      refute_predicate status, :success?
      assert_includes output, 'i.png'
    end
  end

  def test_wrong_arguments_fail
    in_fixture_dir do |dir|
      _output, status = run_bin_script(SCRIPT, dir, 'first')

      refute_predicate status, :success?
    end
  end
end
