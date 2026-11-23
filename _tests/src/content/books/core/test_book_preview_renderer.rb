# frozen_string_literal: true

require_relative '../../../../test_helper'

# Tests for Jekyll::Books::Core::BookPreviewRenderer.
#
# Verifies that the renderer produces the exact single-line hover-preview
# markup consumed by the book-link hover feature, and that the
# `<!--book-preview-->` comment markers (load-bearing for downstream
# stripping) are always present around it.
class TestBookPreviewRenderer < Minitest::Test
  Renderer = Jekyll::Books::Core::BookPreviewRenderer

  def setup
    @site = create_site
    @page = create_doc({ 'path' => 'current.html' }, '/current.html')
    @ctx = create_context({}, { site: @site, page: @page })
    @site.config['plugin_logging']['BOOK_PREVIEW_RATING_ERROR'] = true
  end

  def build(title: 'Dune', authors: ['Frank Herbert'], rating: 5, image: '/images/dune.jpg', context: @ctx,
            series: nil, book_number: nil, lede_html: nil)
    Renderer.new(context, title, authors, rating, image, series: series, book_number: book_number, lede_html: lede_html)
  end

  def test_full_markup
    result = build(
      authors: ['Frank Herbert', 'Second Author', 'Third Author'],
      series: 'Dune',
      book_number: 1,
      lede_html: "Read <cite>Dune</cite>\nnext.",
    ).render
    expected = '<!--book-preview--><span class="book-link-preview" aria-hidden="true" hidden>' \
               '<img class="book-link-preview-cover" src="/images/dune.jpg" alt="Cover of Dune" loading="lazy" decoding="async" sizes="(min-width: 38em) 100px, 80px" />' \
               '<span class="book-link-preview-text">' \
               '<span class="book-link-preview-title">Dune</span>' \
               '<span class="book-link-preview-author">by Frank Herbert, Second Author, and Third Author</span>' \
               '<span class="book-rating star-rating-5" role="img" aria-label="Rating: 5 out of 5 stars. ' \
               'Masterpiece — I loved it" title="Masterpiece — I loved it">' \
               '<span class="book_star full_star" aria-hidden="true">★</span>' \
               '<span class="book_star full_star" aria-hidden="true">★</span>' \
               '<span class="book_star full_star" aria-hidden="true">★</span>' \
               '<span class="book_star full_star" aria-hidden="true">★</span>' \
               '<span class="book_star full_star" aria-hidden="true">★</span>' \
               '</span>' \
               '<span class="book-link-preview-series"><span class="book-series">Dune</span>&thinsp;#1</span>' \
               '</span><span class="book-link-preview-lede">Read <cite>Dune</cite> next.</span>' \
               '</span><!--/book-preview-->'
    assert_equal expected, result
  end

  def test_no_image_omits_cover_span
    result = build(image: nil).render
    refute_match(/book-link-preview-cover/, result)
  end

  def test_empty_image_omits_cover_span
    result = build(image: '').render
    refute_match(/book-link-preview-cover/, result)
  end

  def test_no_rating_omits_stars
    result = build(rating: nil).render
    refute_match(/book-rating/, result)
    refute_match(/book_star/, result)
  end

  def test_invalid_rating_omits_stars_and_logs
    renderer = build(rating: 99)
    result = nil
    Jekyll.stub :logger, silent_logger do
      result = renderer.render
    end
    refute_match(/book-rating/, result)
    refute_match(/book_star/, result)
    assert_match(/BOOK_PREVIEW_RATING_ERROR_FAILURE/, renderer.log_output)
  end

  def test_invalid_rating_log_not_embedded_in_preview_span
    renderer = build(rating: 'not-a-number')
    result = nil
    Jekyll.stub :logger, silent_logger do
      result = renderer.render
    end
    refute_match(/BOOK_PREVIEW_RATING_ERROR/, result)
  end

  def test_empty_authors_omits_author_span
    result = build(authors: []).render
    refute_match(/book-link-preview-author/, result)
  end

  def test_nil_authors_omits_author_span
    result = build(authors: nil).render
    refute_match(/book-link-preview-author/, result)
  end

  def test_more_than_three_authors_uses_et_al
    result = build(authors: ['A. One', 'B. Two', 'C. Three', 'D. Four']).render
    assert_match(%r{by A\. One <abbr class="etal">et al\.</abbr>}, result)
    refute_match(/B\. Two/, result)
  end

  def test_escapes_title_html
    result = build(title: 'Cat & <Mouse>').render
    assert_includes result, '<span class="book-link-preview-title">Cat &amp; &lt;Mouse&gt;</span>'
  end

  def test_escapes_author_html
    result = build(authors: ['A & <B>']).render
    assert_includes result, 'by A &amp; &lt;B&gt;'
  end

  def test_escapes_image_attribute
    result = build(image: "/images/dune's \"cover\".jpg").render
    assert_includes result, 'src="/images/dune&#39;s &quot;cover&quot;.jpg"'
  end

  def test_series_without_number
    result = build(series: 'Dune', book_number: nil).render
    assert_includes result, '<span class="book-link-preview-series"><span class="book-series">Dune</span></span>'
  end

  def test_nil_series_omits_series_span
    result = build(series: nil).render
    refute_match(/book-link-preview-series/, result)
  end

  def test_blank_series_omits_series_span
    result = build(series: '   ').render
    refute_match(/book-link-preview-series/, result)
  end

  def test_escapes_series_html
    result = build(series: 'Cat & <Mouse>', book_number: 1).render
    assert_includes result, '<span class="book-series">Cat &amp; &lt;Mouse&gt;</span>'
  end

  def test_lede_omitted_when_nil
    result = build(lede_html: nil).render
    refute_includes result, 'book-link-preview-lede'
  end

  def test_lede_omitted_when_blank
    result = build(lede_html: '   ').render
    refute_includes result, 'book-link-preview-lede'
  end

  def test_extract_lede_returns_nil_when_no_doc
    result = Renderer.extract_lede(@site, '/nonexistent/')
    assert_nil result
  end

  def test_extract_lede_returns_nil_when_building_lede_flag_set
    excerpt = Struct.new(:output).new('<p>Some text.</p>')
    doc = create_doc({ 'excerpt' => excerpt }, '/books/test/')
    @site.data['url_to_book_doc'] = { '/books/test/' => doc }
    @site.data['_building_lede'] = true

    result = Renderer.extract_lede(@site, '/books/test/')
    assert_nil result
  ensure
    @site.data.delete('_building_lede')
  end

  def test_extract_lede_strips_fragment_from_url
    html = '<p>Read <a href="/books/foo/"><cite>Foo</cite></a><!--book-preview--><span>preview</span><!--/book-preview--> next.</p>'
    excerpt = Struct.new(:output).new(html)
    doc = create_doc({ 'excerpt' => excerpt }, '/books/test/')
    @site.data['url_to_book_doc'] = { '/books/test/' => doc }

    assert_equal 'Read <cite>Foo</cite> next.', Renderer.extract_lede(@site, '/books/test/#some-anchor')
    refute Renderer.building_lede?(@site)
  end

  def test_extract_lede_without_excerpt
    doc = create_doc({}, '/books/test/')
    @site.data['url_to_book_doc'] = { '/books/test/' => doc }

    [nil, '', '   ', '<p></p>'].each do |blank|
      doc.data['excerpt'] = Struct.new(:output).new(blank)
      assert_nil Renderer.extract_lede(@site, '/books/test/')
    end
    doc.data.delete('excerpt')
    assert_nil Renderer.extract_lede(@site, '/books/test/')
  end

  def test_extract_lede_clears_flag_on_exception
    bad_excerpt = Object.new
    def bad_excerpt.output = raise('boom')
    def bad_excerpt.respond_to?(method, *) = method == :output || super
    doc = create_doc({}, '/books/test/')
    doc.data['excerpt'] = bad_excerpt
    @site.data['url_to_book_doc'] = { '/books/test/' => doc }

    assert_raises(RuntimeError) { Renderer.extract_lede(@site, '/books/test/') }
    refute @site.data['_building_lede'], 'Flag should be cleared even on exception'
  end

  def test_building_lede_returns_false_when_not_set
    refute Renderer.building_lede?(@site)
  end

  def test_building_lede_returns_true_when_set
    @site.data['_building_lede'] = true
    assert Renderer.building_lede?(@site)
  ensure
    @site.data.delete('_building_lede')
  end
end
