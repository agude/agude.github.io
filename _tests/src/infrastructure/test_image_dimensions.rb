# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'fileutils'
require 'src/infrastructure/image_dimensions'

# Tests for ImageDimensions: the display size of a local image. Raster
# cases check FastImage on the behavior the site relies on, notably EXIF
# orientation; SVG cases check the Nokogiri reader.
class TestImageDimensions < Minitest::Test
  Dimensions = Jekyll::Infrastructure::ImageDimensions
  REPO_ROOT = File.expand_path('../../..', __dir__)

  def setup
    @dir = Dir.mktmpdir('image-dimensions')
    Dimensions.reset
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def write(name, bytes)
    path = File.join(@dir, name)
    File.binwrite(path, bytes)
    path
  end

  def assert_size(expected, bytes, name: 'image.bin')
    assert_equal expected, Dimensions.of(write(name, bytes))
  end

  def assert_fails(bytes, message, name: 'image.bin')
    error = assert_raises(Jekyll::Errors::FatalException) { Dimensions.of(write(name, bytes)) }
    assert_includes error.message, message
    assert_includes error.message, name
  end

  # --- Fixture builders ---

  def png(width, height)
    ["\x89PNG\r\n\x1A\n", 13, 'IHDR', width, height].pack('a8Na4NNx5')
  end

  def gif(width, height)
    'GIF89a'.b + [width, height].pack('vv') + ("\0" * 3)
  end

  def jpeg_segment(marker, payload)
    [0xFF, marker].pack('CC') + [payload.bytesize + 2].pack('n') + payload
  end

  def jpeg_sof(width, height, marker: 0xC0)
    jpeg_segment(marker, [8, height, width, 3].pack('CnnC') + ("\0" * 9))
  end

  def exif(orientation, byte_order: :little)
    short, long, mark = byte_order == :little ? %w[v V II] : %w[n N MM]
    tiff = mark + [42].pack(short) + [8].pack(long) + [1].pack(short) +
           [0x0112, 3, 1].pack("#{short}#{short}#{long}") + [orientation, 0].pack("#{short}#{short}") +
           [0].pack(long)
    jpeg_segment(0xE1, "Exif\0\0".b + tiff.b)
  end

  def jpeg(*segments)
    "\xFF\xD8".b + segments.join.b + "\xFF\xD9".b
  end

  def svg(attributes)
    %(<?xml version="1.0"?>\n<svg xmlns="http://www.w3.org/2000/svg"\n  #{attributes}>\n</svg>\n)
  end

  # --- PNG and GIF ---

  def test_png
    assert_size [640, 480], png(640, 480)
  end

  def test_gif
    assert_size [16, 9], gif(16, 9)
  end

  def test_truncated_png_raises
    assert_fails png(640, 480).byteslice(0, 18), 'is not a readable image'
  end

  # --- JPEG ---

  def test_jpeg_baseline
    assert_size [800, 1200], jpeg(jpeg_segment(0xE0, "JFIF\0".b), jpeg_sof(800, 1200))
  end

  def test_jpeg_orientation_six_swaps_axes
    assert_size [1200, 800], jpeg(exif(6), jpeg_sof(800, 1200))
  end

  def test_jpeg_orientation_big_endian_swaps_axes
    assert_size [1200, 800], jpeg(exif(8, byte_order: :big), jpeg_sof(800, 1200))
  end

  def test_jpeg_orientation_three_keeps_axes
    assert_size [800, 1200], jpeg(exif(3), jpeg_sof(800, 1200))
  end

  # XMP is also APP1; it must not reset the EXIF orientation read before it.
  def test_jpeg_xmp_after_exif_keeps_orientation
    xmp = jpeg_segment(0xE1, "http://ns.adobe.com/xap/1.0/\0<x:xmpmeta/>".b)
    assert_size [1200, 800], jpeg(exif(6), xmp, jpeg_sof(800, 1200))
  end

  def test_jpeg_non_exif_app1_is_ignored
    assert_size [800, 1200], jpeg(jpeg_segment(0xE1, 'http://ns.adobe.com/xap/1.0/'.b), jpeg_sof(800, 1200))
  end

  def test_jpeg_without_frame_raises
    assert_fails jpeg(jpeg_segment(0xE0, "JFIF\0".b)), 'is not a readable image'
  end

  # --- SVG ---

  def test_svg_unitless
    assert_size [499, 306], svg('width="499" height="306"'), name: 'a.svg'
  end

  def test_svg_fractional_px_rounds
    assert_size [1386, 281], svg('width="1385.8634px" height="280.78281px"'), name: 'a.svg'
  end

  def test_svg_points
    assert_size [768, 768], svg('height="576pt" viewBox="0 0 576 576" width="576pt"'), name: 'a.svg'
  end

  def test_svg_millimetres
    assert_size [96, 192], svg("width='25.4mm' height='50.8mm'"), name: 'a.svg'
  end

  def test_svg_entity_in_attribute_is_decoded
    assert_size [100, 50], svg('width="&#49;00" height="50"'), name: 'a.svg'
  end

  def test_svg_namespace_prefixed_root
    bytes = %(<svg:svg xmlns:svg="http://www.w3.org/2000/svg" width="30" height="20"/>)
    assert_size [30, 20], bytes, name: 'a.svg'
  end

  def test_svg_with_doctype_and_comment_before_root
    bytes = %(<?xml version="1.0"?>\n<!-- Created with Inkscape -->\n) +
            %(<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n) +
            svg('width="12" height="34"').sub(/\A<\?xml[^>]*>\n/, '')
    assert_size [12, 34], bytes, name: 'a.svg'
  end

  def test_xml_without_svg_root_raises
    assert_fails '<html width="10" height="10"/>', 'without an <svg> root', name: 'a.svg'
  end

  def test_zero_dimension_raises
    assert_fails png(0, 480), 'zero dimension'
  end

  def test_svg_percentage_raises
    assert_fails svg('width="100%" height="100%"'), "root width is '100%'", name: 'a.svg'
  end

  def test_svg_missing_size_raises
    assert_fails svg('viewBox="0 0 10 10"'), 'root width is missing', name: 'a.svg'
  end

  def test_unknown_format_raises
    assert_fails 'plain text', 'is not a readable image', name: 'notes.txt'
  end

  def test_missing_file_raises
    error = assert_raises(Jekyll::Errors::FatalException) { Dimensions.of(File.join(@dir, 'gone.png')) }
    assert_includes error.message, 'cannot be read'
  end

  # --- Per-build memo ---

  def test_size_is_memoized_until_reset
    path = write('a.png', png(10, 20))
    assert_equal [10, 20], Dimensions.of(path)

    File.binwrite(path, png(30, 40))
    assert_equal [10, 20], Dimensions.of(path), 'memoized within a build'

    Dimensions.reset
    assert_equal [30, 40], Dimensions.of(path)
  end

  # --- Real site files, sizes checked with ImageMagick `identify` ---

  def test_real_site_images
    {
      'books/covers/a_canticle_for_leibowitz.jpg' => [834, 1198],
      'files/resnet/20_vs_56.png' => [1000, 335],
      'files/vim_eldar/eldar_elflord_cpp.gif' => [654, 716],
      'files/tdf-prize-money/TdFPrizeMoney.svg' => [499, 306],
    }.each do |relative, size|
      assert_equal size, Dimensions.of(File.join(REPO_ROOT, relative)), relative
    end
  end
end
