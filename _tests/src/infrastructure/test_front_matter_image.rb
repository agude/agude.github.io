# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'rbconfig'
require 'yaml'
require 'src/infrastructure/front_matter_image'

# Tests for FrontMatterImage, the shared reading of a front-matter `image`.
class TestFrontMatterImage < Minitest::Test
  Image = Jekyll::Infrastructure::FrontMatterImage

  def setup
    @site = create_site({ 'url' => 'https://alexgude.com', 'baseurl' => '/blog' })
  end

  def test_string_path_is_stripped
    assert_equal '/files/p.jpg', Image.path('  /files/p.jpg ')
  end

  # Reversed on purpose: the {path, alt} hash form used to be accepted.
  def test_hash_raises_naming_the_source
    [{ 'path' => '/files/p.jpg', 'alt' => 'Alt' }, {}, { 'path' => nil }].each do |value|
      error = assert_raises(Jekyll::Errors::FatalException) { Image.path(value, source: '_books/x.md') }
      assert_includes error.message, '_books/x.md', value.inspect
      assert_includes error.message, 'must be a string', value.inspect
    end
  end

  def test_hash_raises_through_absolute_url_and_file_path
    hash = { 'path' => '/files/p.jpg', 'alt' => 'Alt' }
    assert_raises(Jekyll::Errors::FatalException) { Image.absolute_url(hash, @site, source: '_books/x.md') }
    assert_raises(Jekyll::Errors::FatalException) { Image.file_path(hash, source: '_books/x.md') }
  end

  def test_blank_values_are_nil
    [nil, '', '   '].each do |value|
      assert_nil Image.path(value), value.inspect
    end
  end

  def test_other_shapes_raise_naming_the_source
    [['/a.jpg'], 42, { 'path' => ['/a.jpg'] }].each do |value|
      error = assert_raises(Jekyll::Errors::FatalException) { Image.path(value, source: '_posts/x.md') }
      assert_includes error.message, '_posts/x.md'
    end
  end

  def test_file_path_removes_query_and_fragment
    assert_equal '/files/p.jpg', Image.file_path('/files/p.jpg?v=1')
    assert_equal '/files/p.jpg', Image.file_path('/files/p.jpg#top')
    assert_equal '/files/p.jpg', Image.file_path(' /files/p.jpg?v=1#top ')
  end

  def test_file_path_decodes_percent_encoding_once
    assert_equal '/files/a b.png', Image.file_path('/files/a%20b.png')
    assert_equal '/files/a%20b.png', Image.file_path('/files/a%2520b.png')
    assert_equal '/files/é.png', Image.file_path('/files/%C3%A9.png')
  end

  def test_file_path_keeps_literal_space_and_plus
    assert_equal '/files/a b.png', Image.file_path('/files/a b.png?v=1')
    assert_equal '/files/a+b.png', Image.file_path('/files/a+b.png')
    assert_equal '/files/a+b.png', Image.file_path('/files/a%2Bb.png')
  end

  def test_file_path_decodes_after_removing_the_suffix
    assert_equal '/files/what?.png', Image.file_path('/files/what%3F.png?v=1')
    assert_equal '/files/#1.png', Image.file_path('/files/%231.png#x')
  end

  def test_file_path_of_blank_is_nil
    assert_nil Image.file_path(nil)
    assert_nil Image.file_path('  ')
  end

  def test_file_path_rejects_other_shapes_naming_the_source
    error = assert_raises(Jekyll::Errors::FatalException) { Image.file_path(42, source: '_posts/x.md') }
    assert_includes error.message, '_posts/x.md'
  end

  def test_source_name_prefers_the_file
    assert_equal '_books/x.md', Image.source_name(create_doc({ 'path' => '_books/x.md' }, '/books/x/'))
  end

  def test_source_name_falls_back_to_the_url
    doc = create_doc({}, '/books/x/')
    doc.relative_path = nil
    assert_equal '/books/x/', Image.source_name(doc)
    assert_equal '/about/', Image.source_name(Struct.new(:url).new('/about/'))
    assert_nil Image.source_name(nil)
  end

  def test_absolute_url_for_local_path_includes_baseurl
    assert_equal 'https://alexgude.com/blog/files/p.jpg', Image.absolute_url('/files/p.jpg', @site)
  end

  def test_absolute_url_leaves_http_urls_unchanged
    assert_equal 'https://cdn.example.com/p.jpg', Image.absolute_url('https://cdn.example.com/p.jpg', @site)
  end

  def test_absolute_url_of_blank_is_nil
    assert_nil Image.absolute_url(nil, @site)
  end
end

# Integration test: a book whose `image` is a hash must stop a real build,
# whichever consumer reads the image first. The build runs in a separate
# Ruby process; see _tests/src/seo/test_json_ld_rendered_site.rb.
class TestFrontMatterImageHashBuild < Minitest::Test
  REPO_ROOT = File.expand_path('../../..', __dir__)

  STRING_IMAGE = 'image: /files/cover.jpg'
  HASH_IMAGE = "image:\n  path: /files/cover.jpg\n  alt: A cover"

  BOOK = <<~MARKDOWN
    ---
    title: Hash Image
    book_authors: Fixture Author
    series: null
    book_number: 1
    rating: 3
    wikidata_qid: Q1
    %<image>s
    ---

    Hash Image is a fixture book.
  MARKDOWN

  AUTHOR = <<~MARKDOWN
    ---
    layout: author_page
    title: Fixture Author
    wikidata_qid: Q2
    ---
  MARKDOWN

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

  def test_hash_image_stops_the_build_naming_the_book
    output, status = build(HASH_IMAGE)

    refute status.success?, "The build succeeded:\n#{output}"
    assert_includes output, '_books/hash_image.md'
    assert_includes output, 'must be a string'
  end

  # Control: the same fixture with a string image builds, so the failure
  # above comes from the image shape.
  def test_string_image_fixture_builds
    output, status = build(STRING_IMAGE)

    assert status.success?, "The fixture build failed:\n#{output}"
  end

  private

  def build(image_front_matter)
    Dir.mktmpdir('hash-image-site') do |source|
      write_fixture(source, format(BOOK, image: image_front_matter))
      Open3.capture2e(RbConfig.ruby, '-e', BUILD_SCRIPT, source, File.join(source, '_site'), chdir: REPO_ROOT)
    end
  end

  def write_fixture(source, book)
    %w[_layouts _includes _plugins].each { |dir| File.symlink(File.join(REPO_ROOT, dir), File.join(source, dir)) }
    File.write(File.join(source, '_config.yml'), CONFIG.to_yaml)
    {
      '_books/hash_image.md' => book,
      'books/authors/fixture_author.md' => AUTHOR,
      'files/cover.jpg' => 'jpg',
      'files/headshot.jpg' => 'jpg',
    }.each do |path, body|
      FileUtils.mkdir_p(File.join(source, File.dirname(path)))
      File.write(File.join(source, path), body)
    end
  end
end
