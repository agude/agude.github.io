# frozen_string_literal: true

require_relative '../../../test_helper'

# Shared card extraction for document, Drop, and invalid inputs.
class TestCardDataExtractorUtils < Minitest::Test
  Extractor = Jekyll::UI::Cards::CardDataExtractorUtils

  def setup
    @site = create_site({ 'url' => 'http://example.com' })
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current.html' }) })
  end

  def test_extract_base_data_hash_form_image_raises_naming_the_file
    doc = create_doc(
      {
        'path' => '_posts/2024-01-01-a.md',
        'image' => { 'path' => '/assets/image.png', 'alt' => 'Alt' },
      },
      '/a/',
    )

    error = assert_raises(Jekyll::Errors::FatalException) { Extractor.extract_base_data(doc, @context) }
    assert_includes error.message, '_posts/2024-01-01-a.md'
  end

  def test_extract_base_data_item_empty_string_title_uses_default
    doc = create_doc({ 'title' => '  ' }, '/empty-title.html')
    data, diagnostic = Extractor.extract_base_data(doc, @context, default_title: 'Default title')

    assert_equal 'Default title', data[:title]
    assert_empty diagnostic
  end

  def test_extract_base_data_item_empty_url_uses_hash_symbol
    data, = Extractor.extract_base_data(create_doc({}, ''), @context)

    assert_equal '#', data[:url]
  end

  def test_extract_base_data_invalid_item_object_does_not_respond_to_data
    @site.config['plugin_logging']['TEST_CARD'] = true
    invalid_inputs = ['not a document', Struct.new(:data).new({}), nil]

    Jekyll.stub :logger, silent_logger do
      invalid_inputs.each do |item|
        data, diagnostic = Extractor.extract_base_data(item, @context, log_tag_type: 'TEST_CARD')

        assert_nil data
        assert_match(/TEST_CARD_FAILURE: Reason='Invalid item_object: .*SourcePage='current.html'/, diagnostic)
      end
    end
  end

  def test_extract_base_data_missing_context
    Jekyll.stub :logger, silent_logger do
      [nil, create_context].each do |context|
        data, diagnostic = Extractor.extract_base_data(create_doc, context)

        assert_nil data
        assert_empty diagnostic
      end
    end
  end

  def test_extract_description_html_handles_nil_data_hash
    assert_equal '', Extractor.extract_description_html(nil, type: :article)
    assert_equal '', Extractor.extract_description_html(nil, type: :book)
  end

  def test_extract_description_html_excerpt_as_plain_string
    [nil, '  ', 'Plain excerpt'].each do |output|
      [output, Struct.new(:output).new(output)].each do |excerpt|
        %i[article book].each do |type|
          assert_equal output.to_s.strip, Extractor.extract_description_html({ 'excerpt' => excerpt }, type: type)
        end
      end
    end
  end

  def test_extract_description_html_unknown_type_returns_empty
    data = { 'description' => 'Description', 'excerpt' => 'Excerpt' }

    assert_equal '', Extractor.extract_description_html(data, type: :unknown)
    assert_equal '', Extractor.extract_description_html(data, type: nil)
  end

  def test_extract_base_data_with_drop_object
    drop = Jekyll::Drops::DocumentDrop.new(create_doc({ 'title' => 'Drop Title', 'image' => 'drop.jpg' }, '/drop/'))
    data, diagnostic = Extractor.extract_base_data(drop, @context)

    assert_empty diagnostic
    assert_equal 'Drop Title', data[:title]
    assert_equal 'http://example.com/drop/', data[:url]
    assert_equal 'http://example.com/drop.jpg', data[:image_url]
  end
end
