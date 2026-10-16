# frozen_string_literal: true

require_relative '../../../../test_helper'
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'rbconfig'
require 'yaml'

# Integration test: builds a fixture site with the real layouts, includes,
# and plugins, and checks the by-author page's HTML ids. Two authors share a
# series, which used to repeat the series id once per author. The build
# runs in a separate Ruby process; see test_json_ld_rendered_site.rb.
class TestByAuthorPageRendered < Minitest::Test
  REPO_ROOT = File.expand_path('../../../../..', __dir__)

  def self.book(title, author, number)
    <<~MARKDOWN
      ---
      title: #{title}
      book_authors: #{author}
      series: Shared Saga
      book_number: #{number}
      rating: 3
      wikidata_qid: Q#{number}
      ---

      A review of #{title}.
    MARKDOWN
  end

  FILES = {
    '_books/first_book.md' => book('First Book', 'Ann Author', 1),
    '_books/second_book.md' => book('Second Book', 'Bob Author', 2),
    'books/authors/ann_author.md' => "---\nlayout: author_page\ntitle: Ann Author\nwikidata_qid: Q11\n---\n",
    'books/authors/bob_author.md' => "---\nlayout: author_page\ntitle: Bob Author\nwikidata_qid: Q12\n---\n",
    'books/series/shared_saga.md' => "---\nlayout: series_page\ntitle: Shared Saga\n---\n",
    'books/by_author.md' => <<~MARKDOWN,
      ---
      title: By Author
      layout: page
      permalink: /books/by-author/
      ---

      {% display_books_by_author_then_series %}
    MARKDOWN
  }.freeze

  CONFIG = {
    'url' => 'https://example.com',
    'baseurl' => '',
    'title' => 'Fixture Site',
    'description' => 'A fixture site.',
    'logo' => '/files/headshot.jpg',
    'author' => { 'name' => 'Site Owner', 'url' => '/resume/' },
    'collections' => { 'books' => { 'output' => true, 'permalink' => '/books/:path/' } },
    'defaults' => [{ 'scope' => { 'path' => '', 'type' => 'books' }, 'values' => { 'layout' => 'book' } }],
    'plugins' => %w[jekyll-feed jekyll-redirect-from jekyll-sitemap],
    'standard_site' => { 'publication_uri' => 'at://did:plc:fixture/site.standard.publication/fixture' },
    'plugin_log_level' => 'error',
    'quiet' => true,
  }.freeze

  BUILD_SCRIPT = "require 'jekyll'; " \
                 "Jekyll::Site.new(Jekyll.configuration('source' => ARGV[0], 'destination' => ARGV[1])).process"

  def self.page_html
    @page_html ||= build_fixture_site
  end

  def self.build_fixture_site
    source = Dir.mktmpdir('by-author-site')
    Minitest.after_run { FileUtils.remove_entry(source) }
    %w[_layouts _includes _plugins].each { |dir| File.symlink(File.join(REPO_ROOT, dir), File.join(source, dir)) }
    File.write(File.join(source, '_config.yml'), CONFIG.to_yaml)
    FILES.each do |path, content|
      full = File.join(source, path)
      FileUtils.mkdir_p(File.dirname(full))
      File.write(full, content)
    end

    destination = File.join(source, '_site')
    output, status = Open3.capture2e(RbConfig.ruby, '-e', BUILD_SCRIPT, source, destination, chdir: REPO_ROOT)
    raise "Fixture site build failed:\n#{output}" unless status.success?

    File.read(File.join(destination, 'books/by-author/index.html'))
  end

  def test_no_id_repeats
    ids = self.class.page_html.scan(/\sid="([^"]*)"/).flatten
    duplicates = ids.tally.select { |_, count| count > 1 }.keys

    assert_equal 2, self.class.page_html.scan('class="series-title"').length, 'both authors list the series'
    assert_empty duplicates
  end

  def test_navigation_targets_exist
    html = self.class.page_html
    ids = html.scan(/\sid="([^"]*)"/).flatten
    nav = html[%r{<nav class="alpha-jump-links">.*?</nav>}m]
    targets = nav.scan(/href="#([^"]*)"/).flatten

    refute_empty targets
    assert_empty targets - ids
  end
end
