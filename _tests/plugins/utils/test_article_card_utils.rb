# _tests/plugins/utils/test_article_card_utils.rb
require_relative '../../test_helper'
# ArticleCardUtils is loaded by test_helper

class TestArticleCardUtils < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({}, { site: @site, page: create_doc({}, '/current.html') })
    @post_object = create_doc({
      'title' => 'My Article Title',
      'image' => '/images/article.jpg',
      'image_alt' => 'Custom Alt',
      'description' => 'Front matter description.'
    }, '/article.html')

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
      def logger.log_level=(level); end;    def logger.progname=(name); end
    end
  end

  def test_render_article_card_success
    mock_base_data = {
      site: @site,
      data: @post_object.data, # Pass the actual data hash
      absolute_url: "http://example.com/article.html",
      absolute_image_url: "http://example.com/images/article.jpg",
      raw_title: "My Article Title",
      log_output: ""
    }
    mock_prepared_title = "My Prepared Article Title" # With typography
    mock_description_html = "Front matter description." # Assume already processed/stripped

    expected_card_data_to_renderer = {
      base_class: "article-card",
      url: mock_base_data[:absolute_url],
      image_url: mock_base_data[:absolute_image_url],
      image_alt: "Custom Alt",
      image_div_class: "card-image",
      title_html: "<strong>#{mock_prepared_title}</strong>",
      description_html: mock_description_html,
      description_wrapper_html_open: "<br>\n",
      description_wrapper_html_close: "",
      extra_elements_html: []
    }

    captured_card_data = nil

    CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      LiquidUtils.stub :_prepare_display_title, mock_prepared_title do
        CardDataExtractorUtils.stub :extract_description_html, mock_description_html do
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
    post_no_image = create_doc({ 'title' => 'No Image Post' }, '/no-image.html')
    mock_base_data = {
      site: @site, data: post_no_image.data, absolute_url: "/no-image.html",
      absolute_image_url: nil, raw_title: "No Image Post", log_output: ""
    }
    mock_prepared_title = "No Image Post Prepared"
    mock_description_html = "" # No description for this test case

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
    assert_nil captured_card_data[:image_url]
    assert_equal "Article header image, used for decoration.", captured_card_data[:image_alt] # Default alt
  end

  def test_render_article_card_description_from_excerpt
    post_with_excerpt = create_doc({
      'title' => 'Excerpt Post',
      'excerpt' => Struct.new(:output).new("<p>Excerpt content.</p>") # No 'description' front matter
    }, '/excerpt.html')

    mock_base_data = {
      site: @site, data: post_with_excerpt.data, absolute_url: "/excerpt.html",
      absolute_image_url: nil, raw_title: "Excerpt Post", log_output: ""
    }
    mock_prepared_title = "Excerpt Post Prepared"
    # extract_description_html (type: :article) will get this from excerpt.output
    mock_description_html_from_extractor = "<p>Excerpt content.</p>"

    captured_card_data = nil
    CardDataExtractorUtils.stub :extract_base_data, mock_base_data do
      LiquidUtils.stub :_prepare_display_title, mock_prepared_title do
        # Stub extract_description_html to simulate its behavior for articles
        CardDataExtractorUtils.stub :extract_description_html, ->(data_hash, type:) {
          assert_equal :article, type
          assert_equal post_with_excerpt.data, data_hash # Ensure it gets the correct data hash
          mock_description_html_from_extractor # Return the expected processed excerpt
        } do
          CardRendererUtils.stub :render_card, ->(context:, card_data:) { captured_card_data = card_data; "card_with_excerpt" } do
            Jekyll.stub :logger, @silent_logger_stub do
              ArticleCardUtils.render(post_with_excerpt, @context)
            end
          end
        end
      end
    end
    assert_equal mock_description_html_from_extractor, captured_card_data[:description_html]
  end

  def test_render_returns_log_if_base_data_extraction_fails
    # Simulate CardDataExtractorUtils.extract_base_data returning a log message
    mock_failure_log = "<!-- BASE_DATA_EXTRACTION_FAILURE -->"
    CardDataExtractorUtils.stub :extract_base_data, { log_output: mock_failure_log, site: nil } do
      Jekyll.stub :logger, @silent_logger_stub do
        output = ArticleCardUtils.render(@post_object, @context)
        assert_equal mock_failure_log, output
      end
    end
  end

  def test_render_returns_log_if_base_data_has_no_item_data
    mock_base_data_no_item_data = {
      site: @site, data: nil, # Simulate item_object was invalid but site was found
      absolute_url: "/some-url/", absolute_image_url: nil, raw_title: "Some Title",
      log_output: "<!-- ITEM_INVALID_LOG -->" # Log from extractor about invalid item
    }
    CardDataExtractorUtils.stub :extract_base_data, mock_base_data_no_item_data do
      Jekyll.stub :logger, @silent_logger_stub do
        output = ArticleCardUtils.render(@post_object, @context) # @post_object is just a placeholder here
        assert_equal "<!-- ITEM_INVALID_LOG -->", output
      end
    end
  end

end
