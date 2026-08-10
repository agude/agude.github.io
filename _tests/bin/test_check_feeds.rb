# frozen_string_literal: true

require_relative '../test_helper'
require_relative 'bin_script_helper'

# Covers _bin/check_feeds.rb, the CI gate that proves the generated feed XML
# is real XML with entries in it — the failure it exists to catch is Jekyll
# shipping an unrendered Liquid template as feed.xml.
class TestCheckFeeds < Minitest::Test
  include BinScriptHelper

  SCRIPT = 'check_feeds.rb'

  def test_valid_atom_feed_passes
    in_fixture_dir do |dir|
      write_fixture(dir, '_site/feed.xml', atom_feed(count: 3))

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
      assert_includes output, 'OK (3 entries)'
    end
  end

  def test_every_feed_is_checked_not_just_the_first
    in_fixture_dir do |dir|
      write_fixture(dir, '_site/feed.xml', atom_feed(count: 1))
      write_fixture(dir, '_site/feed/books.xml', atom_feed(count: 2))

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
      assert_includes output, '_site/feed.xml'
      assert_includes output, '_site/feed/books.xml'
    end
  end

  def test_missing_feeds_fail
    in_fixture_dir do |dir|
      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, 'no feed XML files found'
    end
  end

  def test_unrendered_liquid_template_fails
    in_fixture_dir do |dir|
      write_fixture(dir, '_site/feed.xml', "---\nlayout: none\n---\n<feed>{{ site.title }}</feed>\n")

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, 'starts with raw Liquid/HTML'
    end
  end

  def test_feed_without_entries_fails
    in_fixture_dir do |dir|
      write_fixture(dir, '_site/feed.xml', atom_feed(count: 0))

      output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
      assert_includes output, 'no entries'
    end
  end

  def test_malformed_xml_fails
    in_fixture_dir do |dir|
      write_fixture(dir, '_site/feed.xml', "<?xml version=\"1.0\"?>\n<feed><entry></feed>\n")

      _output, status = run_bin_script(SCRIPT, dir)

      refute_predicate status, :success?
    end
  end

  def test_non_feed_xml_is_ignored
    in_fixture_dir do |dir|
      write_fixture(dir, '_site/feed.xml', atom_feed(count: 1))
      # sitemap.xml has no <feed>/<rss> root, so it must not be validated as
      # a feed — it legitimately has no <entry> elements.
      write_fixture(dir, '_site/sitemap.xml', "<?xml version=\"1.0\"?>\n<urlset><url><loc>/</loc></url></urlset>\n")

      output, status = run_bin_script(SCRIPT, dir)

      assert_predicate status, :success?, output
      refute_includes output, 'sitemap.xml'
    end
  end
end
