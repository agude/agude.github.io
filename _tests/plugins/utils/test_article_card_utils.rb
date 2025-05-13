# _tests/plugins/utils/test_article_card_utils.rb
require_relative '../../test_helper'
# ArticleCardUtils is loaded by test_helper

class TestArticleCardUtils < Minitest::Test
  def setup
    @site = create_site({'url' => 'http://example.com'})
    @context = create_context({}, { site: @site, page: create_doc({}, '/current.html') })

    # Data for a typical post object
    @post_data_hash = {
      'title' => 'My Article Title',
      'image' => '/images/article.jpg',
      'image_alt' => 'Custom Alt',
      'description' => 'Front matter description.' # Used by Article type
    }
    @post_object = create_doc(@post_data_hash, '/article.html')

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
      def logger.log_level=(level); end;    def logger.progname=(name); end
    end
  end

  def test_render_article_card_success
    # This is what CardDataExtractorUtils.extract_base_data is stubbed to return
    mock_base_data_from_extractor = {
      site: @site,
      data_source_for_keys: @post_object.data, # For Jekyll::Document, this is the .data hash
      data_for_description: @post_object.data, # Pass the .data hash
      absolute_url: "http://example.com/article.html",
      absolute_image_url: "http://example.com/images/article.jpg",
      raw_title: "My Article Title", # From @post_object.data['title']
      log_output: ""
    }
    # This is what LiquidUtils._prepare_display_title is stubbed to return
    mock_prepared_title = "My Prepared Article Title"
    # This is what CardDataExtractorUtils.extract_description_html is stubbed to return
    mock_description_html_from_desc_extractor = "Front matter description."

    expected_card_data_to_renderer = {
      base_class: "article-card",
      url: mock_base_data_from_extractor[:absolute_url],
      image_url: mock_base_data_from_extractor[:absolute_image_url],
      image_alt: "Custom Alt", # This comes from @post_object.data['image_alt']
      image_div_class: "card-image",
      title_html: "<strong>#{mock_prepared_title}</strong>",
      description_html: mock_description_html_from_desc_extractor,
      description_wrapper_html_open: "<br>\n",
      description_wrapper_html_close: "",
      extra_elements_html: []
    }

    captured_card_data = nil

    CardDataExtractorUtils.stub :extract_base_data, mock_base_data_from_extractor do
      LiquidUtils.stub :_prepare_display_title, mock_prepared_title do
        CardDataExtractorUtils.stub :extract_description_html, mock_description_html_from_desc_extractor do
          CardRendererUtils.stub :render_card, ->(context:, card_data:) { captured_card_data = card_data; "mocked_card_html" } do
            Jekyll.stub :logger, @silent_logger_stub do # For PluginLoggerUtils if called
              output = ArticleCardUtils.render(@post_object, @context)
              assert_equal "mocked_card_html", output
            end
          end
        end
      end
    end

    refute_nil captured_card_data, "CardRendererUtils.render_card should have been called"
    assert_equal expected_card_data_to_renderer, captured_card_data

    # Verify extract_description_html was called with correct type
    # This requires a more complex stub if we want to capture args for nested stubs.
    # For now, we assume the data flow implies it was called correctly if output is as expected.
  end

  def test_render_article_card_no_image
    post_no_image_data = { 'title' => 'No Image Post' } # No 'image' or 'image_alt'
    post_no_image = create_doc(post_no_image_data, '/no-image.html')

    mock_base_data = {
      site: @site,
      data_source_for_keys: post_no_image.data,
      data_for_description: post_no_image.data,
      absolute_url: "http://example.com/no-image.html",
      absolute_image_url: nil,
      raw_title: "No Image Post",
      log_output: ""
    }
    mock_prepared_title = "No Image Post Prepared"
    mock_description_html = "" # Assume no description for this case

    captured_card_data = nil
    CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      LiquidUtils.stub :_prepare_display_title, mock_prepared_title do
        CardDataExtractorUtils.stub :extract_description_html, mock_description_html do
          CardRendererUtils.stub :render_card, ->(context:, card_data:) { captured_card_data = card_data; "card_no_image" } do
            Jekyll.stub :logger, @silent_logger_stub do
              ArticleCardUtils.render(post_no_image, @context)
            end
          end
        end
      end
    end
    refute_nil captured_card_data, "CardRendererUtils.render_card should have been called (no image)"
    assert_nil captured_card_data[:image_url]
    assert_equal "Article header image, used for decoration.", captured_card_data[:image_alt] # Default alt
  end

  def test_render_article_card_description_from_excerpt
    post_with_excerpt_data = {
      'title' => 'Excerpt Post',
      # No 'description' front matter, CardDataExtractorUtils.extract_description_html will use excerpt
      'excerpt' => Struct.new(:output).new("<p>Excerpt content.</p>")
    }
    post_with_excerpt = create_doc(post_with_excerpt_data, '/excerpt.html')

    mock_base_data = {
      site: @site,
      data_source_for_keys: post_with_excerpt.data,
      data_for_description: post_with_excerpt.data,
      absolute_url: "http://example.com/excerpt.html",
      absolute_image_url: nil,
      raw_title: "Excerpt Post",
      log_output: ""
    }
    mock_prepared_title = "Excerpt Post Prepared"
    # This is what CardDataExtractorUtils.extract_description_html is stubbed to return
    mock_description_html_from_extractor = "<p>Excerpt content.</p>"

    captured_card_data = nil
    args_to_desc_extractor = nil

    CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      LiquidUtils.stub :_prepare_display_title, mock_prepared_title do
        # Stub extract_description_html to simulate its behavior and capture args
        CardDataExtractorUtils.stub :extract_description_html, ->(source, type:) {
          args_to_desc_extractor = { source: source, type: type }
          mock_description_html_from_extractor
        } do
          CardRendererUtils.stub :render_card, ->(context:, card_data:) { captured_card_data = card_data; "card_with_excerpt" } do
            Jekyll.stub :logger, @silent_logger_stub do
              ArticleCardUtils.render(post_with_excerpt, @context)
            end
          end
        end
      end
    end
    refute_nil captured_card_data, "CardRendererUtils.render_card should have been called (excerpt)"
    assert_equal mock_description_html_from_extractor, captured_card_data[:description_html]
    refute_nil args_to_desc_extractor
    # CardDataExtractorUtils.extract_description_html receives post_with_excerpt.data
    assert_equal post_with_excerpt.data, args_to_desc_extractor[:source]
    assert_equal :article, args_to_desc_extractor[:type]
  end

  def test_render_returns_log_if_base_data_extraction_fails
    # Simulate CardDataExtractorUtils.extract_base_data returning a log message
    mock_failure_log = "<!-- BASE_DATA_EXTRACTION_FAILURE -->"
    # Simulate CardDataExtractorUtils.extract_base_data returning a log and site:nil
    # Also ensure data_source_for_keys is nil to trigger the correct early return in ArticleCardUtils
    CardDataExtractorUtils.stub :extract_base_data, {
      log_output: mock_failure_log,
      site: nil,
      data_source_for_keys: nil,
      data_for_description: nil
    } do
      Jekyll.stub :logger, @silent_logger_stub do
        output = ArticleCardUtils.render(@post_object, @context)
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
      log_output: "<!-- ITEM_INVALID_LOG -->" # This log is from CardDataExtractorUtils
    }
    CardDataExtractorUtils.stub :extract_base_data, mock_base_data_no_item_data do
      Jekyll.stub :logger, @silent_logger_stub do
        output = ArticleCardUtils.render(@post_object, @context)
        # Expect the log message that CardDataExtractorUtils itself generated
        assert_equal "<!-- ITEM_INVALID_LOG -->", output
      end
    end
  end

end
