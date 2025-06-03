# _tests/plugins/test_front_matter_validator.rb
require_relative '../test_helper'
require_relative '../../_plugins/front_matter_validator'
require_relative '../../_plugins/utils/front_matter_utils' # Ensure this is loaded

class TestFrontMatterValidator < Minitest::Test

  def setup
    @book_collection_label = 'books'
    @post_collection_label = 'posts'

    # Define base required fields for different types
    @required_for_books = ['title', 'book_authors', 'book_number'] # Rating not required
    @required_for_posts = ['title', 'date'] # 'date' is required for posts

    @site = create_site
    # No need to store/restore original config directly from constant here
    # as we use override/reset methods in the plugin.

    # Silent logger stub to suppress console output during tests
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.debug(progname = nil, message = nil); end
      def logger.info(progname = nil, message = nil); end
      def logger.warn(progname = nil, message = nil); end
      def logger.error(progname = nil, message = nil); end
    end
  end

  def teardown
    # Reset any test-specific config override after each test
    Jekyll::FrontMatterValidator.reset_config_for_test
  end

  # Helper to temporarily set the validator's config for a test using the new methods
  def with_validator_config(config)
    Jekyll::FrontMatterValidator.override_config_for_test(config)
    yield
  ensure
    Jekyll::FrontMatterValidator.reset_config_for_test # Ensure reset even if test fails
  end

  # --- Tests for 'books' Collection ---
  def test_book_collection_valid_front_matter_passes
    with_validator_config({ @book_collection_label => @required_for_books }) do
      doc = create_doc(
        { 'title' => 'Valid Book', 'book_authors' => ['An Author'], 'book_number' => '1', 'path' => 'valid-book.html' },
        '/valid-book.html', 'content', nil, MockCollection.new(nil, @book_collection_label)
      )
      Jekyll.stub :logger, @silent_logger_stub do
        assert_nil Jekyll::FrontMatterValidator.validate_document(doc), "Should pass with all required fields"
      end
    end
  end

  def test_book_collection_missing_title_raises_error
    with_validator_config({ @book_collection_label => @required_for_books }) do
      doc_data = {
        'title' => nil,
        'book_authors' => ['An Author'],
        'book_number' => '1',
        'path' => 'missing-title.html'
      }
      doc = create_doc(doc_data, '/missing-title.html', 'content', nil, MockCollection.new(nil, @book_collection_label))

      err = nil
      Jekyll.stub :logger, @silent_logger_stub do
        err = assert_raises Jekyll::Errors::FatalException do
          Jekyll::FrontMatterValidator.validate_document(doc)
        end
      end
      assert_match "missing or has empty required front matter fields: title", err.message
      assert_match "Document in collection '#{@book_collection_label}'", err.message
      assert_match "'missing-title.html'", err.message
    end
  end

  def test_book_collection_empty_book_authors_string_raises_error
    with_validator_config({ @book_collection_label => @required_for_books }) do
      doc_data = {
        'title' => 'Test', 'book_authors' => '   ', 'book_number' => '1',
        'path' => 'empty-authors.html'
      }
      doc = create_doc(doc_data, '/empty-authors.html', 'content', nil, MockCollection.new(nil, @book_collection_label))
      err = nil
      Jekyll.stub :logger, @silent_logger_stub do
        err = assert_raises Jekyll::Errors::FatalException do
          Jekyll::FrontMatterValidator.validate_document(doc)
        end
      end
      assert_match "missing or has empty required front matter fields: book_authors", err.message
    end
  end

  def test_book_collection_empty_book_authors_array_raises_error
    with_validator_config({ @book_collection_label => @required_for_books }) do
      doc_data = {
        'title' => 'Test', 'book_authors' => ["", nil, "  "], 'book_number' => '1',
        'path' => 'empty-authors-array.html'
      }
      doc = create_doc(doc_data, '/empty-authors-array.html', 'content', nil, MockCollection.new(nil, @book_collection_label))
      err = nil
      Jekyll.stub :logger, @silent_logger_stub do
        err = assert_raises Jekyll::Errors::FatalException do
          Jekyll::FrontMatterValidator.validate_document(doc)
        end
      end
      assert_match "missing or has empty required front matter fields: book_authors", err.message
    end
  end

  def test_book_collection_missing_book_number_raises_error
    with_validator_config({ @book_collection_label => @required_for_books }) do
      doc_data = {
        'title' => 'Test', 'book_authors' => ['Author'],
        'path' => 'missing-book-number.html'
      }
      doc = create_doc(doc_data, '/missing-book-number.html', 'content', nil, MockCollection.new(nil, @book_collection_label))
      err = nil
      Jekyll.stub :logger, @silent_logger_stub do
        err = assert_raises Jekyll::Errors::FatalException do
          Jekyll::FrontMatterValidator.validate_document(doc)
        end
      end
      assert_match "missing or has empty required front matter fields: book_number", err.message
    end
  end

  def test_book_collection_multiple_missing_fields_raises_error
    with_validator_config({ @book_collection_label => @required_for_books }) do # Requires title, book_authors, book_number
      doc_data = {
        'title' => 'Test', # Only title is present
        'path' => 'multiple-missing-books.html'
      }
      doc = create_doc(doc_data, '/multiple-missing-books.html', 'content', nil, MockCollection.new(nil, @book_collection_label))
      err = nil
      Jekyll.stub :logger, @silent_logger_stub do
        err = assert_raises Jekyll::Errors::FatalException do
          Jekyll::FrontMatterValidator.validate_document(doc)
        end
      end
      assert_match "book_authors", err.message
      assert_match "book_number", err.message
      refute_match "rating", err.message # Ensure rating is NOT listed as missing
    end
  end

  # --- Tests for 'posts' Collection ---
  def test_post_collection_valid_front_matter_passes_with_date_in_fm
    with_validator_config({ @post_collection_label => @required_for_posts }) do
      # Date explicitly in front matter
      doc = create_doc(
        { 'title' => 'Valid Post FM Date', 'date' => Time.now, 'path' => 'valid-post-fm-date.html' },
        '/valid-post-fm-date.html', 'content', nil, MockCollection.new(nil, @post_collection_label)
      )
      Jekyll.stub :logger, @silent_logger_stub do
        assert_nil Jekyll::FrontMatterValidator.validate_document(doc)
      end
    end
  end

  def test_post_collection_valid_front_matter_passes_with_date_from_filename
    # Simulate date derived from filename (not in front matter data, but doc.date is set)
    with_validator_config({ @post_collection_label => @required_for_posts }) do
      doc_data = { 'title' => 'Post Date From Filename', 'path' => '2024-01-01-my-post.md' }
      # create_doc will use the date_str_param to set doc.date and doc.data['date']
      doc = create_doc(
        doc_data,
        '/2024/01/01/my-post.html', 'content', "2024-01-01", # This sets doc.date
        MockCollection.new(nil, @post_collection_label)
      )
      # Even if doc.data['date'] was nil, doc.date (attribute) would be valid.
      # The validator now checks doc.date for posts.
      Jekyll.stub :logger, @silent_logger_stub do
        assert_nil Jekyll::FrontMatterValidator.validate_document(doc)
      end
    end
  end

  def test_post_collection_missing_date_raises_error_if_doc_date_is_nil
    with_validator_config({ @post_collection_label => @required_for_posts }) do
      doc_data = { 'title' => 'Post Truly Missing Date', 'path' => 'post-truly-missing-date.html' }
      doc = create_doc(
        doc_data,
        '/post-truly-missing-date.html', 'content', nil, # No date_str_param
        MockCollection.new(nil, @post_collection_label)
      )
      # create_doc would set doc.date to Time.now if date not in data_overrides and no date_str_param.
      # To simulate Jekyll failing to set a date (e.g. invalid filename and no FM date), we mock doc.date.
      doc.define_singleton_method(:date) { nil }

      err = nil
      Jekyll.stub :logger, @silent_logger_stub do
        err = assert_raises Jekyll::Errors::FatalException do
          Jekyll::FrontMatterValidator.validate_document(doc)
        end
      end
      assert_match "missing or has empty required front matter fields: date", err.message
      assert_match "'post-truly-missing-date.html'", err.message
    end
  end

  def test_post_collection_date_is_not_time_object_raises_error
    with_validator_config({ @post_collection_label => @required_for_posts }) do
      doc_data = { 'title' => 'Post Bad Date Type', 'path' => 'post-bad-date-type.html' }
      doc = create_doc(doc_data, '/post-bad-date-type.html', 'content', nil, MockCollection.new(nil, @post_collection_label))
      # Override doc.date to return something that is not a Time object
      doc.define_singleton_method(:date) { "This is not a Time object" }

      err = nil
      Jekyll.stub :logger, @silent_logger_stub do
        err = assert_raises Jekyll::Errors::FatalException do
          Jekyll::FrontMatterValidator.validate_document(doc)
        end
      end
      assert_match "missing or has empty required front matter fields: date", err.message
      assert_match "'post-bad-date-type.html'", err.message
    end
  end


  # --- Test for documents/pages not configured for validation ---
  def test_unconfigured_document_type_is_skipped
    with_validator_config({ 'other_collection' => ['some_field'] }) do
      doc = create_doc(
        { 'title' => 'Book in Unwatched Collection', 'path' => 'unwatched-book.html' },
        '/unwatched-book.html', 'content', nil, MockCollection.new(nil, @book_collection_label)
      )
      Jekyll.stub :logger, @silent_logger_stub do
        assert_nil Jekyll::FrontMatterValidator.validate_document(doc)
      end

      page = create_doc(
        { 'layout' => 'unwatched_layout', 'title' => 'Page with Unwatched Layout', 'path' => 'unwatched-page.html' },
        '/unwatched-page.html', 'content', nil, nil
      )
      Jekyll.stub :logger, @silent_logger_stub do
        assert_nil Jekyll::FrontMatterValidator.validate_document(page)
      end
    end
  end

  def test_logs_error_before_raising_exception
    with_validator_config({ @book_collection_label => ['title'] }) do
      doc_data_for_log = {'path' => 'no-title-for-log-test.html', 'title' => nil } # Explicitly nil title
      doc = create_doc(doc_data_for_log, '/no-title-for-log-test.html', 'c', nil, MockCollection.new(nil, @book_collection_label))
      # doc.data.delete('title') # No longer needed if title is nil in data_overrides

      mock_logger = Minitest::Mock.new
      mock_logger.expect(
        :error, nil,
        ["FrontMatter Error:", ->(msg){ msg.include?("'no-title-for-log-test.html'") && msg.include?("missing or has empty required front matter fields: title") }]
      )

      Jekyll.stub :logger, mock_logger do
        assert_raises Jekyll::Errors::FatalException do
          Jekyll::FrontMatterValidator.validate_document(doc)
        end
      end
      mock_logger.verify
    end
  end
end
