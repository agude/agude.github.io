# frozen_string_literal: true

require 'test_helper'
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

  def test_hash_form_uses_path
    assert_equal '/files/p.jpg', Image.path({ 'path' => '/files/p.jpg', 'alt' => 'Alt' })
  end

  def test_blank_values_are_nil
    [nil, '', '   ', {}, { 'path' => nil }, { 'path' => ' ' }].each do |value|
      assert_nil Image.path(value), value.inspect
    end
  end

  def test_other_shapes_raise_naming_the_source
    [['/a.jpg'], 42, { 'path' => ['/a.jpg'] }].each do |value|
      error = assert_raises(Jekyll::Errors::FatalException) { Image.path(value, source: '_posts/x.md') }
      assert_includes error.message, '_posts/x.md'
    end
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
