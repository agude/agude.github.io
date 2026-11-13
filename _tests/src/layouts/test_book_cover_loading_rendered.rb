# frozen_string_literal: true

require_relative '../../test_helper'
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'rbconfig'
require 'yaml'
require 'src/infrastructure/image_derivatives'

# Integration test: builds a fixture book page with the real layouts,
# includes, and plugins, and checks how its cover images load. The build
# runs in a separate Ruby process; see
# _tests/src/seo/test_json_ld_rendered_site.rb.
#
# The lead cover is the first image a reader sees, so it loads eagerly.
# Card covers, here in the related-books section, load lazily. On a page
# that is a list of cards (the author page), the first two cards load
# eagerly (EagerCardImages).
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
    '_books/third_book.md' => <<~MARKDOWN,
      ---
      title: Third Book
      book_authors: Fixture Author
      series: Fixture Saga
      book_number: 3
      rating: 2
      image: /books/covers/third_book.jpg
      wikidata_qid: Q4
      ---

      Third Book is a fixture novel.
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
  }.freeze

  # Real, decodable JPEGs, so ImageDerivatives can encode them.
  COVERS = {
    'books/covers/first_book.jpg' => [600, 900],
    'books/covers/second_book.jpg' => [500, 800],
    'books/covers/third_book.jpg' => [400, 600],
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
    'image_derivatives' => [{ 'source_dir' => 'books/covers', 'widths' => [300, 600], 'sizes' => '300px' }],
    'plugin_log_level' => 'error',
    'quiet' => true,
  }.freeze

  BUILD_SCRIPT = "require 'jekyll'; " \
                 "Jekyll::Site.new(Jekyll.configuration('source' => ARGV[0], 'destination' => ARGV[1])).process"

  def self.page
    @page ||= parse('books/first_book/index.html')
  end

  def self.author_page
    @author_page ||= parse('books/authors/fixture_author/index.html')
  end

  def self.parse(path)
    Nokogiri::HTML5(File.read(File.join(destination, path)))
  end

  # @return [String] The built site's directory.
  def self.destination
    @destination ||= build_fixture_site
  end

  def self.build_fixture_site
    source = Dir.mktmpdir('book-cover-site')
    Minitest.after_run { FileUtils.remove_entry(source) }
    %w[_layouts _includes _plugins].each { |dir| File.symlink(File.join(REPO_ROOT, dir), File.join(source, dir)) }
    File.write(File.join(source, '_config.yml'), CONFIG.to_yaml)
    FILES.each do |path, content|
      full = File.join(source, path)
      FileUtils.mkdir_p(File.dirname(full))
      File.binwrite(full, content)
    end
    COVERS.each { |path, size| write_cover(File.join(source, path), *size) }

    destination = File.join(source, '_site')
    output, status = Open3.capture2e(RbConfig.ruby, '-e', BUILD_SCRIPT, source, destination, chdir: REPO_ROOT)
    raise "Fixture site build failed:\n#{output}" unless status.success?

    destination
  end

  def self.write_cover(path, width, height)
    FileUtils.mkdir_p(File.dirname(path))
    command = Jekyll::Infrastructure::ImageDerivatives.send(:imagemagick)
    output, status = Open3.capture2e(command, '-size', "#{width}x#{height}", 'xc:#336699', path)
    raise "Could not write fixture cover #{path}:\n#{output}" unless status.success?
  end

  def test_lead_cover_loads_eagerly
    lead = self.class.page.at_css('img.book-cover-lead')

    refute_nil lead, 'fixture should render a lead cover'
    assert_equal '/books/covers/first_book.jpg', lead['src']
    assert_nil lead['loading'], 'the lead cover must not be lazy-loaded'
  end

  # The lead cover is the Largest Contentful Paint element on book pages,
  # so it is fetched ahead of other images.
  def test_lead_cover_is_high_priority
    assert_equal 'high', self.class.page.at_css('img.book-cover-lead')['fetchpriority']
  end

  # Width and height let the browser reserve each cover's box before the
  # file loads (ImageDimensionsInjector).
  def test_covers_carry_intrinsic_size
    lead = self.class.page.at_css('img.book-cover-lead')
    card = self.class.page.at_css('.book-card img[src$="/books/covers/second_book.jpg"]')

    assert_equal %w[600 900], [lead['width'], lead['height']]
    assert_equal %w[500 800], [card['width'], card['height']]
  end

  def test_related_card_cover_loads_lazily
    card = self.class.page.at_css('.book-card img[src$="/books/covers/second_book.jpg"]')

    refute_nil card, 'fixture should render a related-book card with a cover'
    assert_equal 'lazy', card['loading']
    assert_equal 'async', card['decoding']
  end

  def test_first_two_cards_on_a_card_list_page_load_eagerly
    loading = self.class.author_page.css('.book-card img').map { |img| img['loading'] }

    assert_equal [nil, nil, 'lazy'], loading
  end

  # The lead cover gets the configured `sizes`; card covers state their
  # own (BookCardRenderer), with `auto` only while lazy. A source no wider than 600 px
  # stands in for the skipped 600 px copy.
  def test_covers_offer_webp_derivatives
    lead = self.class.page.at_css('img.book-cover-lead')
    card = self.class.page.at_css('.book-card img[src$="/books/covers/second_book.jpg"]')

    assert_equal '/books/covers/derived/first_book-300.webp 300w, /books/covers/first_book.jpg 600w', lead['srcset']
    assert_equal '300px', lead['sizes']
    assert_equal '/books/covers/derived/second_book-300.webp 300w, /books/covers/second_book.jpg 500w', card['srcset']
    sizes = Jekyll::Books::Core::BookCardRenderer::COVER_SIZES
    assert_equal "auto, #{sizes}", card['sizes']
    author_sizes = self.class.author_page.css('.book-card img').map { |img| img['sizes'] }
    assert_equal [sizes, sizes, "auto, #{sizes}"], author_sizes
  end

  def test_derivatives_are_published
    derived = File.join(self.class.destination, 'books', 'covers', 'derived')
    assert_equal %w[first_book-300.webp second_book-300.webp third_book-300.webp], Dir.children(derived).sort
  end
end
