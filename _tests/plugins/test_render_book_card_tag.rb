# _tests/plugins/test_render_book_card_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/render_book_card_tag' # Load the tag

class TestRenderBookCardTag < Minitest::Test

  def setup
    @site = create_site({ 'url' => 'http://example.com' }) # For BookCardUtils -> CardDataExtractorUtils -> UrlUtils
    @book_obj = create_doc({ 'title' => 'Test Book', 'path' => 'test-book.md' }, '/test-book.html')
    @context = create_context(
      { 'my_book' => @book_obj, 'nil_book_var' => nil },
      { site: @site, page: create_doc({ 'path' => 'current_page.md' }, '/current-page.html') } # Page path for SourcePage
    )

    # Silent logger for tests not asserting specific console output from PluginLoggerUtils
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
      def logger.log_level=(level); end;    def logger.progname=(name); end
    end
  end

  def render_tag(markup, context = @context)
    output = ""
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% render_book_card #{markup} %}").render!(context)
    end
    output
  end

  # --- Test Cases ---

  # 1. Syntax Error
  def test_syntax_error_if_markup_is_empty
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% render_book_card %}")
    end
    assert_match "A book object variable must be provided", err.message

    err_whitespace = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% render_book_card    %}")
    end
    assert_match "A book object variable must be provided", err_whitespace.message
  end

  # 2. Render - Success
  def test_render_success_calls_book_card_utils
    markup = "my_book" # 'my_book' is @book_obj in context
    expected_card_html = "<div class='book-card'>Rendered Test Book</div>"
    captured_args = nil

    BookCardUtils.stub :render, ->(book_arg, context_arg) {
      captured_args = { book: book_arg, context: context_arg }
      expected_card_html
    } do
      output = render_tag(markup)
      assert_equal expected_card_html, output
    end

    refute_nil captured_args, "BookCardUtils.render should have been called"
    assert_equal @book_obj, captured_args[:book], "Incorrect book object passed to BookCardUtils"
    assert_equal @context, captured_args[:context], "Incorrect context passed to BookCardUtils"
  end

  # 3. Render - Failure: Book object resolves to nil
  def test_render_failure_if_book_object_is_nil
    markup = "nil_book_var" # 'nil_book_var' resolves to nil
    expected_log_html = "<!-- RENDER_BOOK_CARD_TAG: NIL BOOK OBJECT -->"
    captured_log_args = nil

    @site.config['plugin_logging']['RENDER_BOOK_CARD_TAG'] = true

    PluginLoggerUtils.stub :log_liquid_failure, ->(args) {
      captured_log_args = args
      expected_log_html
    } do
      output = render_tag(markup)
      assert_equal expected_log_html, output
    end

    refute_nil captured_log_args, "PluginLoggerUtils.log_liquid_failure should have been called"
    assert_equal @context, captured_log_args[:context]
    assert_equal "RENDER_BOOK_CARD_TAG", captured_log_args[:tag_type]
    assert_match "Book object variable '#{markup}' resolved to nil", captured_log_args[:reason]
    assert_equal({ markup: markup }, captured_log_args[:identifiers])
    assert_nil captured_log_args[:level], "Tag should not explicitly pass level, relying on util's default"
  end

  def test_render_failure_if_book_variable_not_found
    markup = "non_existent_book_var"
    expected_log_html = "<!-- RENDER_BOOK_CARD_TAG: NON-EXISTENT BOOK VAR -->"
    captured_log_args = nil

    @site.config['plugin_logging']['RENDER_BOOK_CARD_TAG'] = true

    PluginLoggerUtils.stub :log_liquid_failure, ->(args) {
      captured_log_args = args
      expected_log_html
    } do
      output = render_tag(markup)
      assert_equal expected_log_html, output
    end

    refute_nil captured_log_args
    assert_equal "RENDER_BOOK_CARD_TAG", captured_log_args[:tag_type]
    assert_match "Book object variable '#{markup}' resolved to nil", captured_log_args[:reason]
    assert_nil captured_log_args[:level], "Tag should not explicitly pass level, relying on util's default"
  end

  # 4. Render - Failure: BookCardUtils.render raises an error
  def test_render_failure_if_book_card_utils_raises_error
    markup = "my_book"
    error_message = "Something went wrong in BookCardUtils"
    expected_log_html = "<!-- RENDER_BOOK_CARD_TAG: UTIL ERROR -->"
    captured_log_args = nil

    @site.config['plugin_logging']['RENDER_BOOK_CARD_TAG'] = true

    BookCardUtils.stub :render, ->(_book, _ctx) { raise StandardError, error_message } do
      PluginLoggerUtils.stub :log_liquid_failure, ->(args) {
        captured_log_args = args
        expected_log_html
      } do
        output = render_tag(markup)
        assert_equal expected_log_html, output
      end
    end

    refute_nil captured_log_args, "PluginLoggerUtils.log_liquid_failure should have been called for util error"
    assert_equal @context, captured_log_args[:context]
    assert_equal "RENDER_BOOK_CARD_TAG", captured_log_args[:tag_type]
    assert_match "Error rendering book card: #{error_message}", captured_log_args[:reason]
    assert_equal({ book_markup: markup, error_class: "StandardError" }, captured_log_args[:identifiers])
    assert_nil captured_log_args[:level], "Tag should not explicitly pass level, relying on util's default"
  end
end