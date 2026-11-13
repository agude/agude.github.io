# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'fileutils'
require 'src/infrastructure/local_image'

# Tests for LocalImage: the shared resolution of image references.
class TestLocalImage < Minitest::Test
  Local = Jekyll::Infrastructure::LocalImage

  def setup
    @source = Dir.mktmpdir('local-image')
    FileUtils.mkdir_p(File.join(@source, 'files', 'post'))
    File.write(File.join(@source, 'files', 'post', 'a b.png'), 'x')
    @site = create_site({ 'source' => @source, 'url' => 'https://alexgude.com', 'baseurl' => '/preview' })
  end

  def teardown
    FileUtils.remove_entry(@source)
  end

  def resolve(reference)
    Local.resolve(reference, @site)
  end

  def test_root_relative_reference_is_found
    image = resolve(' /files/post/a%20b.png?v=2#top ')
    assert_predicate image, :found?
    assert_equal 'files/post/a b.png', image.relative
    assert_equal File.join(@source, 'files/post/a b.png'), image.file
  end

  def test_site_url_and_baseurl_prefixes_are_local
    assert_predicate resolve('https://alexgude.com/preview/files/post/a%20b.png'), :found?
  end

  def test_other_hosts_and_protocol_relative_urls_are_remote
    %w[https://example.com/x.png //cdn.example.com/x.png data:image/png;base64,AA].each do |reference|
      assert_equal :remote, resolve(reference).status, reference
    end
  end

  def test_url_alone_is_stripped_when_baseurl_is_empty
    site = create_site({ 'source' => @source, 'url' => 'https://alexgude.com/', 'baseurl' => '' })
    assert_predicate Local.resolve('https://alexgude.com/files/post/a%20b.png', site), :found?
  end

  # Only `url/` is a prefix: the bare site URL, or a host that merely
  # starts with it, is another address.
  def test_reference_that_only_starts_with_url_is_remote
    assert_equal :remote, resolve('https://alexgude.com').status
    assert_equal :remote, resolve('https://alexgude.com.evil.test/files/post/a%20b.png').status
  end

  def test_relative_reference
    assert_equal :relative, resolve('files/post/a%20b.png').status
  end

  def test_missing_file_names_where_it_looked
    image = resolve('/files/post/gone.png')
    assert_equal :missing, image.status
    assert_equal File.join(@source, 'files/post/gone.png'), image.file
  end

  # --- file_path ---

  def test_file_path_removes_query_and_fragment
    assert_equal '/files/p.jpg', Local.file_path('/files/p.jpg?v=1')
    assert_equal '/files/p.jpg', Local.file_path('/files/p.jpg#top')
    assert_equal '/files/p.jpg', Local.file_path(' /files/p.jpg?v=1#top ')
  end

  def test_file_path_decodes_percent_encoding_once
    assert_equal '/files/a b.png', Local.file_path('/files/a%20b.png')
    assert_equal '/files/a%20b.png', Local.file_path('/files/a%2520b.png')
    assert_equal '/files/é.png', Local.file_path('/files/%C3%A9.png')
  end

  def test_file_path_keeps_literal_space_and_plus
    assert_equal '/files/a b.png', Local.file_path('/files/a b.png?v=1')
    assert_equal '/files/a+b.png', Local.file_path('/files/a+b.png')
    assert_equal '/files/a+b.png', Local.file_path('/files/a%2Bb.png')
  end

  def test_file_path_decodes_after_removing_the_suffix
    assert_equal '/files/what?.png', Local.file_path('/files/what%3F.png?v=1')
    assert_equal '/files/#1.png', Local.file_path('/files/%231.png#x')
  end
end
