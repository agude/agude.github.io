# frozen_string_literal: true

require_relative '../../test_helper'

# Tests for Jekyll::Infrastructure::GeneratedStaticFile.
#
# Verifies that generated content is written to the destination
# instead of copying a source file.
class TestGeneratedStaticFile < Minitest::Test
  def setup
    @site = create_site({ 'source' => Dir.mktmpdir })
    @dest = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@site.config['source'])
    FileUtils.rm_rf(@dest)
  end

  def test_write_creates_file_with_content
    content = "# Hello\n\nThis is generated Markdown.\n"
    file = Jekyll::Infrastructure::GeneratedStaticFile.new(@site, '/blog/post/', 'index.md', content)

    file.write(@dest)

    written = File.read(File.join(@dest, 'blog', 'post', 'index.md'))
    assert_equal content, written
  end

  def test_write_creates_parent_directories
    file = Jekyll::Infrastructure::GeneratedStaticFile.new(@site, '/deep/nested/path/', 'output.md', 'content')

    file.write(@dest)

    assert File.exist?(File.join(@dest, 'deep', 'nested', 'path', 'output.md'))
  end

  def test_write_returns_true
    file = Jekyll::Infrastructure::GeneratedStaticFile.new(@site, '/', 'test.md', 'content')

    result = file.write(@dest)

    assert_equal true, result
  end
end
