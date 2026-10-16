# frozen_string_literal: true

require_relative '../../test_helper'
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'rbconfig'
require 'yaml'

# Integration test: builds a fixture post with the real layouts, includes,
# and plugins, and checks that every heading permalink anchor has an
# accessible name naming its heading. The build runs in a separate Ruby
# process; see _tests/src/seo/test_json_ld_rendered_site.rb.
class TestHeadingAnchorsRendered < Minitest::Test
  REPO_ROOT = File.expand_path('../../..', __dir__)

  POST = <<~MARKDOWN
    ---
    title: Anchor Fixture
    layout: post
    ---

    Intro paragraph.

    ## Plain Heading

    Text.

    ## Cats & Dogs: `a < b` and `"q"`

    More text.
  MARKDOWN

  CONFIG = {
    'url' => 'https://example.com',
    'baseurl' => '',
    'title' => 'Fixture Site',
    'description' => 'A fixture site.',
    'logo' => '/files/headshot.jpg',
    'author' => { 'name' => 'Site Owner', 'url' => '/resume/' },
    'permalink' => '/blog/:slug/',
    'plugins' => %w[jekyll-feed jekyll-redirect-from jekyll-sitemap],
    'standard_site' => { 'publication_uri' => 'at://did:plc:fixture/site.standard.publication/fixture' },
    'plugin_log_level' => 'error',
    'quiet' => true,
  }.freeze

  BUILD_SCRIPT = "require 'jekyll'; " \
                 "Jekyll::Site.new(Jekyll.configuration('source' => ARGV[0], 'destination' => ARGV[1])).process"

  def self.page
    @page ||= Nokogiri::HTML5(build_fixture_site)
  end

  def self.build_fixture_site
    source = Dir.mktmpdir('anchor-site')
    Minitest.after_run { FileUtils.remove_entry(source) }
    %w[_layouts _includes _plugins].each { |dir| File.symlink(File.join(REPO_ROOT, dir), File.join(source, dir)) }
    File.write(File.join(source, '_config.yml'), CONFIG.to_yaml)
    FileUtils.mkdir_p(File.join(source, '_posts'))
    File.write(File.join(source, '_posts', '2024-01-01-anchor-fixture.md'), POST)

    destination = File.join(source, '_site')
    output, status = Open3.capture2e(RbConfig.ruby, '-e', BUILD_SCRIPT, source, destination, chdir: REPO_ROOT)
    raise "Fixture site build failed:\n#{output}" unless status.success?

    File.read(File.join(destination, 'blog', 'anchor-fixture', 'index.html'))
  end

  def anchors
    self.class.page.css('main h2 a[href^="#"]')
  end

  def test_every_heading_anchor_names_its_heading
    refute_empty anchors

    anchors.each do |anchor|
      heading = anchor.parent.text.strip
      assert_equal "Permalink to #{heading}", anchor['aria-label'], anchor.to_html
    end
  end

  def test_special_characters_survive_in_the_label
    labels = anchors.map { |anchor| anchor['aria-label'] }

    assert_includes labels, 'Permalink to Cats & Dogs: a < b and "q"'
  end
end
