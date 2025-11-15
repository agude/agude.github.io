# _tests/plugins/utils/test_json_ld_utils.rb
require_relative '../../test_helper'
# JsonLdUtils is loaded via test_helper (assuming you'll add it there)

class TestJsonLdUtils < Minitest::Test
  def setup
    @site_config_full = {
      'url' => 'https://example.com',
      'baseurl' => '/blog',
      'author' => { 'name' => 'Site Author Name' }
    }
    @site_config_no_author = {
      'url' => 'https://example.com',
      'baseurl' => ''
    }
    @mock_site_full = create_site(@site_config_full)
    @mock_site_no_author = create_site(@site_config_no_author)

    # Mock document for excerpt/content testing
    @mock_doc_data = {
      'title' => 'Test Doc',
      'description' => 'Front matter description.',
      'excerpt' => Struct.new(:output).new('<p>Excerpt <em>HTML</em> content.</p>'), # Mock Excerpt object
      'content' => '<div>Full <span>HTML</span> page content.</div>'
    }
    @mock_document = create_doc(@mock_doc_data)
  end

  # --- Tests for build_site_person_entity ---
  def test_build_site_person_entity_with_name
    expected = { '@type' => 'Person', 'name' => 'Site Author Name' }
    assert_equal expected, JsonLdUtils.build_site_person_entity(@mock_site_full)
  end

  def test_build_site_person_entity_with_name_and_url
    expected = {
      '@type' => 'Person',
      'name' => 'Site Author Name',
      'url' => 'https://example.com/blog/' # UrlUtils.absolute_url("", @mock_site_full)
    }
    assert_equal expected, JsonLdUtils.build_site_person_entity(@mock_site_full, include_site_url: true)
  end

  def test_build_site_person_entity_no_author_name
    assert_nil JsonLdUtils.build_site_person_entity(@mock_site_no_author)
  end

  def test_build_site_person_entity_empty_author_name
    site_empty_author = create_site({ 'author' => { 'name' => '  ' } })
    assert_nil JsonLdUtils.build_site_person_entity(site_empty_author)
  end

  # --- Tests for build_document_person_entity ---
  def test_build_document_person_entity_with_name
    expected = { '@type' => 'Person', 'name' => 'Book Author Name' }
    assert_equal expected, JsonLdUtils.build_document_person_entity('Book Author Name')
  end

  def test_build_document_person_entity_empty_name
    assert_nil JsonLdUtils.build_document_person_entity('')
    assert_nil JsonLdUtils.build_document_person_entity('   ')
  end

  def test_build_document_person_entity_nil_name
    assert_nil JsonLdUtils.build_document_person_entity(nil)
  end

  # --- Tests for build_image_object_entity ---
  def test_build_image_object_entity_valid_path
    expected = {
      '@type' => 'ImageObject',
      'url' => 'https://example.com/blog/images/pic.jpg' # UrlUtils.absolute_url("images/pic.jpg", @mock_site_full)
    }
    assert_equal expected, JsonLdUtils.build_image_object_entity('images/pic.jpg', @mock_site_full)
  end

  def test_build_image_object_entity_empty_path
    assert_nil JsonLdUtils.build_image_object_entity('', @mock_site_full)
    assert_nil JsonLdUtils.build_image_object_entity('  ', @mock_site_full)
  end

  def test_build_image_object_entity_nil_path
    assert_nil JsonLdUtils.build_image_object_entity(nil, @mock_site_full)
  end

  # --- Tests for extract_descriptive_text ---
  def test_extract_descriptive_text_priority_excerpt
    # Excerpt exists and is primary
    result = JsonLdUtils.extract_descriptive_text(
      @mock_document,
      field_priority: %w[excerpt description content]
    )
    assert_equal 'Excerpt HTML content.', result # Cleaned from <p>Excerpt <em>HTML</em> content.</p>
  end

  def test_extract_descriptive_text_priority_description
    # Make excerpt empty for this test
    doc_no_excerpt_output = create_doc(@mock_doc_data.merge('excerpt' => Struct.new(:output).new('')))
    result = JsonLdUtils.extract_descriptive_text(
      doc_no_excerpt_output,
      field_priority: %w[excerpt description content]
    )
    assert_equal 'Front matter description.', result
  end

  def test_extract_descriptive_text_priority_content
    doc_no_excerpt_desc = create_doc(@mock_doc_data.merge(
                                       'excerpt' => Struct.new(:output).new(''),
                                       'description' => ''
                                     ))
    result = JsonLdUtils.extract_descriptive_text(
      doc_no_excerpt_desc,
      field_priority: %w[excerpt description content]
    )
    assert_equal 'Full HTML page content.', result # Cleaned from <div>Full <span>HTML</span> page content.</div>
  end

  def test_extract_descriptive_text_only_content_specified
    result = JsonLdUtils.extract_descriptive_text(
      @mock_document, # Has excerpt and description, but we only ask for content
      field_priority: ['content']
    )
    assert_equal 'Full HTML page content.', result
  end

  def test_extract_descriptive_text_no_matching_fields
    doc_empty = create_doc({ 'title' => 'Empty Doc', 'excerpt' => Struct.new(:output).new(nil), 'description' => nil,
                             'content' => nil })
    result = JsonLdUtils.extract_descriptive_text(
      doc_empty,
      field_priority: %w[excerpt description content]
    )
    assert_nil result
  end

  def test_extract_descriptive_text_with_truncation
    result = JsonLdUtils.extract_descriptive_text(
      @mock_document, # Uses excerpt: "Excerpt HTML content." (3 words)
      field_priority: ['excerpt'],
      truncate_options: { words: 2, omission: '...' }
    )
    assert_equal 'Excerpt HTML...', result
  end

  def test_extract_descriptive_text_no_truncation_needed
    result = JsonLdUtils.extract_descriptive_text(
      @mock_document, # Uses excerpt: "Excerpt HTML content." (3 words)
      field_priority: ['excerpt'],
      truncate_options: { words: 5, omission: '...' }
    )
    assert_equal 'Excerpt HTML content.', result # Original cleaned text
  end

  def test_extract_descriptive_text_nil_truncate_options
    result = JsonLdUtils.extract_descriptive_text(
      @mock_document,
      field_priority: ['excerpt'],
      truncate_options: nil # Explicitly nil
    )
    assert_equal 'Excerpt HTML content.', result
  end

  # --- Tests for build_rating_entity ---
  def test_build_rating_entity_valid
    expected = { '@type' => 'Rating', 'ratingValue' => '4', 'bestRating' => '5', 'worstRating' => '1' }
    assert_equal expected, JsonLdUtils.build_rating_entity(4)
    assert_equal expected, JsonLdUtils.build_rating_entity('4')
  end

  def test_build_rating_entity_custom_best_worst
    expected = { '@type' => 'Rating', 'ratingValue' => '3', 'bestRating' => '10', 'worstRating' => '0' }
    assert_equal expected, JsonLdUtils.build_rating_entity(3, best_rating: '10', worst_rating: '0')
  end

  def test_build_rating_entity_invalid_or_zero
    assert_nil JsonLdUtils.build_rating_entity(0)
    assert_nil JsonLdUtils.build_rating_entity(-1)
    assert_nil JsonLdUtils.build_rating_entity('abc')
    assert_nil JsonLdUtils.build_rating_entity(nil)
  end

  # --- Tests for build_book_series_entity ---
  def test_build_book_series_entity_with_name_and_position
    expected = { '@type' => 'BookSeries', 'name' => 'The Expanse', 'position' => '3' }
    assert_equal expected, JsonLdUtils.build_book_series_entity(' The Expanse ', '3')
  end

  def test_build_book_series_entity_with_name_only
    expected = { '@type' => 'BookSeries', 'name' => 'Dune' }
    assert_equal expected, JsonLdUtils.build_book_series_entity('Dune')
    assert_equal expected, JsonLdUtils.build_book_series_entity('Dune', 0) # Position 0 is invalid
    assert_equal expected, JsonLdUtils.build_book_series_entity('Dune', 'abc') # Invalid position
  end

  def test_build_book_series_entity_empty_or_nil_name
    assert_nil JsonLdUtils.build_book_series_entity('', '1')
    assert_nil JsonLdUtils.build_book_series_entity('   ', '1')
    assert_nil JsonLdUtils.build_book_series_entity(nil, '1')
  end

  # --- Tests for cleanup_data_hash! ---
  def test_cleanup_data_hash_removes_nil_and_empty
    data = {
      'name' => 'Test',
      'description' => '',
      'keywords' => [],
      'author' => nil,
      'image' => 'img.jpg',
      'nested' => {
        'prop1' => 'value',
        'prop2' => nil,
        'prop3' => ''
      },
      'valid_empty_array_prop' => ['item'], # Should stay
      'empty_array_prop_to_remove' => [] # Should be removed
    }
    expected = {
      'name' => 'Test',
      'image' => 'img.jpg',
      'nested' => {
        'prop1' => 'value'
      },
      'valid_empty_array_prop' => ['item']
    }
    assert_equal expected, JsonLdUtils.cleanup_data_hash!(data)
  end

  def test_cleanup_data_hash_empty_hash
    data = {}
    expected = {}
    assert_equal expected, JsonLdUtils.cleanup_data_hash!(data)
  end

  def test_cleanup_data_hash_all_empty
    data = { 'a' => nil, 'b' => '', 'c' => [] }
    expected = {}
    assert_equal expected, JsonLdUtils.cleanup_data_hash!(data)
  end

  def test_cleanup_data_hash_no_changes_needed
    data = { 'name' => 'Test', 'image' => 'img.jpg' }
    expected = { 'name' => 'Test', 'image' => 'img.jpg' }
    # The method modifies in place, so we compare original to expected after call
    JsonLdUtils.cleanup_data_hash!(data)
    assert_equal expected, data
  end

  def test_cleanup_data_hash_deeply_nested
    data = {
      'level1' => {
        'name' => 'L1',
        'level2' => {
          'desc' => '',
          'level3' => {
            'val' => 'v3',
            'empty_arr' => []
          },
          'other_l2' => nil
        },
        'arr' => ['a']
      },
      'notes' => ''
    }
    expected = {
      'level1' => {
        'name' => 'L1',
        'level2' => {
          'level3' => {
            'val' => 'v3'
          }
        },
        'arr' => ['a']
      }
    }
    assert_equal expected, JsonLdUtils.cleanup_data_hash!(data)
  end
end
