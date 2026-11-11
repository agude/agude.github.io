# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'src/infrastructure/image_derivatives'
require_relative '../../support/image_fixture'

# Tests for ImageDerivatives: WebP copies of configured images, cached and
# published, with the srcset table ImageDimensionsInjector reads. Encoding
# runs the real ImageMagick (in the Docker image and installed in CI).
class TestImageDerivatives < Minitest::Test
  Derivatives = Jekyll::Infrastructure::ImageDerivatives
  SPEC = { 'source_dir' => 'books/covers', 'widths' => [250, 500], 'sizes' => '250px' }.freeze

  def setup
    @source = Dir.mktmpdir('image-derivatives')
    @covers = File.join(@source, 'books', 'covers')
    FileUtils.mkdir_p(@covers)
    Jekyll::Infrastructure::ImageDimensions.reset
  end

  def teardown
    FileUtils.remove_entry(@source)
  end

  # Writes a real, decodable JPEG.
  def write_jpeg(name, width, height)
    path = File.join(@covers, name)
    _out, status = Open3.capture2e(imagemagick, '-size', "#{width}x#{height}", 'xc:#336699', path)
    assert status.success?, 'ImageMagick could not write a fixture JPEG'
    Jekyll::Infrastructure::ImageDimensions.reset
    path
  end

  def imagemagick
    Derivatives.send(:imagemagick)
  end

  def site(spec = SPEC)
    create_site({ 'source' => @source, 'image_derivatives' => spec && [spec] })
  end

  def cache_file(name)
    File.join(@source, Derivatives::CACHE_DIR, 'books', 'covers', 'derived', name)
  end

  def webp_size(path)
    out, status = Open3.capture2(imagemagick, path, '-format', '%m %w %h', 'info:')
    assert status.success?
    out.split.then { |format, width, height| [format, width.to_i, height.to_i] }
  end

  # --- Configuration ---

  def test_no_configuration_builds_nothing
    test_site = site(nil)
    assert_equal({}, Derivatives.build(test_site))
    assert_empty test_site.static_files
  end

  def test_missing_source_dir_raises
    spec = SPEC.merge('source_dir' => 'books/missing')
    error = assert_raises(Jekyll::Errors::FatalException) { Derivatives.build(site(spec)) }
    assert_includes error.message, "'books/missing' does not exist"
  end

  def test_invalid_widths_raise
    [[], [250, -1], ['250'], nil].each do |widths|
      error = assert_raises(Jekyll::Errors::FatalException) { Derivatives.build(site(SPEC.merge('widths' => widths))) }
      assert_includes error.message, 'positive integers'
    end
  end

  def test_missing_sizes_raises
    error = assert_raises(Jekyll::Errors::FatalException) { Derivatives.build(site(SPEC.merge('sizes' => ' '))) }
    assert_includes error.message, 'sizes'
  end

  def test_non_image_file_raises
    File.write(File.join(@covers, 'notes.txt'), 'x')
    error = assert_raises(Jekyll::Errors::FatalException) { Derivatives.build(site) }
    assert_includes error.message, 'books/covers/notes.txt is not a JPEG or PNG'
  end

  def test_sources_sharing_a_stem_raise
    write_jpeg('same.jpg', 1000, 1500)
    write_jpeg('same.png', 1000, 1500)
    error = assert_raises(Jekyll::Errors::FatalException) { Derivatives.build(site) }
    assert_includes error.message, 'books/covers/same.jpg and books/covers/same.png would share derivative names'
  end

  # --- Encoding and publishing ---

  def test_build_encodes_publishes_and_returns_srcset
    write_jpeg('dune.jpg', 1000, 1500)
    test_site = site

    srcsets = Derivatives.build(test_site)

    assert_equal(
      {
        '/books/covers/dune.jpg' => {
          'srcset' => '/books/covers/derived/dune-250.webp 250w, /books/covers/derived/dune-500.webp 500w',
          'sizes' => '250px',
        },
      },
      srcsets,
    )
    assert_equal ['WEBP', 250, 375], webp_size(cache_file('dune-250.webp'))
    assert_equal ['WEBP', 500, 750], webp_size(cache_file('dune-500.webp'))
    published = test_site.static_files.sort_by(&:relative_path)
    assert_equal %w[books/covers/derived/dune-250.webp books/covers/derived/dune-500.webp],
                 published.map(&:relative_path)
    assert_equal [cache_file('dune-250.webp'), cache_file('dune-500.webp')], published.map(&:path)
  end

  # A cover narrower than the widest output joins its own srcset, so a 2x
  # screen is not left with only the 250 px copy.
  def test_narrow_source_skips_wider_outputs_and_lists_original
    write_jpeg('small.jpg', 300, 450)

    srcsets = Derivatives.build(site)

    assert_equal '/books/covers/derived/small-250.webp 250w, /books/covers/small.jpg 300w',
                 srcsets['/books/covers/small.jpg']['srcset']
    refute File.exist?(cache_file('small-500.webp'))
  end

  # A source exactly as wide as the widest output skips that output, so
  # the original must stand in for it.
  def test_source_as_wide_as_largest_width_lists_original
    write_jpeg('exact.jpg', 500, 750)

    srcsets = Derivatives.build(site)

    assert_equal '/books/covers/derived/exact-250.webp 250w, /books/covers/exact.jpg 500w',
                 srcsets['/books/covers/exact.jpg']['srcset']
  end

  # Keys match the injector's lookup (no baseurl); candidates match `src`.
  def test_candidates_carry_baseurl
    write_jpeg('small.jpg', 300, 450)
    test_site = create_site({ 'source' => @source, 'baseurl' => '/preview', 'image_derivatives' => [SPEC] })

    srcsets = Derivatives.build(test_site)

    assert_equal '/preview/books/covers/derived/small-250.webp 250w, /preview/books/covers/small.jpg 300w',
                 srcsets['/books/covers/small.jpg']['srcset']
  end

  # Generators run before :pre_render, so the size memo must be cleared
  # when the site resets, or a replaced cover keeps its old width.
  def test_replaced_source_is_resized_on_rebuild
    wide = File.binread(write_jpeg('wide.jpg', 1000, 1500))
    File.delete(File.join(@covers, 'wide.jpg'))
    write_jpeg('dune.jpg', 300, 450)
    Derivatives.build(site)
    File.binwrite(File.join(@covers, 'dune.jpg'), wide)

    rebuilt = site
    Jekyll::Hooks.trigger(:site, :after_reset, rebuilt)

    assert_equal '/books/covers/derived/dune-250.webp 250w, /books/covers/derived/dune-500.webp 500w',
                 Derivatives.build(rebuilt)['/books/covers/dune.jpg']['srcset']
  end

  def test_source_narrower_than_every_width_gets_no_srcset
    write_jpeg('tiny.jpg', 200, 300)
    assert_equal({}, Derivatives.build(site))
  end

  def test_cached_outputs_are_not_reencoded
    write_jpeg('dune.jpg', 1000, 1500)
    Derivatives.build(site)

    Open3.stub(:capture3, ->(*) { flunk 'encoded a cached output' }) { Derivatives.build(site) }
  end

  def test_changed_source_is_reencoded
    write_jpeg('dune.jpg', 1000, 1500)
    Derivatives.build(site)

    write_jpeg('dune.jpg', 1000, 2000)
    Derivatives.build(site)

    assert_equal ['WEBP', 250, 500], webp_size(cache_file('dune-250.webp'))
  end

  def test_failed_encode_raises_naming_the_source
    File.binwrite(File.join(@covers, 'broken.jpg'), ImageFixture.jpeg(1000, 1500))
    error = assert_raises(Jekyll::Errors::FatalException) { Derivatives.build(site) }
    assert_includes error.message, 'broken.jpg'
    assert_includes error.message, 'failed'
  end

  def test_missing_imagemagick_raises
    write_jpeg('dune.jpg', 1000, 1500)
    Derivatives.instance_variable_set(:@imagemagick, nil)
    error = Open3.stub(:capture2e, ->(*) { raise Errno::ENOENT }) do
      assert_raises(Jekyll::Errors::FatalException) { Derivatives.build(site) }
    end
    assert_includes error.message, 'needs ImageMagick with WebP support'
  ensure
    Derivatives.instance_variable_set(:@imagemagick, nil)
  end

  def test_generator_stores_srcsets_in_site_data
    write_jpeg('dune.jpg', 1000, 1500)
    test_site = site
    Jekyll::Infrastructure::ImageDerivativesGenerator.new.generate(test_site)
    assert_includes test_site.data['image_srcsets'].keys, '/books/covers/dune.jpg'
  end
end
