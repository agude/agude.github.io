# frozen_string_literal: true

# _tests/plugins/utils/test_book_card_utils.rb
require_relative '../../../../test_helper'
# Jekyll::Books::Core::BookCardUtils, Jekyll::Infrastructure::FrontMatterUtils, Jekyll::Infrastructure::TextProcessingUtils, etc., are loaded by test_helper

# Tests for Jekyll::Books::Core::BookCardRenderer class.
#
# Verifies that the renderer correctly renders book cards with authors, ratings, and optional subtitles.
class TestBookCardRenderer < Minitest::Test
  def setup
    @site = create_site({ 'url' => 'http://example.com' })
    @context = create_context(
      {},
      {
        site: @site,
        page: create_doc({ 'path' => 'current_card_test.md' }, '/current.html'),
      },
    )
    @site.config['plugin_logging'] ||= {} # Ensure logging config exists

    setup_book_objects
    @silent_logger_stub = create_silent_logger_stub
  end

  def test_uses_display_title_override_when_provided
    book = @book_object_single_author
    override_title = 'This is a Custom Title'

    output_with_override = render_with_silent_logger(book, display_title_override: override_title)
    assert_match "<strong><cite class=\"book-title\">#{override_title}</cite></strong>", output_with_override
    assert_match "alt=\"Book cover of #{override_title}.\"", output_with_override
    refute_match 'My Book Title', output_with_override

    output_without_override = render_with_silent_logger(book)
    assert_match '<strong><cite class="book-title">My Book Title</cite></strong>', output_without_override
    refute_match 'This is a Custom Title', output_without_override

    output_with_blank_override = render_with_silent_logger(book, display_title_override: '   ')
    assert_match '<strong><cite class="book-title">My Book Title</cite></strong>', output_with_blank_override
  end

  def test_renders_subtitle_when_provided
    book = @book_object_single_author
    subtitle_text = 'A Special Subtitle'

    output_with_subtitle = render_with_silent_logger(book, subtitle: subtitle_text)
    assert_match "<div class=\"card-subtitle\"><i>#{subtitle_text}</i></div>", output_with_subtitle

    output_without_subtitle = render_with_silent_logger(book)
    refute_match '<div class="card-subtitle">', output_without_subtitle

    output_with_blank_subtitle = render_with_silent_logger(book, subtitle: '  ')
    refute_match '<div class="card-subtitle">', output_with_blank_subtitle
  end

  def test_render_book_card_single_author_success
    book_to_test = @book_object_single_author
    mock_base_data = create_base_data(book_to_test, '/book_single.html', '/images/book.jpg', 'My Book Title')
    mock_prepared_title = 'My Prepared Book Title'
    mock_description_html = '<p>Book excerpt.</p>'
    mock_author_link_html_single = '<a href="/authors/test-author"><span class="author-name">Test Author</span></a>'
    mock_rating_stars_html = '<div class="book-rating star-rating-4">****</div>'

    expected_formatted_authors = mock_author_link_html_single
    expected_card_data = build_expected_card_data(
      mock_base_data,
      mock_prepared_title,
      mock_description_html,
      [
        build_author_element(expected_formatted_authors),
        build_rating_element(mock_rating_stars_html),
      ],
    )
    captured_card_data = nil

    stub_rendering_dependencies(mock_base_data, mock_prepared_title, mock_description_html) do
      Jekyll::Authors::AuthorLinkUtils.stub :render_author_link, mock_author_link_html_single do
        Jekyll::Infrastructure::TextProcessingUtils.stub :format_list_as_sentence, ->(list, etal_after: nil) { list.first } do
          Jekyll::UI::Ratings::RatingUtils.stub :render_rating_stars, mock_rating_stars_html do
            captured_card_data = capture_card_data { Jekyll::Books::Core::BookCardRenderer.new(book_to_test, @context, nil, nil).render }
          end
        end
      end
    end

    refute_nil captured_card_data
    assert_equal expected_card_data, captured_card_data
  end

  def test_render_book_card_multiple_authors
    book_to_test = @book_object_multi_author
    mock_base_data = create_base_data(book_to_test, '/book_multi.html', '/images/collab.jpg', 'Collaborative Work')
    mock_prepared_title = 'Collaborative Work Prepared'
    mock_description_html = '<p>A joint effort.</p>'
    mock_author1_link_html = '<a href="...">Author One</a>'
    mock_author2_link_html = '<a href="...">Author Two</a>'
    expected_formatted_authors = "#{mock_author1_link_html} and #{mock_author2_link_html}"
    mock_rating_stars_html = '<div class="book-rating star-rating-5">*****</div>'

    expected_card_data = build_expected_card_data(
      mock_base_data,
      mock_prepared_title,
      mock_description_html,
      [
        build_author_element(expected_formatted_authors),
        build_rating_element(mock_rating_stars_html),
      ],
    )
    captured_card_data = nil
    author_link_calls = 0

    stub_rendering_dependencies(mock_base_data, mock_prepared_title, mock_description_html) do
      Jekyll::Authors::AuthorLinkUtils.stub :render_author_link,
                                            lambda { |name, _ctx|
                                              author_link_calls += 1
                                              name == 'Author One' ? mock_author1_link_html : mock_author2_link_html
                                            } do
        Jekyll::UI::Ratings::RatingUtils.stub :render_rating_stars, mock_rating_stars_html do
          captured_card_data = capture_card_data { Jekyll::Books::Core::BookCardUtils.render(book_to_test, @context) }
        end
      end
    end

    assert_equal 2, author_link_calls, 'Jekyll::Authors::AuthorLinkUtils.render_author_link should be called twice'
    refute_nil captured_card_data
    assert_equal expected_card_data, captured_card_data
  end

  def test_render_book_card_four_plus_authors_uses_etal
    book_to_test = @book_object_four_authors
    mock_base_data = create_base_data(book_to_test, '/book_four.html', '/images/four.jpg', 'Four Author Book')
    mock_prepared_title = 'Four Author Book Prepared'
    mock_description_html = '<p>Many authors.</p>'
    mock_first_author_link_html = '<a href="...">First Author</a>'
    expected_formatted_authors_with_etal =
      "#{mock_first_author_link_html} <abbr class=\"etal\">et al.</abbr>"
    mock_rating_stars_html = '<div class="book-rating star-rating-4">****</div>'

    expected_card_data = build_expected_card_data(
      mock_base_data,
      mock_prepared_title,
      mock_description_html,
      [
        build_author_element(expected_formatted_authors_with_etal),
        build_rating_element(mock_rating_stars_html),
      ],
    )
    captured_card_data = nil
    author_link_calls = 0

    stub_rendering_dependencies(mock_base_data, mock_prepared_title, mock_description_html) do
      Jekyll::Authors::AuthorLinkUtils.stub :render_author_link,
                                            lambda { |name, _ctx|
                                              author_link_calls += 1
                                              "<a href=\"...\">#{name}</a>"
                                            } do
        Jekyll::UI::Ratings::RatingUtils.stub :render_rating_stars, mock_rating_stars_html do
          captured_card_data = capture_card_data { Jekyll::Books::Core::BookCardUtils.render(book_to_test, @context) }
        end
      end
    end

    assert_equal 4,
                 author_link_calls,
                 'Jekyll::Authors::AuthorLinkUtils.render_author_link should be called for all four authors'
    refute_nil captured_card_data
    assert_equal expected_card_data, captured_card_data
  end

  def test_render_book_card_no_authors_logs_warning
    @site.config['plugin_logging']['BOOK_CARD_MISSING_AUTHORS'] = true
    book_to_test = @book_object_no_authors
    mock_base_data = create_base_data(book_to_test, '/book_no_authors.html', '/images/anon.jpg', 'Anonymous Tales')
    mock_prepared_title = 'Anonymous Tales Prepared'
    mock_description_html = '<p>Stories from nowhere.</p>'
    mock_rating_stars_html = '<div class="book-rating star-rating-3">***</div>'

    expected_card_data = build_expected_card_data(
      mock_base_data,
      mock_prepared_title,
      mock_description_html,
      [build_rating_element(mock_rating_stars_html)],
    )
    captured_card_data = nil
    final_output = ''

    stub_rendering_dependencies(mock_base_data, mock_prepared_title, mock_description_html) do
      Jekyll::Authors::AuthorLinkUtils.stub :render_author_link,
                                            lambda { |_name, _ctx|
                                              flunk 'Jekyll::Authors::AuthorLinkUtils should not be called for no authors'
                                            } do
        Jekyll::Infrastructure::TextProcessingUtils.stub :format_list_as_sentence,
                                                         lambda { |_list, etal_after: nil|
                                                           flunk 'format_list_as_sentence should not be called if author list is empty'
                                                         } do
          Jekyll::UI::Ratings::RatingUtils.stub :render_rating_stars, mock_rating_stars_html do
            captured_card_data, final_output = capture_card_data_and_output do
              Jekyll::Books::Core::BookCardRenderer.new(book_to_test, @context, nil, nil).render
            end
          end
        end
      end
    end

    refute_nil captured_card_data
    assert_equal expected_card_data, captured_card_data
    assert_match(
      /<!-- \[WARN\] BOOK_CARD_MISSING_AUTHORS_FAILURE: .* book_title='Anonymous Tales'/,
      final_output,
    )
  end

  def test_render_book_card_minimal_data
    book_minimal_data = { 'title' => 'Minimal Book', 'book_authors' => [] }
    book_minimal = create_doc(book_minimal_data, '/minimal.html')
    mock_base_data = create_base_data(
      book_minimal,
      '/minimal.html',
      nil,
      'Minimal Book',
      log: '<!-- BOOK_CARD_MISSING_AUTHORS_FAILURE -->',
    )
    mock_prepared_title = 'Minimal Book Prepared'
    mock_description_html = ''

    captured_card_data = nil
    final_output = ''

    stub_rendering_dependencies(mock_base_data, mock_prepared_title, mock_description_html) do
      captured_card_data, final_output = capture_card_data_and_output do
        Jekyll::Books::Core::BookCardRenderer.new(book_minimal, @context, nil, nil).render
      end
    end

    refute_nil captured_card_data
    assert_nil captured_card_data[:image_url]
    assert_equal 'Book cover of Minimal Book.', captured_card_data[:image_alt]
    assert_empty captured_card_data[:extra_elements_html]
    assert_equal '', captured_card_data[:description_html]
    assert_equal '<!-- BOOK_CARD_MISSING_AUTHORS_FAILURE -->minimal_card_html', final_output
  end

  def test_render_returns_log_if_base_data_extraction_fails
    mock_failure_log = '<!-- BOOK_BASE_DATA_EXTRACTION_FAILURE -->'
    Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_base_data,
                                                   {
                                                     log_output: mock_failure_log, site: nil, data_source_for_keys: nil, data_for_description: nil,
                                                   } do
      output = render_with_silent_logger(@book_object_single_author)
      assert_equal mock_failure_log, output
    end
  end

  def test_render_returns_log_if_base_data_has_no_item_data_source
    mock_base_data_no_item_data = {
      site: @site,
      data_source_for_keys: nil,
      data_for_description: nil,
      absolute_url: '/some-url/',
      absolute_image_url: nil,
      raw_title: 'Some Title',
      log_output: '<!-- BOOK_ITEM_INVALID_LOG -->',
    }
    Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_base_data, mock_base_data_no_item_data do
      output = render_with_silent_logger(@book_object_single_author)
      assert_equal '<!-- BOOK_ITEM_INVALID_LOG -->', output
    end
  end

  def test_render_with_missing_title_logs_error
    # This tests line 50-51 and the 'then' branch on line 49
    @site.config['plugin_logging']['BOOK_CARD_MISSING_TITLE'] = true
    book_no_title = create_doc({ 'book_authors' => ['Author'], 'image' => '/img.jpg' }, '/book.html')

    mock_base_data = create_base_data(book_no_title, '/book.html', '/img.jpg', 'Untitled Book')
    captured_output = ''

    Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      Jekyll::Infrastructure::TypographyUtils.stub :prepare_display_title, ->(title) { title } do
        Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_description_html, '' do
          Jekyll::Authors::AuthorLinkUtils.stub :render_author_link, '<a>Author</a>' do
            Jekyll::Infrastructure::TextProcessingUtils.stub :format_list_as_sentence, ->(list, etal_after: nil) { list.first } do
              Jekyll::UI::Ratings::RatingUtils.stub :render_rating_stars, nil do
                Jekyll::UI::Cards::CardRendererUtils.stub :render_card, ->(context:, card_data:) { 'card_html' } do
                  Jekyll.stub :logger, @silent_logger_stub do
                    captured_output = Jekyll::Books::Core::BookCardRenderer.new(book_no_title, @context, nil, nil).render
                  end
                end
              end
            end
          end
        end
      end
    end

    assert_match(/\[ERROR\] BOOK_CARD_MISSING_TITLE_FAILURE:.*Book title is missing and defaulted/, captured_output)
  end

  def test_render_with_provided_image_alt_uses_it
    # This tests the 'then' branch on line 61 (returning alt when it's not empty)
    book_with_alt = create_doc(
      {
        'title' => 'Book',
        'image' => '/img.jpg',
        'image_alt' => 'Custom Alt Text',
        'book_authors' => ['Author'],
      },
      '/book.html',
    )

    mock_base_data = create_base_data(book_with_alt, '/book.html', '/img.jpg', 'Book')
    captured_card_data = nil

    Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      Jekyll::Infrastructure::TypographyUtils.stub :prepare_display_title, ->(title) { title } do
        Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_description_html, '' do
          Jekyll::Authors::AuthorLinkUtils.stub :render_author_link, '<a>Author</a>' do
            Jekyll::Infrastructure::TextProcessingUtils.stub :format_list_as_sentence, ->(list, etal_after: nil) { list.first } do
              Jekyll::UI::Ratings::RatingUtils.stub :render_rating_stars, nil do
                Jekyll::UI::Cards::CardRendererUtils.stub :render_card,
                                                          lambda { |context:, card_data:|
                                                            captured_card_data = card_data
                                                            'card'
                                                          } do
                  Jekyll.stub :logger, @silent_logger_stub do
                    Jekyll::Books::Core::BookCardRenderer.new(book_with_alt, @context, nil, nil).render
                  end
                end
              end
            end
          end
        end
      end
    end

    assert_equal 'Custom Alt Text', captured_card_data[:image_alt]
  end

  def test_render_with_invalid_rating_logs_error_and_continues
    # This tests lines 114-116 (rescue ArgumentError from Jekyll::UI::Ratings::RatingUtils)
    @site.config['plugin_logging']['BOOK_CARD_RATING_ERROR'] = true
    book_bad_rating = create_doc(
      {
        'title' => 'Book',
        'image' => '/img.jpg',
        'book_authors' => ['Author'],
        'rating' => 'invalid',
      },
      '/book.html',
    )

    mock_base_data = create_base_data(book_bad_rating, '/book.html', '/img.jpg', 'Book')
    captured_output = ''

    Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      Jekyll::Infrastructure::TypographyUtils.stub :prepare_display_title, ->(title) { title } do
        Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_description_html, '' do
          Jekyll::Authors::AuthorLinkUtils.stub :render_author_link, '<a>Author</a>' do
            Jekyll::Infrastructure::TextProcessingUtils.stub :format_list_as_sentence, ->(list, etal_after: nil) { list.first } do
              # Make Jekyll::UI::Ratings::RatingUtils raise ArgumentError
              Jekyll::UI::Ratings::RatingUtils.stub :render_rating_stars, ->(_val, _tag = 'div') { raise ArgumentError, 'Invalid rating' } do
                Jekyll::UI::Cards::CardRendererUtils.stub :render_card, ->(context:, card_data:) { 'card_html' } do
                  Jekyll.stub :logger, @silent_logger_stub do
                    captured_output = Jekyll::Books::Core::BookCardRenderer.new(book_bad_rating, @context, nil, nil).render
                  end
                end
              end
            end
          end
        end
      end
    end

    assert_match(/\[WARN\] BOOK_CARD_RATING_ERROR_FAILURE:.*Invalid or malformed.*rating.*value/, captured_output)
  end

  # --- extract_data tests ---

  def test_extract_data_returns_frozen_hash_with_expected_keys
    book = @book_object_single_author
    mock_base_data = create_base_data(book, '/book_single.html', '/images/book.jpg', 'My Book Title')

    data = nil
    Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_description_html, '<p>Book excerpt.</p>' do
        Jekyll.stub :logger, @silent_logger_stub do
          data = Jekyll::Books::Core::BookCardRenderer.new(book, @context, nil, nil).extract_data
        end
      end
    end

    assert data.frozen?
    assert_equal %i[title authors rating excerpt url image_url image_alt subtitle].sort, data.keys.sort
  end

  def test_extract_data_returns_raw_values
    book = @book_object_single_author
    mock_base_data = create_base_data(book, '/book_single.html', '/images/book.jpg', 'My Book Title')

    data = nil
    Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_description_html, '<p>Book excerpt.</p>' do
        Jekyll.stub :logger, @silent_logger_stub do
          data = Jekyll::Books::Core::BookCardRenderer.new(book, @context, nil, nil).extract_data
        end
      end
    end

    assert_equal 'My Book Title', data[:title]
    assert_equal ['Test Author'], data[:authors]
    assert_equal 4, data[:rating]
    assert_equal '<p>Book excerpt.</p>', data[:excerpt]
    assert_equal 'http://example.com/book_single.html', data[:url]
    assert_equal 'http://example.com/images/book.jpg', data[:image_url]
    assert_equal 'Book cover of My Book Title.', data[:image_alt]
    assert_nil data[:subtitle]
  end

  def test_extract_data_returns_nil_when_base_extraction_fails
    mock_failure = { log_output: '<!-- fail -->', site: nil, data_source_for_keys: nil }
    Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_base_data, mock_failure do
      data = Jekyll::Books::Core::BookCardRenderer.new(@book_object_single_author, @context, nil, nil).extract_data
      assert_nil data
    end
  end

  def test_extract_data_respects_title_override
    book = @book_object_single_author
    mock_base_data = create_base_data(book, '/book_single.html', '/images/book.jpg', 'My Book Title')

    data = nil
    Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_description_html, '' do
        Jekyll.stub :logger, @silent_logger_stub do
          data = Jekyll::Books::Core::BookCardRenderer.new(book, @context, 'Custom Title', nil).extract_data
        end
      end
    end

    assert_equal 'Custom Title', data[:title]
    assert_equal 'Book cover of Custom Title.', data[:image_alt]
  end

  def test_extract_data_includes_subtitle_when_provided
    book = @book_object_single_author
    mock_base_data = create_base_data(book, '/book_single.html', '/images/book.jpg', 'My Book Title')

    data = nil
    Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_description_html, '' do
        Jekyll.stub :logger, @silent_logger_stub do
          data = Jekyll::Books::Core::BookCardRenderer.new(book, @context, nil, 'A Subtitle').extract_data
        end
      end
    end

    assert_equal 'A Subtitle', data[:subtitle]
  end

  def test_extract_data_uses_provided_image_alt
    book = create_doc(
      {
        'title' => 'Book',
        'image' => '/img.jpg',
        'image_alt' => 'Custom Alt',
        'book_authors' => ['Author'],
        'rating' => 3,
      },
      '/book.html',
    )
    mock_base_data = create_base_data(book, '/book.html', '/img.jpg', 'Book')

    data = nil
    Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_description_html, '' do
        Jekyll.stub :logger, @silent_logger_stub do
          data = Jekyll::Books::Core::BookCardRenderer.new(book, @context, nil, nil).extract_data
        end
      end
    end

    assert_equal 'Custom Alt', data[:image_alt]
  end

  def test_extract_data_returns_multiple_authors
    book = @book_object_multi_author
    mock_base_data = create_base_data(book, '/book_multi.html', '/images/collab.jpg', 'Collaborative Work')

    data = nil
    Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_description_html, '' do
        Jekyll.stub :logger, @silent_logger_stub do
          data = Jekyll::Books::Core::BookCardRenderer.new(book, @context, nil, nil).extract_data
        end
      end
    end

    assert_equal ['Author One', 'Author Two'], data[:authors]
  end

  def test_render_with_empty_rating_html_excludes_rating_element
    # This tests line 124's else branch: html && !html.empty? returns false when html is ''
    book_with_rating = create_doc(
      {
        'title' => 'Book',
        'image' => '/img.jpg',
        'book_authors' => ['Author'],
        'rating' => 3,
      },
      '/book.html',
    )

    mock_base_data = create_base_data(book_with_rating, '/book.html', '/img.jpg', 'Book')
    captured_card_data = nil

    Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      Jekyll::Infrastructure::TypographyUtils.stub :prepare_display_title, ->(title) { title } do
        Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_description_html, '' do
          Jekyll::Authors::AuthorLinkUtils.stub :render_author_link, '<a>Author</a>' do
            Jekyll::Infrastructure::TextProcessingUtils.stub :format_list_as_sentence, ->(list, etal_after: nil) { list.first } do
              # Return empty string instead of nil to trigger the else branch
              Jekyll::UI::Ratings::RatingUtils.stub :render_rating_stars, '' do
                Jekyll::UI::Cards::CardRendererUtils.stub :render_card,
                                                          lambda { |context:, card_data:|
                                                            captured_card_data = card_data
                                                            'card'
                                                          } do
                  Jekyll.stub :logger, @silent_logger_stub do
                    Jekyll::Books::Core::BookCardRenderer.new(book_with_rating, @context, nil, nil).render
                  end
                end
              end
            end
          end
        end
      end
    end

    # Only author element should be present, no rating element
    assert_equal 1, captured_card_data[:extra_elements_html].length
    assert_match(/by-author/, captured_card_data[:extra_elements_html].first)
  end

  private

  def setup_book_objects
    @book_data_single_author = {
      'title' => 'My Book Title',
      'image' => '/images/book.jpg',
      'book_authors' => ['Test Author'],
      'rating' => 4,
      'excerpt' => Struct.new(:output).new('<p>Book excerpt.</p>'),
    }
    @book_object_single_author = create_doc(@book_data_single_author, '/book_single.html')

    @book_data_multi_author = {
      'title' => 'Collaborative Work',
      'image' => '/images/collab.jpg',
      'book_authors' => ['Author One', 'Author Two'],
      'rating' => 5,
      'excerpt' => Struct.new(:output).new('<p>A joint effort.</p>'),
    }
    @book_object_multi_author = create_doc(@book_data_multi_author, '/book_multi.html')

    @book_data_no_authors = {
      'title' => 'Anonymous Tales',
      'image' => '/images/anon.jpg',
      'book_authors' => [],
      'rating' => 3,
      'excerpt' => Struct.new(:output).new('<p>Stories from nowhere.</p>'),
    }
    @book_object_no_authors = create_doc(@book_data_no_authors, '/book_no_authors.html')

    @book_data_four_authors = {
      'title' => 'Four Author Book',
      'image' => '/images/four.jpg',
      'book_authors' => ['First Author', 'Second Author', 'Third Author', 'Fourth Author'],
      'rating' => 4,
      'excerpt' => Struct.new(:output).new('<p>Many authors.</p>'),
    }
    @book_object_four_authors = create_doc(@book_data_four_authors, '/book_four.html')
  end

  def create_silent_logger_stub
    Object.new.tap do |logger|
      def logger.warn(_topic, _message); end
      def logger.error(_topic, _message); end
      def logger.info(_topic, _message); end
      def logger.debug(_topic, _message); end
    end
  end

  def render_with_silent_logger(book, **options)
    Jekyll.stub :logger, @silent_logger_stub do
      title_override = options[:display_title_override]
      subtitle = options[:subtitle]
      Jekyll::Books::Core::BookCardRenderer.new(book, @context, title_override, subtitle).render
    end
  end

  def create_base_data(book, url, image_url, title, log: '')
    {
      site: @site,
      data_source_for_keys: book.data,
      data_for_description: book.data,
      absolute_url: "http://example.com#{url}",
      absolute_image_url: image_url ? "http://example.com#{image_url}" : nil,
      raw_title: title,
      log_output: +log,
    }
  end

  def build_author_element(formatted_authors)
    "    <span class=\"by-author\"> by #{formatted_authors}</span>\n"
  end

  def build_rating_element(rating_html)
    "    #{rating_html}\n"
  end

  def build_expected_card_data(base_data, title, description, extra_elements)
    {
      base_class: 'book-card',
      url: base_data[:absolute_url],
      image_url: base_data[:absolute_image_url],
      image_alt: "Book cover of #{base_data[:raw_title]}.",
      image_div_class: 'card-book-cover',
      title_html: "<strong><cite class=\"book-title\">#{title}</cite></strong>",
      extra_elements_html: extra_elements,
      description_html: description,
      description_wrapper_html_open: "    <div class=\"card-element card-text\">\n      ",
      description_wrapper_html_close: "\n    </div>\n",
    }
  end

  def stub_rendering_dependencies(base_data, title, description, &block)
    Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_base_data, base_data do
      Jekyll::Infrastructure::TypographyUtils.stub :prepare_display_title, title do
        Jekyll::UI::Cards::CardDataExtractorUtils.stub :extract_description_html, description, &block
      end
    end
  end

  def capture_card_data(&block)
    captured_card_data = nil
    Jekyll::UI::Cards::CardRendererUtils.stub :render_card,
                                              lambda { |context:, card_data:|
                                                captured_card_data = card_data
                                                'mocked_card'
                                              } do
      Jekyll.stub :logger, @silent_logger_stub, &block
    end
    captured_card_data
  end

  def capture_card_data_and_output
    captured_card_data = nil
    final_output = ''
    Jekyll::UI::Cards::CardRendererUtils.stub :render_card,
                                              lambda { |context:, card_data:|
                                                captured_card_data = card_data
                                                'minimal_card_html'
                                              } do
      Jekyll.stub :logger, @silent_logger_stub do
        final_output = yield
      end
    end
    [captured_card_data, final_output]
  end
end
