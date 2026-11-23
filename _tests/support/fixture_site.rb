# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'open3'
require 'rbconfig'
require 'yaml'

# Run Jekyll with the real plugins in a fresh process. Other tests define
# stub Jekyll::Converter subclasses, which Jekyll would otherwise instantiate.
module FixtureSite
  REPO_ROOT = File.expand_path('../..', __dir__)
  Build = Struct.new(:destination, :output, :status, keyword_init: true) do
    def destination!
      raise "Fixture site build failed:\n#{output}" unless status.success?

      destination
    end
  end

  CONFIG = {
    'url' => 'https://example.com',
    'baseurl' => '',
    'title' => 'Fixture Site',
    'description' => 'A fixture site.',
    'logo' => '/files/headshot.jpg',
    'author' => { 'name' => 'Site Owner', 'url' => '/resume/' },
    'permalink' => '/blog/:slug/',
    'collections' => { 'books' => { 'output' => true, 'permalink' => '/books/:path/' } },
    'defaults' => [{ 'scope' => { 'path' => '', 'type' => 'books' }, 'values' => { 'layout' => 'book' } }],
    'plugins' => %w[jekyll-feed jekyll-redirect-from jekyll-sitemap],
    'standard_site' => { 'publication_uri' => 'at://did:plc:fixture/site.standard.publication/fixture' },
    'plugin_log_level' => 'error',
    'quiet' => true,
    'timezone' => 'UTC',
  }.freeze

  BUILD_SCRIPT = <<~RUBY
    require 'jekyll'
    Jekyll::Site.new(Jekyll.configuration('source' => ARGV[0], 'destination' => ARGV[1])).process
  RUBY

  def self.build(files:, config: {})
    source = Dir.mktmpdir('jekyll-fixture-site')
    Minitest.after_run { FileUtils.remove_entry(source) }
    %w[_layouts _includes _plugins].each do |dir|
      File.symlink(File.join(REPO_ROOT, dir), File.join(source, dir))
    end
    File.write(File.join(source, '_config.yml'), CONFIG.merge(config).to_yaml)
    files.each do |path, content|
      full_path = File.join(source, path)
      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, content)
    end

    destination = File.join(source, '_site')
    output, status = Open3.capture2e(RbConfig.ruby, '-e', BUILD_SCRIPT, source, destination, chdir: REPO_ROOT)
    Build.new(destination: destination, output: output, status: status)
  end
end
