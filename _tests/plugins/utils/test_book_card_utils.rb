# _tests/plugins/utils/test_book_card_utils.rb
require_relative '../../test_helper'
# BookCardUtils, FrontMatterUtils, TextProcessingUtils, etc., are loaded by test_helper

class TestBookCardUtils < Minitest::Test
  def setup
    @site = create_site({'url' => 'http://example.com'})
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current_card_test.md'}, '/current.html') })
    @site.config['plugin_logging'] ||= {} # Ensure logging config exists

    # Default book data for single author scenario
    @book_data_single_author = {
      'title' => 'My Book Title',
      'image' => '/images/book.jpg',
      'book_authors' => ['Test Author'], # CHANGED to book_authors array
      'rating' => 4,
      'excerpt' => Struct.new(:output).new("<p>Book excerpt.</p>")
    }
    @book_object_single_author = create_doc(@book_data_single_author, '/book_single.html')

    # Book data for multiple authors scenario
    @book_data_multi_author = {
      'title' => 'Collaborative Work',
      'image' => '/images/collab.jpg',
      'book_authors' => ['Author One', 'Author Two'],
      'rating' => 5,
      'excerpt' => Struct.new(:output).new("<p>A joint effort.</p>")
    }
    @book_object_multi_author = create_doc(@book_data_multi_author, '/book_multi.html')

    # Book data for no authors scenario
    @book_data_no_authors = {
      'title' => 'Anonymous Tales',
      'image' => '/images/anon.jpg',
      'book_authors' => [], # Empty list
      'rating' => 3,
      'excerpt' => Struct.new(:output).new("<p>Stories from nowhere.</p>")
    }
    @book_object_no_authors = create_doc(@book_data_no_authors, '/book_no_authors.html')

    # Book data for four authors scenario
    @book_data_four_authors = {
      'title' => 'Four Author Book',
      'image' => '/images/four.jpg',
      'book_authors' => ['First Author', 'Second Author', 'Third Author', 'Fourth Author'],
      'rating' => 4,
      'excerpt' => Struct.new(:output).new("<p>Many authors.</p>")
    }
    @book_object_four_authors = create_doc(@book_data_four_authors, '/book_four.html')


    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end; def logger.debug(topic, message); end
    end
  end

  def test_uses_display_title_override_when_provided
    book = @book_object_single_author
    override_title = "This is a Custom Title"

    # 1. Test with the override
    output_with_override = ""
    Jekyll.stub :logger, @silent_logger_stub do
      output_with_override = BookCardUtils.render(book, @context, display_title_override: override_title)
    end

    assert_match "<strong><cite class=\"book-title\">#{override_title}</cite></strong>", output_with_override
    refute_match "My Book Title", output_with_override

    # 2. Test without the override (should use default title)
    output_without_override = ""
    Jekyll.stub :logger, @silent_logger_stub do
      output_without_override = BookCardUtils.render(book, @context)
    end

    assert_match "<strong><cite class=\"book-title\">My Book Title</cite></strong>", output_without_override
    refute_match "This is a Custom Title", output_without_override

    # 3. Test with a blank override (should use default title)
    output_with_blank_override = ""
    Jekyll.stub :logger, @silent_logger_stub do
      output_with_blank_override = BookCardUtils.render(book, @context, display_title_override: "   ")
    end
    assert_match "<strong><cite class=\"book-title\">My Book Title</cite></strong>", output_with_blank_override
  end

  def test_render_book_card_single_author_success
    book_to_test = @book_object_single_author

    mock_base_data = {
      site: @site, data_source_for_keys: book_to_test.data, data_for_description: book_to_test.data,
      absolute_url: "http://example.com/book_single.html",
      absolute_image_url: "http://example.com/images/book.jpg",
      raw_title: "My Book Title", log_output: ""
    }
    mock_prepared_title = "My Prepared Book Title"
    mock_description_html = "<p>Book excerpt.</p>"
    mock_author_link_html_single = "<a href=\"/authors/test-author\"><span class=\"author-name\">Test Author</span></a>"
    mock_rating_stars_html = "<div class=\"book-rating star-rating-4\">****</div>"

    # TextProcessingUtils.format_list_as_sentence will be called with [mock_author_link_html_single]
    # and should return mock_author_link_html_single itself.
    expected_formatted_authors = mock_author_link_html_single
    expected_author_element_html = "    <span class=\"by-author\"> by #{expected_formatted_authors}</span>\n"
    expected_rating_element_html = "    #{mock_rating_stars_html}\n"

    expected_card_data = {
      base_class: "book-card", url: mock_base_data[:absolute_url],
      image_url: mock_base_data[:absolute_image_url], image_alt: "Book cover of My Book Title.",
      image_div_class: "card-book-cover", title_html: "<strong><cite class=\"book-title\">#{mock_prepared_title}</cite></strong>",
      extra_elements_html: [expected_author_element_html, expected_rating_element_html],
      description_html: mock_description_html,
      description_wrapper_html_open: "    <div class=\"card-element card-text\">\n      ",
      description_wrapper_html_close: "\n    </div>\n"
    }
    captured_card_data = nil

    CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      TypographyUtils.stub :prepare_display_title, mock_prepared_title do
        CardDataExtractorUtils.stub :extract_description_html, mock_description_html do
          # AuthorLinkUtils will be called once for 'Test Author'
          AuthorLinkUtils.stub :render_author_link, mock_author_link_html_single do
            # TextProcessingUtils.format_list_as_sentence will be called with the result
            # For single author, it returns the single item.
            TextProcessingUtils.stub :format_list_as_sentence, ->(list, etal_after: nil) { list.first } do
              RatingUtils.stub :render_rating_stars, mock_rating_stars_html do
                CardRendererUtils.stub :render_card, ->(context:, card_data:) { captured_card_data = card_data; "mocked_card" } do
                  Jekyll.stub :logger, @silent_logger_stub do
                    BookCardUtils.render(book_to_test, @context)
                  end
                end
              end
            end
          end
        end
      end
    end
    refute_nil captured_card_data
    assert_equal expected_card_data, captured_card_data
  end

  def test_render_book_card_multiple_authors
    book_to_test = @book_object_multi_author # Authors: ['Author One', 'Author Two']

    mock_base_data = {
      site: @site, data_source_for_keys: book_to_test.data, data_for_description: book_to_test.data,
      absolute_url: "http://example.com/book_multi.html",
      absolute_image_url: "http://example.com/images/collab.jpg",
      raw_title: "Collaborative Work", log_output: ""
    }
    mock_prepared_title = "Collaborative Work Prepared"
    mock_description_html = "<p>A joint effort.</p>"
    mock_author1_link_html = "<a href=\"...\">Author One</a>"
    mock_author2_link_html = "<a href=\"...\">Author Two</a>"
    # Expected output from TextProcessingUtils.format_list_as_sentence(["link1", "link2"])
    expected_formatted_authors = "#{mock_author1_link_html} and #{mock_author2_link_html}"
    mock_rating_stars_html = "<div class=\"book-rating star-rating-5\">*****</div>"

    expected_author_element_html = "    <span class=\"by-author\"> by #{expected_formatted_authors}</span>\n"
    expected_rating_element_html = "    #{mock_rating_stars_html}\n"

    expected_card_data = {
      base_class: "book-card", url: mock_base_data[:absolute_url],
      image_url: mock_base_data[:absolute_image_url], image_alt: "Book cover of Collaborative Work.",
      image_div_class: "card-book-cover", title_html: "<strong><cite class=\"book-title\">#{mock_prepared_title}</cite></strong>",
      extra_elements_html: [expected_author_element_html, expected_rating_element_html],
      description_html: mock_description_html,
      description_wrapper_html_open: "    <div class=\"card-element card-text\">\n      ",
      description_wrapper_html_close: "\n    </div>\n"
    }
    captured_card_data = nil
    author_link_calls = 0

    CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      TypographyUtils.stub :prepare_display_title, mock_prepared_title do
        CardDataExtractorUtils.stub :extract_description_html, mock_description_html do
          # Stub AuthorLinkUtils to return different links based on input name
          AuthorLinkUtils.stub :render_author_link, ->(name, _ctx) {
            author_link_calls += 1
            name == 'Author One' ? mock_author1_link_html : mock_author2_link_html
          } do
            # Let TextProcessingUtils.format_list_as_sentence run its actual logic for 2 authors
            # TextProcessingUtils.stub :format_list_as_sentence, expected_formatted_authors do
            RatingUtils.stub :render_rating_stars, mock_rating_stars_html do
              CardRendererUtils.stub :render_card, ->(context:, card_data:) { captured_card_data = card_data; "mocked_multi_author_card" } do
                Jekyll.stub :logger, @silent_logger_stub do
                  BookCardUtils.render(book_to_test, @context)
                end
              end
            end
          end
        end
      end
    end
    assert_equal 2, author_link_calls, "AuthorLinkUtils.render_author_link should be called twice"
    refute_nil captured_card_data
    assert_equal expected_card_data, captured_card_data
  end

  def test_render_book_card_four_plus_authors_uses_etal
    book_to_test = @book_object_four_authors # Authors: ['First Author', 'Second Author', 'Third Author', 'Fourth Author']

    mock_base_data = {
      site: @site, data_source_for_keys: book_to_test.data, data_for_description: book_to_test.data,
      absolute_url: "http://example.com/book_four.html",
      absolute_image_url: "http://example.com/images/four.jpg",
      raw_title: "Four Author Book", log_output: ""
    }
    mock_prepared_title = "Four Author Book Prepared"
    mock_description_html = "<p>Many authors.</p>"
    mock_first_author_link_html = "<a href=\"...\">First Author</a>"
    # For "et al.", only the first author's link is used by TextProcessingUtils.format_list_as_sentence
    expected_formatted_authors_with_etal = "#{mock_first_author_link_html} <abbr class=\"etal\">et al.</abbr>"
    mock_rating_stars_html = "<div class=\"book-rating star-rating-4\">****</div>"

    expected_author_element_html = "    <span class=\"by-author\"> by #{expected_formatted_authors_with_etal}</span>\n"
    expected_rating_element_html = "    #{mock_rating_stars_html}\n"

    expected_card_data = {
      base_class: "book-card", url: mock_base_data[:absolute_url],
      image_url: mock_base_data[:absolute_image_url], image_alt: "Book cover of Four Author Book.",
      image_div_class: "card-book-cover", title_html: "<strong><cite class=\"book-title\">#{mock_prepared_title}</cite></strong>",
      extra_elements_html: [expected_author_element_html, expected_rating_element_html],
      description_html: mock_description_html,
      description_wrapper_html_open: "    <div class=\"card-element card-text\">\n      ",
      description_wrapper_html_close: "\n    </div>\n"
    }
    captured_card_data = nil
    author_link_calls = 0 # To count how many times AuthorLinkUtils.render_author_link is called

    CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      TypographyUtils.stub :prepare_display_title, mock_prepared_title do
        CardDataExtractorUtils.stub :extract_description_html, mock_description_html do
          # Stub AuthorLinkUtils.render_author_link. It will be called for each of the 4 authors.
          AuthorLinkUtils.stub :render_author_link, ->(name, _ctx) {
            author_link_calls += 1
            # Return a simple link; TextProcessingUtils will only use the first one for "et al."
            "<a href=\"...\">#{name}</a>"
          } do
            # Let TextProcessingUtils.format_list_as_sentence run its actual logic
            RatingUtils.stub :render_rating_stars, mock_rating_stars_html do
              CardRendererUtils.stub :render_card, ->(context:, card_data:) { captured_card_data = card_data; "mocked_four_author_card" } do
                Jekyll.stub :logger, @silent_logger_stub do
                  BookCardUtils.render(book_to_test, @context)
                end
              end
            end
          end
        end
      end
    end

    assert_equal 4, author_link_calls, "AuthorLinkUtils.render_author_link should be called for all four authors"
    refute_nil captured_card_data
    # The key assertion is that `expected_author_element_html` (which contains the "et al." formatting)
    # is correctly assembled and passed to CardRendererUtils.
    assert_equal expected_card_data, captured_card_data
  end


  def test_render_book_card_no_authors_logs_warning
    @site.config['plugin_logging']['BOOK_CARD_MISSING_AUTHORS'] = true
    book_to_test = @book_object_no_authors # book_authors: []

    mock_base_data = {
      site: @site, data_source_for_keys: book_to_test.data, data_for_description: book_to_test.data,
      absolute_url: "http://example.com/book_no_authors.html",
      absolute_image_url: "http://example.com/images/anon.jpg",
      raw_title: "Anonymous Tales", log_output: "" # Start with empty log
    }
    mock_prepared_title = "Anonymous Tales Prepared"
    mock_description_html = "<p>Stories from nowhere.</p>"
    mock_rating_stars_html = "<div class=\"book-rating star-rating-3\">***</div>"

    # Expect no author element, only rating
    expected_rating_element_html = "    #{mock_rating_stars_html}\n"
    expected_card_data = {
      base_class: "book-card", url: mock_base_data[:absolute_url],
      image_url: mock_base_data[:absolute_image_url], image_alt: "Book cover of Anonymous Tales.",
      image_div_class: "card-book-cover", title_html: "<strong><cite class=\"book-title\">#{mock_prepared_title}</cite></strong>",
      extra_elements_html: [expected_rating_element_html], # Only rating
      description_html: mock_description_html,
      description_wrapper_html_open: "    <div class=\"card-element card-text\">\n      ",
      description_wrapper_html_close: "\n    </div>\n"
    }
    captured_card_data = nil
    final_output = ""

    CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      TypographyUtils.stub :prepare_display_title, mock_prepared_title do
        CardDataExtractorUtils.stub :extract_description_html, mock_description_html do
          # AuthorLinkUtils should not be called
          AuthorLinkUtils.stub :render_author_link, ->(name, _ctx) { flunk "AuthorLinkUtils should not be called for no authors" } do
            TextProcessingUtils.stub :format_list_as_sentence, ->(list, etal_after: nil) { flunk "format_list_as_sentence should not be called if author list is empty" } do
              RatingUtils.stub :render_rating_stars, mock_rating_stars_html do
                CardRendererUtils.stub :render_card, ->(context:, card_data:) { captured_card_data = card_data; "card_html_no_author" } do
                  Jekyll.stub :logger, @silent_logger_stub do # Keep logger silent for this part
                    final_output = BookCardUtils.render(book_to_test, @context)
                  end
                end
              end
            end
          end
        end
      end
    end
    refute_nil captured_card_data
    assert_equal expected_card_data, captured_card_data
    # Check that the log message for missing authors is part of the final output
    assert_match %r{<!-- \[WARN\] BOOK_CARD_MISSING_AUTHORS_FAILURE: Reason='&#39;book_authors&#39; field resolved to an empty list\.'\s*book_title='Anonymous Tales'\s*SourcePage='current_card_test\.md' -->}, final_output
  end

  # Minimal data test remains largely the same, but ensure 'book_authors' is absent or empty
  def test_render_book_card_minimal_data
    book_minimal_data = { 'title' => 'Minimal Book', 'book_authors' => [] } # No author, rating, image, excerpt
    book_minimal = create_doc(book_minimal_data, '/minimal.html')

    mock_base_data = {
      site: @site, data_source_for_keys: book_minimal.data, data_for_description: book_minimal.data,
      absolute_url: "http://example.com/minimal.html", absolute_image_url: nil,
      raw_title: "Minimal Book", log_output: "<!-- BOOK_CARD_MISSING_AUTHORS_FAILURE -->" # Simulate log from authors check
    }
    mock_prepared_title = "Minimal Book Prepared"
    mock_description_html = ""

    captured_card_data = nil
    final_output = ""

    CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      TypographyUtils.stub :prepare_display_title, mock_prepared_title do
        CardDataExtractorUtils.stub :extract_description_html, mock_description_html do
          CardRendererUtils.stub :render_card, ->(context:, card_data:) { captured_card_data = card_data; "minimal_card_html" } do
            Jekyll.stub :logger, @silent_logger_stub do
              final_output = BookCardUtils.render(book_minimal, @context)
            end
          end
        end
      end
    end
    refute_nil captured_card_data
    assert_nil captured_card_data[:image_url]
    assert_equal "Book cover of Minimal Book.", captured_card_data[:image_alt]
    assert_empty captured_card_data[:extra_elements_html] # No authors, no rating
    assert_equal "", captured_card_data[:description_html]
    # Check that the log from base_data (simulating missing authors log) is prepended
    assert_equal "<!-- BOOK_CARD_MISSING_AUTHORS_FAILURE -->minimal_card_html", final_output
  end

  # Tests for CardDataExtractorUtils failures remain the same
  def test_render_returns_log_if_base_data_extraction_fails
    mock_failure_log = "<!-- BOOK_BASE_DATA_EXTRACTION_FAILURE -->"
    CardDataExtractorUtils.stub :extract_base_data, {
      log_output: mock_failure_log, site: nil, data_source_for_keys: nil, data_for_description: nil
    } do
      Jekyll.stub :logger, @silent_logger_stub do
        output = BookCardUtils.render(@book_object_single_author, @context)
        assert_equal mock_failure_log, output
      end
    end
  end

  def test_render_returns_log_if_base_data_has_no_item_data_source
    mock_base_data_no_item_data = {
      site: @site, data_source_for_keys: nil, data_for_description: nil,
      absolute_url: "/some-url/", absolute_image_url: nil, raw_title: "Some Title",
      log_output: "<!-- BOOK_ITEM_INVALID_LOG -->"
    }
    CardDataExtractorUtils.stub :extract_base_data, mock_base_data_no_item_data do
      Jekyll.stub :logger, @silent_logger_stub do
        output = BookCardUtils.render(@book_object_single_author, @context)
        assert_equal "<!-- BOOK_ITEM_INVALID_LOG -->", output
      end
    end
  end
end
