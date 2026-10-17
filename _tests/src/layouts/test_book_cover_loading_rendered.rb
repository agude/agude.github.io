# frozen_string_literal: true

require_relative '../../test_helper'
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'rbconfig'
require 'yaml'

# Integration test: builds a fixture book page with the real layouts,
# includes, and plugins, and checks how its cover images load. The build
# runs in a separate Ruby process; see
# _tests/src/seo/test_json_ld_rendered_site.rb.
#
# The lead cover is the first image a reader sees, so it loads eagerly.
# Card covers, here in the related-books section, load lazily.
class TestBookCoverLoadingRendered < Minitest::Test
  REPO_ROOT = File.expand_path('../../..', __dir__)

  FILES = {
    '_books/first_book.md' => <<~MARKDOWN,
      ---
      title: First Book
      book_authors: Fixture Author
      series: Fixture Saga
      book_number: 1
      rating: 4
      image: /books/covers/first_book.jpg
      wikidata_qid: Q1
      ---

      First Book is a fixture novel.
    MARKDOWN
    '_books/second_book.md' => <<~MARKDOWN,
      ---
      title: Second Book
      book_authors: Fixture Author
      series: Fixture Saga
      book_number: 2
      rating: 3
      image: /books/covers/second_book.jpg
      wikidata_qid: Q2
      ---

      Second Book is a fixture novel.
    MARKDOWN
    'books/authors/fixture_author.md' => <<~MARKDOWN,
      ---
      layout: author_page
      title: Fixture Author
      wikidata_qid: Q3
      ---
    MARKDOWN
    'books/series/fixture_saga.md' => <<~MARKDOWN,
      ---
      layout: series_page
      title: Fixture Saga
      ---
    MARKDOWN
    'books/covers/first_book.jpg' => 'not a real image',
    'books/covers/second_book.jpg' => 'not a real image',
  }.freeze

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
  }.freeze

  BUILD_SCRIPT = "require 'jekyll'; " \
                 "Jekyll::Site.new(Jekyll.configuration('source' => ARGV[0], 'destination' => ARGV[1])).process"

  def self.page
    @page ||= Nokogiri::HTML5(build_fixture_site)
  end

  def self.build_fixture_site
    source = Dir.mktmpdir('book-cover-site')
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

    File.read(File.join(destination, 'books', 'first_book', 'index.html'))
  end

  def test_lead_cover_loads_eagerly
    lead = self.class.page.at_css('img.book-cover-lead')

    refute_nil lead, 'fixture should render a lead cover'
    assert_equal '/books/covers/first_book.jpg', lead['src']
    assert_nil lead['loading'], 'the lead cover must not be lazy-loaded'
  end

  def test_related_card_cover_loads_lazily
    card = self.class.page.at_css('.book-card img[src$="/books/covers/second_book.jpg"]')

    refute_nil card, 'fixture should render a related-book card with a cover'
    assert_equal 'lazy', card['loading']
    assert_equal 'async', card['decoding']
  end
end
