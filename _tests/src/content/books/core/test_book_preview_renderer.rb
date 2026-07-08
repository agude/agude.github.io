# frozen_string_literal: true

# _tests/src/content/books/core/test_book_preview_renderer.rb
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
            series: nil, book_number: nil, date_published: nil)
    Renderer.new(context, title, authors, rating, image, series: series, book_number: book_number, date_published: date_published)
  end

  def test_full_markup
    result = build.render
    expected = '<!--book-preview--><span class="book-link-preview" aria-hidden="true">' \
               '<span class="book-link-preview-cover" style="background-image: url(\'/images/dune.jpg\')"></span>' \
               '<span class="book-link-preview-text">' \
               '<cite class="book-title">Dune</cite>' \
               '<span class="book-link-preview-author">by Frank Herbert</span>' \
               '<span class="book-rating star-rating-5" role="img" aria-label="Rating: 5 out of 5 stars. ' \
               'Masterpiece — I loved it" title="Masterpiece — I loved it">' \
               '<span class="book_star full_star" aria-hidden="true">★</span>' \
               '<span class="book_star full_star" aria-hidden="true">★</span>' \
               '<span class="book_star full_star" aria-hidden="true">★</span>' \
               '<span class="book_star full_star" aria-hidden="true">★</span>' \
               '<span class="book_star full_star" aria-hidden="true">★</span>' \
               '</span>' \
               '</span></span><!--/book-preview-->'
    assert_equal expected, result
  end

  def test_output_contains_no_newlines
    refute_match(/\n/, build.render)
  end

  def test_starts_and_ends_with_comment_markers
    result = build.render
    assert result.start_with?('<!--book-preview-->')
    assert result.end_with?('<!--/book-preview-->')
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

  def test_three_authors_lists_all
    result = build(authors: ['A. One', 'B. Two', 'C. Three']).render
    assert_match(/by A\. One, B\. Two, and C\. Three/, result)
  end

  def test_escapes_title_html
    result = build(title: 'Cat & <Mouse>').render
    assert_includes result, '<cite class="book-title">Cat &amp; &lt;Mouse&gt;</cite>'
  end

  def test_escapes_author_html
    result = build(authors: ['A & <B>']).render
    assert_includes result, 'by A &amp; &lt;B&gt;'
  end

  def test_escapes_image_attribute
    result = build(image: "/images/dune's \"cover\".jpg").render
    assert_includes result, "url('/images/dune&#39;s &quot;cover&quot;.jpg')"
  end

  def test_log_output_defaults_to_empty_string
    assert_equal '', build.log_output
  end

  def test_series_with_number
    result = build(series: 'Dune', book_number: 1).render
    assert_includes result,
                    '<span class="book-link-preview-series"><span class="book-series">Dune</span>&thinsp;#1</span>'
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

  def test_date_published_as_date_object
    result = build(date_published: Date.new(2005, 7, 5)).render
    assert_includes result, '<span class="book-link-preview-published">Published 2005</span>'
  end

  def test_date_published_as_year_month_string
    result = build(date_published: '1959-10').render
    assert_includes result, '<span class="book-link-preview-published">Published 1959</span>'
  end

  def test_date_published_as_full_date_string
    result = build(date_published: '2021-03-02').render
    assert_includes result, '<span class="book-link-preview-published">Published 2021</span>'
  end

  def test_nil_date_published_omits_published_span
    result = build(date_published: nil).render
    refute_match(/book-link-preview-published/, result)
  end

  def test_garbage_date_published_omits_published_span
    result = build(date_published: 'not-a-date').render
    refute_match(/book-link-preview-published/, result)
  end

  def test_non_date_non_string_date_published_omits_published_span
    result = build(date_published: 12_345).render
    refute_match(/book-link-preview-published/, result)
  end

  def test_series_and_published_output_no_newlines
    result = build(series: 'Dune', book_number: 1, date_published: Date.new(1965, 8, 1)).render
    refute_match(/\n/, result)
  end

  def test_full_markup_with_series_and_published
    result = build(series: 'Dune', book_number: 1, date_published: Date.new(1965, 8, 1)).render
    assert result.end_with?(
      '<span class="book-link-preview-series"><span class="book-series">Dune</span>&thinsp;#1</span>' \
      '<span class="book-link-preview-published">Published 1965</span>' \
      '</span></span><!--/book-preview-->',
    )
  end
end
