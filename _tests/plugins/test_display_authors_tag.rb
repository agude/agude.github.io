# _tests/plugins/test_display_authors_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_authors_tag'

class TestDisplayAuthorsTag < Minitest::Test

  def setup
    @site = create_site
    @context = create_context(
      {
        'page' => {
          'single_author_list' => ['Jane Doe'],
          'multi_author_list' => ['John Smith', 'Jane Doe', 'Peter Pan'],
          'single_author_string' => 'Richard Roe',
          'empty_author_list' => [],
          'nil_author_list' => nil,
          'linked_true_var' => true,
          'linked_false_var' => false,
          'linked_string_true_var' => 'true',
          'linked_string_false_var' => 'false'
        }
      },
      { site: @site } # No current page needed for these specific tests as AuthorLinkUtils handles it
    )

    # Expected HTML from AuthorLinkUtils.render_author_link (simplified for stubbing)
    @mock_link_jane = "<a href=\"/authors/jane-doe\"><span class=\"author-name\">Jane Doe</span></a>"
    @mock_link_john = "<a href=\"/authors/john-smith\"><span class=\"author-name\">John Smith</span></a>"
    @mock_link_peter = "<a href=\"/authors/peter-pan\"><span class=\"author-name\">Peter Pan</span></a>"
    @mock_link_richard = "<a href=\"/authors/richard-roe\"><span class=\"author-name\">Richard Roe</span></a>"

    # Expected plain text span
    @plain_span_jane = "<span class=\"author-name\">Jane Doe</span>"
    @plain_span_john = "<span class=\"author-name\">John Smith</span>"
    @plain_span_peter = "<span class=\"author-name\">Peter Pan</span>"
    @plain_span_richard = "<span class=\"author-name\">Richard Roe</span>"

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
    end
  end

  # Helper to render the tag, stubs underlying utils
  def render_tag(markup, context = @context)
    output = ""
    # Stub AuthorLinkUtils.render_author_link
    # The possessive flag is no longer passed from DisplayAuthorsTag
    AuthorLinkUtils.stub :render_author_link, ->(name, ctx, _link_text_override = nil, _possessive = false) {
      case name
      when 'Jane Doe' then @mock_link_jane
      when 'John Smith' then @mock_link_john
      when 'Peter Pan' then @mock_link_peter
      when 'Richard Roe' then @mock_link_richard
      else "<a href=\"...\"><span class=\"author-name\">#{name}</span></a>" # Fallback
      end
    } do
      Jekyll.stub :logger, @silent_logger_stub do # For any logs from FrontMatterUtils if input is weird
        output = Liquid::Template.parse("{% display_authors #{markup} %}").render!(context)
      end
    end
    output
  end

  # --- Syntax Error Tests (Initialize) ---
  def test_syntax_error_missing_authors_list
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_authors %}")
    end
    assert_match "Missing required authors list", err.message

    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_authors linked=true %}") # Authors list still missing
    end
    assert_match "Missing required authors list", err.message
  end

  def test_syntax_error_unknown_named_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_authors page.single_author_list badkey='test' %}")
    end
    assert_match "Unknown argument 'badkey'", err.message
  end

  def test_syntax_error_duplicate_named_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_authors page.single_author_list linked=true linked=false %}")
    end
    assert_match "Duplicate argument 'linked'", err.message
  end

  def test_syntax_error_invalid_argument_syntax_after_authors_list
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_authors page.single_author_list not_a_key_value %}")
    end
    assert_match "Invalid argument syntax near 'not_a_key_value'", err.message
  end


  # --- Rendering Tests ---
  def test_render_single_author_from_list_linked_default
    output = render_tag("page.single_author_list") # ['Jane Doe']
    assert_equal @mock_link_jane, output
  end

  def test_render_single_author_from_string_linked_default
    output = render_tag("page.single_author_string") # "Richard Roe"
    assert_equal @mock_link_richard, output
  end

  def test_render_multiple_authors_linked_default
    # page.multi_author_list is ['John Smith', 'Jane Doe', 'Peter Pan']
    # Expected: "John Smith link, Jane Doe link, and Peter Pan link"
    expected_output = "#{@mock_link_john}, #{@mock_link_jane}, and #{@mock_link_peter}"
    output = render_tag("page.multi_author_list")
    assert_equal expected_output, output
  end

  def test_render_two_authors_linked_default
    @context['page']['two_authors'] = ['John Smith', 'Jane Doe']
    expected_output = "#{@mock_link_john} and #{@mock_link_jane}"
    output = render_tag("page.two_authors")
    assert_equal expected_output, output
  end

  # --- Test 'linked' option ---
  def test_render_single_author_unlinked
    output = render_tag("page.single_author_list linked='false'")
    assert_equal @plain_span_jane, output
  end

  def test_render_single_author_unlinked_variable
    output = render_tag("page.single_author_list linked=page.linked_false_var")
    assert_equal @plain_span_jane, output
  end

  def test_render_multiple_authors_unlinked
    expected_output = "#{@plain_span_john}, #{@plain_span_jane}, and #{@plain_span_peter}"
    output = render_tag("page.multi_author_list linked='false'")
    assert_equal expected_output, output
  end

  def test_render_multiple_authors_linked_explicitly_true_string
    expected_output = "#{@mock_link_john}, #{@mock_link_jane}, and #{@mock_link_peter}"
    output = render_tag("page.multi_author_list linked='true'")
    assert_equal expected_output, output
  end

  def test_render_multiple_authors_linked_explicitly_true_variable
    expected_output = "#{@mock_link_john}, #{@mock_link_jane}, and #{@mock_link_peter}"
    output = render_tag("page.multi_author_list linked=page.linked_true_var")
    assert_equal expected_output, output
  end

  # --- Test Empty/Nil Author Inputs ---
  def test_render_empty_author_list_variable
    output = render_tag("page.empty_author_list") # []
    assert_equal "", output
  end

  def test_render_nil_author_list_variable
    output = render_tag("page.nil_author_list") # nil
    assert_equal "", output
  end

  def test_render_authors_list_markup_resolves_to_nil
    output = render_tag("non_existent_variable")
    assert_equal "", output
  end

  def test_render_authors_list_markup_resolves_to_empty_string
    @context['page']['empty_string_for_authors'] = ""
    output = render_tag("page.empty_string_for_authors")
    assert_equal "", output
  end

  def test_render_authors_list_markup_resolves_to_whitespace_string
    @context['page']['whitespace_string_for_authors'] = "   "
    output = render_tag("page.whitespace_string_for_authors")
    assert_equal "", output # FrontMatterUtils turns this into an empty list
  end

end
