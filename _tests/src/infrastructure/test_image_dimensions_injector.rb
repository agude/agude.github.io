# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'fileutils'
require 'src/infrastructure/image_dimensions_injector'

# Tests for ImageDimensionsInjector: every local <img> in rendered HTML
# gains the width and height of the file it names.
class TestImageDimensionsInjector < Minitest::Test
  Injector = Jekyll::Infrastructure::ImageDimensionsInjector

  def setup
    @source = Dir.mktmpdir('image-dimensions-injector')
    FileUtils.mkdir_p(File.join(@source, 'files', 'post'))
    write_png('files/post/plot.png', 640, 480)
    write_png('files/post/a b.png', 30, 20)
    @site = create_site({ 'source' => @source, 'url' => 'https://alexgude.com', 'baseurl' => '' })
    Jekyll::Infrastructure::ImageDimensions.reset
  end

  def teardown
    FileUtils.remove_entry(@source)
  end

  def write_png(relative, width, height)
    bytes = ["\x89PNG\r\n\x1A\n", 13, 'IHDR', width, height].pack('a8Na4NNx5')
    File.binwrite(File.join(@source, relative), bytes)
  end

  def inject(html, site: @site)
    Injector.inject(html, site, source: '_posts/post.md')
  end

  def assert_raises_naming(html, *fragments)
    error = assert_raises(Jekyll::Errors::FatalException) { inject(html) }
    (['_posts/post.md'] + fragments).each { |fragment| assert_includes error.message, fragment }
  end

  def test_self_closing_tag
    assert_equal '<img src="/files/post/plot.png" alt="Plot" width="640" height="480" />',
                 inject('<img src="/files/post/plot.png" alt="Plot" />')
  end

  def test_unclosed_tag
    assert_equal '<img src="/files/post/plot.png" width="640" height="480">',
                 inject('<img src="/files/post/plot.png">')
  end

  def test_single_quoted_src_and_multiline_tag
    html = "<img\n  alt='Plot'\n  src='/files/post/plot.png'\n/>"
    assert_equal "<img\n  alt='Plot'\n  src='/files/post/plot.png' width=\"640\" height=\"480\"\n/>", inject(html)
  end

  def test_every_tag_in_page_is_sized
    html = '<p><img src="/files/post/plot.png"> and <img src="/files/post/a%20b.png"></p>'
    assert_equal '<p><img src="/files/post/plot.png" width="640" height="480"> and ' \
                 '<img src="/files/post/a%20b.png" width="30" height="20"></p>',
                 inject(html)
  end

  # The figure include captures its URL with surrounding whitespace and a
  # doubled slash.
  def test_padded_src_with_double_slash
    assert_includes inject('<img src=" /files/post//plot.png ">'), 'width="640" height="480"'
  end

  def test_own_absolute_url_is_local
    assert_includes inject('<img src="https://alexgude.com/files/post/plot.png">'), 'width="640"'
  end

  def test_baseurl_prefix_is_removed
    site = create_site({ 'source' => @source, 'url' => 'https://example.com', 'baseurl' => '/blog' })
    assert_includes inject('<img src="/blog/files/post/plot.png">', site: site), 'width="640"'
  end

  def test_query_fragment_and_entities_are_ignored
    assert_includes inject('<img src="/files/post/plot.png?v=1&amp;x=2#top">'), 'width="640"'
  end

  # No CSS fallback reserves a remote image's box, so it stops the build.
  def test_remote_and_data_urls_raise
    [
      'https://cdn.example.com/a.png',
      '//cdn.example.com/a.png',
      'data:image/png;base64,AAAA',
    ].each { |src| assert_raises_naming(%(<img src="#{src}">), src, 'is remote') }
  end

  def test_author_set_size_raises
    assert_raises_naming('<img src="/files/post/plot.png" width="320">', 'sets width', 'CSS')
    assert_raises_naming('<img src="/files/post/plot.png" HEIGHT="48">', 'sets height', 'CSS')
    assert_raises_naming('<img src="/files/post/plot.png" width="1" height="1">', 'sets width and height')
  end

  # --- srcset from ImageDerivatives ---

  def with_srcset
    @site.data['image_srcsets'] = {
      '/files/post/plot.png' => { 'srcset' => '/d/plot-250.webp 250w, /d/plot-500.webp 500w', 'sizes' => '250px' },
    }
  end

  def test_image_with_derivatives_gains_srcset_and_sizes
    with_srcset
    assert_equal '<img src="/files/post/plot.png" width="640" height="480" ' \
                 'srcset="/d/plot-250.webp 250w, /d/plot-500.webp 500w" sizes="250px">',
                 inject('<img src="/files/post/plot.png">')
  end

  # sizes="auto" lets the browser use the laid-out width, but is valid
  # only on a lazy image.
  def test_lazy_image_gets_auto_sizes
    with_srcset
    assert_includes inject('<img src="https://alexgude.com/files/post/plot.png" loading="lazy">'),
                    'sizes="auto, 250px"'
  end

  def test_image_without_derivatives_gets_no_srcset
    with_srcset
    refute_includes inject('<img src="/files/post/a%20b.png">'), 'srcset'
  end

  # A template whose slot differs from the configured one sets its own.
  def test_template_sizes_is_kept
    with_srcset
    assert_equal '<img src="/files/post/plot.png" loading="lazy" sizes="80px" width="640" height="480" ' \
                 'srcset="/d/plot-250.webp 250w, /d/plot-500.webp 500w">',
                 inject('<img src="/files/post/plot.png" loading="lazy" sizes="80px">')
  end

  def test_author_set_srcset_raises
    with_srcset
    assert_raises_naming('<img src="/files/post/plot.png" srcset="/x.png 1x">', 'sets srcset')
  end

  # --- Quote-aware tag scanning ---

  def test_greater_than_inside_alt_is_not_the_tag_end
    assert_equal '<img alt="Revenue > expenses" src="/files/post/plot.png" width="640" height="480">',
                 inject('<img alt="Revenue > expenses" src="/files/post/plot.png">')
  end

  def test_src_text_inside_alt_is_not_the_src
    html = %(<img alt="see src='/files/post/missing.png'" src="/files/post/plot.png">)
    assert_includes inject(html), 'width="640" height="480"'
  end

  def test_unquoted_and_uppercase_attributes
    assert_equal '<IMG SRC=/files/post/plot.png alt=Plot width="640" height="480">',
                 inject('<IMG SRC=/files/post/plot.png alt=Plot>')
  end

  def test_image_inside_comment_is_unchanged
    html = '<!-- <img src="/files/post/missing.png"> --><img src="/files/post/plot.png">'
    assert_equal '<!-- <img src="/files/post/missing.png"> --><img src="/files/post/plot.png" width="640" height="480">',
                 inject(html)
  end

  def test_markup_quoted_in_another_tags_attribute_is_unchanged
    html = %(<div data-example='<img src="/files/post/missing.png">'>) +
           %(<span title="<img src='/files/post/missing.png'>">x</span></div>)
    assert_equal html, inject(html)
  end

  def test_applies_to_html_with_images_in_any_case
    page = Struct.new(:output_ext, :output)
    assert Injector.applies_to?(page.new('.html', '<p><IMG SRC=/a.png></p>'))
    assert Injector.applies_to?(page.new('.html', '<img src="/a.png">'))
    refute Injector.applies_to?(page.new('.html', '<p>no images; <imgur></p>'))
    refute Injector.applies_to?(page.new('.xml', '<img src="/a.png">'))
    refute Injector.applies_to?(page.new('.html', nil))
  end

  def test_image_inside_script_and_style_is_unchanged
    html = %(<script>const t = '<img src="/files/post/missing.png">';</script>) +
           %(<style>/* <img src="/files/post/missing.png"> */</style>)
    assert_equal html, inject(html)
  end

  def test_tag_without_src_raises
    assert_raises_naming('<img alt="x">', '<img alt="x"> has no src')
  end

  def test_escaped_markup_is_not_a_tag
    html = '<code>&lt;img src="/files/post/missing.png"&gt;</code>'
    assert_equal html, inject(html)
  end

  def test_missing_file_raises
    assert_raises_naming('<img src="/files/post/missing.png">', '/files/post/missing.png', 'names no file')
  end

  def test_relative_src_raises
    assert_raises_naming('<img src="plot.png">', 'plot.png', 'is relative')
  end

  def test_unreadable_image_raises
    File.write(File.join(@source, 'files', 'post', 'fake.png'), 'not an image')
    assert_raises(Jekyll::Errors::FatalException) { inject('<img src="/files/post/fake.png">') }
  end
end
