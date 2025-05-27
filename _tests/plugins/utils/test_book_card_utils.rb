# _tests/plugins/utils/test_book_card_utils.rb
require_relative '../../test_helper'

class TestBookCardUtils < Minitest::Test
  def setup
    @site = create_site({'url' => 'http://example.com'})
    @current_page_for_context = create_doc({ 'path' => 'current_card_test_page.md'}, '/current.html')
    @context = create_context({}, { site: @site, page: @current_page_for_context })

    @book_data_full_template = {
      'title' => 'My Book Title',
      'image' => '/images/book.jpg',
      'image_alt' => 'User Alt Text.',
      'book_author' => 'Test Author',
      'series' => 'Awesome Series',
      'book_number' => '1',
      'rating' => 4,
      'excerpt_output_override' => "<p>Book excerpt.</p>"
    }
    @book_object_full = create_doc(@book_data_full_template, '/books/full-book.html')

    @mock_base_data_from_extractor_template = {
      site: @site,
      data_source_for_keys: @book_object_full.data,
      data_for_description: @book_object_full.data,
      absolute_url: "http://example.com/books/full-book.html",
      absolute_image_url: "http://example.com/images/book.jpg",
      raw_title: @book_object_full.data['title'],
      log_output: ""
    }
    @mock_author_link_html = "<a href='/authors/test-author'><span class='author-name'>Test Author</span></a>"
    @mock_rating_stars_html = "<div class='rating'>4 Stars</div>"

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
    end
  end

  def render_book_card_with_stubs(book_obj,
                                  context = @context,
                                  series_text_analysis_stub_val: { prefix: "the ", name: book_obj.data['series'], suffix: " series" },
                                  series_link_stub_val: "<a href='/series/link'><span class='series-name'>#{book_obj.data['series']}</span></a>",
                                  author_link_stub_val: @mock_author_link_html,
                                  rating_stars_stub_val: @mock_rating_stars_html
                                 )

    captured_card_data_to_renderer = nil
    current_base_data_stub = @mock_base_data_from_extractor_template.dup
    current_base_data_stub[:data_source_for_keys] = book_obj.data
    current_base_data_stub[:data_for_description] = book_obj.data
    current_base_data_stub[:raw_title] = book_obj.data['title'] || BookCardUtils::DEFAULT_TITLE_FOR_BOOK_CARD
    current_base_data_stub[:absolute_url] = UrlUtils.absolute_url(book_obj.url, @site) if book_obj.url
    current_base_data_stub[:absolute_image_url] = book_obj.data['image'] ? UrlUtils.absolute_url(book_obj.data['image'], @site) : nil
    description_html_stub = book_obj.data['excerpt_output_override'] || "<p>Default excerpt.</p>"

    # Define the lambda for stubbing CardRendererUtils.render_card
    # It must match the original method's keyword arguments: context:, card_data:
    card_renderer_stub = lambda do |context:, card_data:| # Use 'context:' not 'ctx:'
      captured_card_data_to_renderer = card_data
      "<!-- RENDERED_CARD -->" # Return value for the stub
    end

    CardDataExtractorUtils.stub :extract_base_data, current_base_data_stub do
      TypographyUtils.stub :prepare_display_title, ->(title_str) { title_str } do
        CardDataExtractorUtils.stub :extract_description_html, description_html_stub do
          AuthorLinkUtils.stub :render_author_link, author_link_stub_val do
            SeriesTextUtils.stub :analyze_series_name, series_text_analysis_stub_val do
              SeriesLinkUtils.stub :render_series_link, series_link_stub_val do
                RatingUtils.stub :render_rating_stars, rating_stars_stub_val do
                  CardRendererUtils.stub :render_card, card_renderer_stub do # Pass the defined lambda
                    Jekyll.stub :logger, @silent_logger_stub do
                      BookCardUtils.render(book_obj, context)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    captured_card_data_to_renderer
  end

  # --- Test Cases ---
  # (All test cases remain the same as the previous correct version)

  def test_render_book_card_success_with_all_elements_including_series
    book_data = @book_data_full_template.dup
    book_obj = create_doc(book_data, '/books/series-book1.html')
    series_name = book_obj.data['series']
    book_number = book_obj.data['book_number']

    series_text_analysis = { prefix: "the ", name: series_name, suffix: " series" }
    series_link_html = "<a href='/slink'><span class='sname'>#{series_name}</span></a>"

    card_data = render_book_card_with_stubs(
      book_obj,
      series_text_analysis_stub_val: series_text_analysis,
      series_link_stub_val: series_link_html
    )

    refute_nil card_data
    expected_series_line = "    <div class=\"book-series-line\">Book #{book_number} of the #{series_link_html} series</div>\n"
    assert_includes card_data[:extra_elements_html], expected_series_line
  end

  def test_series_line_with_fractional_book_number
    book_data = @book_data_full_template.merge({ 'book_number' => '2.5' })
    book_obj = create_doc(book_data, '/books/frac-num.html')
    series_name = book_obj.data['series']

    series_text_analysis = { prefix: "the ", name: series_name, suffix: " series" }
    series_link_html = "<a href='/slink'><span class='sname'>#{series_name}</span></a>"

    card_data = render_book_card_with_stubs(
      book_obj,
      series_text_analysis_stub_val: series_text_analysis,
      series_link_stub_val: series_link_html
    )
    expected_series_line = "    <div class=\"book-series-line\">Book 2.5 of the #{series_link_html} series</div>\n"
    assert_includes card_data[:extra_elements_html], expected_series_line
  end

  def test_series_line_with_book_number_ending_in_zero_retains_original_string
    book_data = @book_data_full_template.merge({ 'book_number' => '3.0' })
    book_obj = create_doc(book_data, '/books/3point0.html')
    series_name = book_obj.data['series']

    series_text_analysis = { prefix: "the ", name: series_name, suffix: " series" }
    series_link_html = "<a href='/slink'><span class='sname'>#{series_name}</span></a>"

    card_data = render_book_card_with_stubs(
      book_obj,
      series_text_analysis_stub_val: series_text_analysis,
      series_link_stub_val: series_link_html
    )
    expected_series_line = "    <div class=\"book-series-line\">Book 3.0 of the #{series_link_html} series</div>\n"
    assert_includes card_data[:extra_elements_html], expected_series_line
  end


  def test_series_line_part_of_if_no_book_number
    book_data = @book_data_full_template.merge({ 'book_number' => nil })
    book_obj = create_doc(book_data, '/books/series-no-num.html')
    series_name = book_obj.data['series']

    series_text_analysis = { prefix: "the ", name: series_name, suffix: " series" }
    series_link_html = "<a href='/slink'><span class='sname'>#{series_name}</span></a>"

    card_data = render_book_card_with_stubs(
      book_obj,
      series_text_analysis_stub_val: series_text_analysis,
      series_link_stub_val: series_link_html
    )
    expected_series_line = "    <div class=\"book-series-line\">Part of the #{series_link_html} series</div>\n"
    assert_includes card_data[:extra_elements_html], expected_series_line
  end

  def test_series_line_part_of_if_invalid_text_book_number
    book_data = @book_data_full_template.merge({ 'book_number' => 'Volume 1' })
    book_obj = create_doc(book_data, '/books/series-invalid-num.html')
    series_name = book_obj.data['series']

    series_text_analysis = { prefix: "the ", name: series_name, suffix: " series" }
    series_link_html = "<a href='/slink'><span class='sname'>#{series_name}</span></a>"

    card_data = render_book_card_with_stubs(
      book_obj,
      series_text_analysis_stub_val: series_text_analysis,
      series_link_stub_val: series_link_html
    )
    expected_series_line = "    <div class=\"book-series-line\">Part of the #{series_link_html} series</div>\n"
    assert_includes card_data[:extra_elements_html], expected_series_line
  end

  def test_series_line_part_of_if_zero_book_number
    book_data = @book_data_full_template.merge({ 'book_number' => '0' })
    book_obj = create_doc(book_data, '/books/series-zero-num.html')
    series_name = book_obj.data['series']

    series_text_analysis = { prefix: "the ", name: series_name, suffix: " series" }
    series_link_html = "<a href='/slink'><span class='sname'>#{series_name}</span></a>"

    card_data = render_book_card_with_stubs(
      book_obj,
      series_text_analysis_stub_val: series_text_analysis,
      series_link_stub_val: series_link_html
    )
    expected_series_line = "    <div class=\"book-series-line\">Part of the #{series_link_html} series</div>\n"
    assert_includes card_data[:extra_elements_html], expected_series_line
  end

  def test_series_line_part_of_if_negative_book_number
    book_data = @book_data_full_template.merge({ 'book_number' => '-1' })
    book_obj = create_doc(book_data, '/books/series-neg-num.html')
    series_name = book_obj.data['series']

    series_text_analysis = { prefix: "the ", name: series_name, suffix: " series" }
    series_link_html = "<a href='/slink'><span class='sname'>#{series_name}</span></a>"

    card_data = render_book_card_with_stubs(
      book_obj,
      series_text_analysis_stub_val: series_text_analysis,
      series_link_stub_val: series_link_html
    )
    expected_series_line = "    <div class=\"book-series-line\">Part of the #{series_link_html} series</div>\n"
    assert_includes card_data[:extra_elements_html], expected_series_line
  end

  def test_no_series_line_if_book_has_no_series
    book_data = @book_data_full_template.merge({ 'series' => nil, 'book_number' => nil })
    book_obj = create_doc(book_data, '/books/no-series.html')

    card_data = render_book_card_with_stubs(book_obj, series_text_analysis_stub_val: nil)
    has_series_line = card_data[:extra_elements_html].any? { |el| el.include?("book-series-line") }
    refute has_series_line
  end

  def test_series_line_uses_grammatical_analysis_from_series_text_utils
    book_the_series_data = @book_data_full_template.merge({ 'series' => 'The Expanse', 'book_number' => '2' })
    book_the_series = create_doc(book_the_series_data, '/books/the-expanse-book.html')
    series_name_expanse = book_the_series.data['series']

    series_text_analysis_for_the_expanse = { prefix: "", name: series_name_expanse, suffix: " series" }
    series_link_for_the_expanse = "<a href='/slink'><span class='sname'>#{series_name_expanse}</span></a>"

    card_data = render_book_card_with_stubs(
      book_the_series,
      series_text_analysis_stub_val: series_text_analysis_for_the_expanse,
      series_link_stub_val: series_link_for_the_expanse
    )
    expected_series_line = "    <div class=\"book-series-line\">Book 2 of #{series_link_for_the_expanse} series</div>\n"
    assert_includes card_data[:extra_elements_html], expected_series_line

    book_saga_series_data = @book_data_full_template.merge({ 'series' => 'Dune Saga', 'book_number' => '1' })
    book_saga_series = create_doc(book_saga_series_data, '/books/dune-saga-book.html')
    series_name_saga = book_saga_series.data['series']

    series_text_analysis_for_dune_saga = { prefix: "the ", name: series_name_saga, suffix: "" }
    series_link_for_dune_saga = "<a href='/slink'><span class='sname'>#{series_name_saga}</span></a>"

    card_data_saga = render_book_card_with_stubs(
      book_saga_series,
      series_text_analysis_stub_val: series_text_analysis_for_dune_saga,
      series_link_stub_val: series_link_for_dune_saga
    )
    expected_series_line_saga = "    <div class=\"book-series-line\">Book 1 of the #{series_link_for_dune_saga}</div>\n"
    assert_includes card_data_saga[:extra_elements_html], expected_series_line_saga
  end

  def test_series_line_not_added_if_series_analysis_returns_nil
    book_data = @book_data_full_template.merge({'series' => 'Problematic Series'})
    book_obj = create_doc(book_data, '/books/problem-series.html')

    card_data = render_book_card_with_stubs(book_obj, series_text_analysis_stub_val: nil)
    has_series_line = card_data[:extra_elements_html].any? { |el| el.include?("book-series-line") }
    refute has_series_line
  end

  def test_series_line_not_added_if_linked_series_html_is_empty
    book_data = @book_data_full_template.merge({'series' => 'Unlinked Series'})
    book_obj = create_doc(book_data, '/books/unlinked-series.html')
    series_name = book_obj.data['series']
    series_text_analysis = { prefix: "the ", name: series_name, suffix: " series" }

    card_data = render_book_card_with_stubs(
      book_obj,
      series_text_analysis_stub_val: series_text_analysis,
      series_link_stub_val: "  "
    )
    has_series_line = card_data[:extra_elements_html].any? { |el| el.include?("book-series-line") }
    refute has_series_line
  end

  def test_render_book_card_minimal_data_no_extras
    book_minimal_data = { 'title' => 'Minimal Book', 'image' => 'img.jpg', 'excerpt_output_override' => 'desc' }
    book_minimal = create_doc(book_minimal_data, '/minimal.html')

    card_data = render_book_card_with_stubs(
      book_minimal,
      author_link_stub_val: "",
      series_text_analysis_stub_val: nil,
      series_link_stub_val: "",
      rating_stars_stub_val: ""
    )
    refute_nil card_data
    assert_equal "<strong><cite class=\"book-title\">Minimal Book</cite></strong>", card_data[:title_html]
    assert_empty card_data[:extra_elements_html]
  end

  def test_render_returns_log_if_base_data_extraction_fails
    mock_failure_log = "<!-- BOOK_BASE_DATA_EXTRACTION_FAILURE -->"
    CardDataExtractorUtils.stub :extract_base_data, {
      log_output: mock_failure_log,
      site: nil, data_source_for_keys: nil, data_for_description: nil
    } do
      Jekyll.stub :logger, @silent_logger_stub do
        output = BookCardUtils.render(@book_object_full, @context)
        assert_equal mock_failure_log, output
      end
    end
  end
end
