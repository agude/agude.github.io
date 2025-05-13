# _tests/plugins/utils/test_book_card_utils.rb
require_relative '../../test_helper'
# BookCardUtils is loaded by test_helper

class TestBookCardUtils < Minitest::Test
  def setup
    @site = create_site({'url' => 'http://example.com'}) # Ensure site URL for UrlUtils
    @context = create_context({}, { site: @site, page: create_doc({}, '/current.html') })

    # Data for a typical book object
    @book_data_hash = {
      'title' => 'My Book Title',
      'image' => '/images/book.jpg',
      'book_author' => 'Test Author',
      'rating' => 4,
      'excerpt' => Struct.new(:output).new("<p>Book excerpt.</p>")
    }
    @book_object = create_doc(@book_data_hash, '/book.html')

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
      def logger.log_level=(level); end;    def logger.progname=(name); end
    end
  end

  def test_render_book_card_success
    # This is what CardDataExtractorUtils.extract_base_data is stubbed to return
    mock_base_data_from_extractor = {
      site: @site,
      data_source_for_keys: @book_object.data, # For Jekyll::Document, this is .data
      data_for_description: @book_object.data, # For Jekyll::Document, this is .data
      absolute_url: "http://example.com/book.html",
      absolute_image_url: "http://example.com/images/book.jpg",
      raw_title: "My Book Title", # From @book_object.data['title']
      log_output: ""
    }
    # This is what LiquidUtils._prepare_display_title is stubbed to return
    mock_prepared_title = "My Prepared Book Title"
    # This is what CardDataExtractorUtils.extract_description_html is stubbed to return
    mock_description_html_from_desc_extractor = "<p>Book excerpt.</p>"

    mock_author_link_content_html = "<a href=\"/authors/test-author\"><span class=\"author-name\">Test Author</span></a>"
    mock_rating_stars_content_html = "<div class=\"book-rating star-rating-4\">****</div>"

    expected_author_element_html = "    <span class=\"by-author\"> by #{mock_author_link_content_html}</span>\n"
    expected_rating_element_html = "    #{mock_rating_stars_content_html}\n"

    expected_card_data_to_renderer = {
      base_class: "book-card",
      url: mock_base_data_from_extractor[:absolute_url],
      image_url: mock_base_data_from_extractor[:absolute_image_url],
      image_alt: "Book cover of My Book Title.", # This comes from raw_title
      image_div_class: "card-book-cover",
      title_html: "<strong><cite class=\"book-title\">#{mock_prepared_title}</cite></strong>",
      extra_elements_html: [expected_author_element_html, expected_rating_element_html],
      description_html: mock_description_html_from_desc_extractor,
      description_wrapper_html_open: "    <div class=\"card-element card-text\">\n      ",
      description_wrapper_html_close: "\n    </div>\n"
    }

    captured_card_data = nil

    CardDataExtractorUtils.stub :extract_base_data, mock_base_data_from_extractor do
      LiquidUtils.stub :_prepare_display_title, mock_prepared_title do
        # Stub extract_description_html to return the pre-calculated description
        CardDataExtractorUtils.stub :extract_description_html, mock_description_html_from_desc_extractor do
          AuthorLinkUtils.stub :render_author_link, mock_author_link_content_html do
            RatingUtils.stub :render_rating_stars, mock_rating_stars_content_html do
              CardRendererUtils.stub :render_card, ->(context:, card_data:) { captured_card_data = card_data; "mocked_book_card_html" } do
                Jekyll.stub :logger, @silent_logger_stub do
                  output = BookCardUtils.render(@book_object, @context)
                  assert_equal "mocked_book_card_html", output
                end
              end
            end
          end
        end
      end
    end

    refute_nil captured_card_data, "CardRendererUtils.render_card should have been called"
    assert_equal expected_card_data_to_renderer, captured_card_data
  end

  def test_render_book_card_minimal_data
    book_minimal_data = { 'title' => 'Minimal Book' } # No author, rating, image, excerpt
    book_minimal = create_doc(book_minimal_data, '/minimal.html')

    mock_base_data = {
      site: @site,
      data_source_for_keys: book_minimal.data,
      data_for_description: book_minimal.data,
      absolute_url: "http://example.com/minimal.html",
      absolute_image_url: nil,
      raw_title: "Minimal Book",
      log_output: ""
    }
    mock_prepared_title = "Minimal Book Prepared"
    mock_description_html = "" # Extractor returns "" if no excerpt (or if excerpt.output is nil/empty)

    captured_card_data = nil
    args_to_desc_extractor = nil # To capture args

    CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      LiquidUtils.stub :_prepare_display_title, mock_prepared_title do
        # Stub extract_description_html to simulate its behavior and capture args
        CardDataExtractorUtils.stub :extract_description_html, ->(source, type:) {
          args_to_desc_extractor = { source: source, type: type }
          mock_description_html # Return the empty string
        } do
          # No need to stub AuthorLinkUtils or RatingUtils as they shouldn't be called
          CardRendererUtils.stub :render_card, ->(context:, card_data:) { captured_card_data = card_data; "minimal_card" } do
            Jekyll.stub :logger, @silent_logger_stub do
              BookCardUtils.render(book_minimal, @context)
            end
          end
        end
      end
    end
    refute_nil captured_card_data, "CardRendererUtils.render_card should have been called (minimal)"
    assert_nil captured_card_data[:image_url]
    assert_equal "Book cover of Minimal Book.", captured_card_data[:image_alt]
    assert_empty captured_card_data[:extra_elements_html]
    assert_equal "", captured_card_data[:description_html] # Expecting empty description

    refute_nil args_to_desc_extractor
    assert_equal book_minimal.data, args_to_desc_extractor[:source]
    assert_equal :book, args_to_desc_extractor[:type]
  end

  def test_render_returns_log_if_base_data_extraction_fails
    mock_failure_log = "<!-- BOOK_BASE_DATA_EXTRACTION_FAILURE -->"
    # Simulate CardDataExtractorUtils.extract_base_data returning a log and site:nil
    # Also ensure data_source_for_keys is nil to trigger the correct early return
    CardDataExtractorUtils.stub :extract_base_data, {
      log_output: mock_failure_log,
      site: nil,
      data_source_for_keys: nil,
      data_for_description: nil
    } do
      Jekyll.stub :logger, @silent_logger_stub do
        output = BookCardUtils.render(@book_object, @context)
        assert_equal mock_failure_log, output
      end
    end
  end

  def test_render_returns_log_if_base_data_has_no_item_data_source
    mock_base_data_no_item_data = {
      site: @site,
      data_source_for_keys: nil, # This is the key condition for early return
      data_for_description: nil,
      absolute_url: "/some-url/",
      absolute_image_url: nil,
      raw_title: "Some Title",
      log_output: "<!-- BOOK_ITEM_INVALID_LOG -->" # This log is from CardDataExtractorUtils
    }
    CardDataExtractorUtils.stub :extract_base_data, mock_base_data_no_item_data do
      Jekyll.stub :logger, @silent_logger_stub do
        output = BookCardUtils.render(@book_object, @context)
        assert_equal "<!-- BOOK_ITEM_INVALID_LOG -->", output
      end
    end
  end

end
