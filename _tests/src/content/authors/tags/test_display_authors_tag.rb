# frozen_string_literal: true

# _tests/plugins/test_display_authors_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/authors/tags/display_authors_tag'

# Tests for Jekyll::Authors::Tags::DisplayAuthorsTag Liquid tag.
#
# Verifies that the tag correctly parses arguments and delegates to Jekyll::Authors::DisplayAuthorsUtil.
class TestDisplayAuthorsTag < Minitest::Test
  def setup
    @site = create_site({ 'url' => 'http://example.com' })
    @context = create_context(
      {
        'page' => {
          'book_authors' => ['Isaac Asimov', 'Robert Silverberg'],
          'single_author' => ['Jane Doe'],
          'linked_false_var' => false,
          'etal_var' => 3
        }
      },
      { site: @site }
    )
    @silent_logger_stub = create_silent_logger
  end

  private

  # Helper to create a silent logger stub
  def create_silent_logger
    Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
  end

  public

  # --- Syntax Error Tests ---

  def test_syntax_error_missing_authors_list
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_authors %}')
    end
    assert_match 'Missing required authors list', err.message

    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_authors linked=true %}')
    end
    assert_match 'Missing required authors list', err.message
  end

  def test_syntax_error_unknown_named_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_authors page.book_authors badkey='test' %}")
    end
    assert_match "Unknown argument 'badkey'", err.message
  end

  def test_syntax_error_duplicate_named_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_authors page.book_authors linked=true linked=false %}')
    end
    assert_match "Duplicate argument 'linked'", err.message

    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_authors page.book_authors etal_after=3 etal_after=4 %}')
    end
    assert_match "Duplicate argument 'etal_after'", err.message
  end

  def test_syntax_error_invalid_argument_syntax
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_authors page.book_authors not_a_key_value %}')
    end
    assert_match "Invalid argument syntax near 'not_a_key_value'", err.message
  end

  # --- Orchestration Tests ---

  def test_calls_util_with_correct_author_input
    captured_args = {}
    mock_output = '<a href="/authors/isaac-asimov.html">Isaac Asimov</a>'

    Jekyll::Authors::DisplayAuthorsUtil.stub :render_author_list, lambda { |**args|
      captured_args = args
      mock_output
    } do
      Jekyll.stub :logger, @silent_logger_stub do
        output = Liquid::Template.parse('{% display_authors page.book_authors %}').render!(@context)

        assert_equal ['Isaac Asimov', 'Robert Silverberg'], captured_args[:author_input]
        assert_equal @context, captured_args[:context]
        assert_equal mock_output, output
      end
    end
  end

  def test_calls_util_with_linked_true_by_default
    captured_args = {}

    Jekyll::Authors::DisplayAuthorsUtil.stub :render_author_list, lambda { |**args|
      captured_args = args
      '<mock output>'
    } do
      Jekyll.stub :logger, @silent_logger_stub do
        Liquid::Template.parse('{% display_authors page.single_author %}').render!(@context)

        assert_equal true, captured_args[:linked]
      end
    end
  end

  def test_calls_util_with_linked_false_when_specified
    captured_args = {}

    Jekyll::Authors::DisplayAuthorsUtil.stub :render_author_list, lambda { |**args|
      captured_args = args
      '<mock output>'
    } do
      Jekyll.stub :logger, @silent_logger_stub do
        Liquid::Template.parse("{% display_authors page.single_author linked='false' %}").render!(@context)

        assert_equal false, captured_args[:linked]
      end
    end
  end

  def test_calls_util_with_linked_variable
    captured_args = {}

    Jekyll::Authors::DisplayAuthorsUtil.stub :render_author_list, lambda { |**args|
      captured_args = args
      '<mock output>'
    } do
      Jekyll.stub :logger, @silent_logger_stub do
        Liquid::Template.parse('{% display_authors page.single_author linked=page.linked_false_var %}').render!(@context)

        assert_equal false, captured_args[:linked]
      end
    end
  end

  def test_calls_util_with_etal_after_nil_by_default
    captured_args = {}

    Jekyll::Authors::DisplayAuthorsUtil.stub :render_author_list, lambda { |**args|
      captured_args = args
      '<mock output>'
    } do
      Jekyll.stub :logger, @silent_logger_stub do
        Liquid::Template.parse('{% display_authors page.book_authors %}').render!(@context)

        assert_nil captured_args[:etal_after]
      end
    end
  end

  def test_calls_util_with_etal_after_when_specified
    captured_args = {}

    Jekyll::Authors::DisplayAuthorsUtil.stub :render_author_list, lambda { |**args|
      captured_args = args
      '<mock output>'
    } do
      Jekyll.stub :logger, @silent_logger_stub do
        Liquid::Template.parse('{% display_authors page.book_authors etal_after=2 %}').render!(@context)

        assert_equal 2, captured_args[:etal_after]
      end
    end
  end

  def test_calls_util_with_etal_after_variable
    captured_args = {}

    Jekyll::Authors::DisplayAuthorsUtil.stub :render_author_list, lambda { |**args|
      captured_args = args
      '<mock output>'
    } do
      Jekyll.stub :logger, @silent_logger_stub do
        Liquid::Template.parse('{% display_authors page.book_authors etal_after=page.etal_var %}').render!(@context)

        assert_equal 3, captured_args[:etal_after]
      end
    end
  end

  def test_returns_output_from_util
    mock_output = '<div class="custom-authors">Custom Author HTML</div>'

    Jekyll::Authors::DisplayAuthorsUtil.stub :render_author_list, ->(**_args) { mock_output } do
      Jekyll.stub :logger, @silent_logger_stub do
        output = Liquid::Template.parse('{% display_authors page.book_authors %}').render!(@context)

        assert_equal mock_output, output
      end
    end
  end

  def test_trailing_whitespace_after_arguments
    # Tests line 73: break if scanner.eos? after skipping whitespace
    captured_args = {}

    Jekyll::Authors::DisplayAuthorsUtil.stub :render_author_list, lambda { |**args|
      captured_args = args
      '<mock output>'
    } do
      Jekyll.stub :logger, @silent_logger_stub do
        Liquid::Template.parse('{% display_authors page.book_authors linked=true   %}').render!(@context)

        assert_equal true, captured_args[:linked]
      end
    end
  end

  def test_linked_option_resolves_to_nil
    # Tests line 115: return true if val.nil?
    ctx = create_context(
      { 'page' => { 'book_authors' => ['Jane Doe'], 'nil_var' => nil } },
      { site: @site }
    )
    captured_args = {}

    Jekyll::Authors::DisplayAuthorsUtil.stub :render_author_list, lambda { |**args|
      captured_args = args
      '<mock output>'
    } do
      Jekyll.stub :logger, @silent_logger_stub do
        Liquid::Template.parse('{% display_authors page.book_authors linked=page.nil_var %}').render!(ctx)

        # When linked resolves to nil, it should default to true
        assert_equal true, captured_args[:linked]
      end
    end
  end

  def test_etal_after_option_resolves_to_nil
    # Tests line 125: return nil unless val
    ctx = create_context(
      { 'page' => { 'book_authors' => ['Jane Doe'], 'nil_var' => nil } },
      { site: @site }
    )
    captured_args = {}

    Jekyll::Authors::DisplayAuthorsUtil.stub :render_author_list, lambda { |**args|
      captured_args = args
      '<mock output>'
    } do
      Jekyll.stub :logger, @silent_logger_stub do
        Liquid::Template.parse('{% display_authors page.book_authors etal_after=page.nil_var %}').render!(ctx)

        # When etal_after resolves to nil, it should return nil
        assert_nil captured_args[:etal_after]
      end
    end
  end

  def test_etal_after_option_invalid_integer
    # Tests line 129: rescue ArgumentError returns nil
    ctx = create_context(
      { 'page' => { 'book_authors' => ['Jane Doe'], 'bad_int' => 'not_a_number' } },
      { site: @site }
    )
    captured_args = {}

    Jekyll::Authors::DisplayAuthorsUtil.stub :render_author_list, lambda { |**args|
      captured_args = args
      '<mock output>'
    } do
      Jekyll.stub :logger, @silent_logger_stub do
        Liquid::Template.parse('{% display_authors page.book_authors etal_after=page.bad_int %}').render!(ctx)

        # When etal_after can't be converted to Integer, it should return nil
        assert_nil captured_args[:etal_after]
      end
    end
  end
end
