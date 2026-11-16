# frozen_string_literal: true

require_relative 'test_helper'
require 'open3'
require 'rbconfig'

# The publisher's Python tests consume the same YAML fixtures. Build them
# with real Jekyll to check the timestamps and which pages actually exist.
# A separate process avoids converter stubs installed by other Ruby tests.
class TestAtprotoDates < Minitest::Test
  BUILD_SCRIPT = <<~'RUBY'
    require 'jekyll'
    require 'json'
    require 'tmpdir'
    require 'fileutils'

    JSON.parse(File.read(ARGV[0])).each do |fixture|
      Dir.mktmpdir('atproto-dates') do |source|
        %w[_posts _books].each { |dir| FileUtils.mkdir_p(File.join(source, dir)) }
        content = "---\ntitle: Fixture\ndate: #{fixture.fetch('date_yaml')}\n---\nFixture.\n"
        instant = Time.iso8601(fixture.fetch('instant'))
        File.write(File.join(source, "_posts/#{instant.strftime('%Y-%m-%d')}-fixture.md"), content)
        File.write(File.join(source, '_books/fixture.md'), content)

        [-1, 0, 1].each do |seconds|
          destination = File.join(source, "_site_#{seconds}")
          config = {
            'source' => source,
            'destination' => destination,
            'timezone' => 'America/Los_Angeles',
            'time' => (instant + seconds).utc.iso8601,
            'future' => false,
            'permalink' => '/blog/:slug/',
            'collections' => { 'books' => { 'output' => true, 'permalink' => '/books/:path/' } },
            'exclude' => %w[_site_-1 _site_0 _site_1],
            'quiet' => true,
          }
          config_path = File.join(source, '_config.yml')
          File.write(config_path, config.to_yaml)
          site = Jekyll::Site.new(Jekyll.configuration('config' => config_path))
          site.process
          book = site.collections.fetch('books').docs.first
          abort "Wrong instant: #{fixture.inspect}: #{book.date}" unless book.date == instant

          %w[blog books].each do |directory|
            page = File.join(destination, directory, 'fixture/index.html')
            next if File.exist?(page) == (seconds >= 0)

            abort "Wrong publication cutoff: #{fixture.inspect}, #{seconds}, #{directory}"
          end
        end
      end
    end
  RUBY

  def test_yaml_dates_and_publish_cutoffs_match_jekyll
    fixtures = File.expand_path('../_scripts/tests/fixtures/atproto_dates.json', __dir__)
    output, status = Open3.capture2e(RbConfig.ruby, '-e', BUILD_SCRIPT, fixtures)

    assert status.success?, output
  end
end
