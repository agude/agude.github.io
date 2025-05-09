# _tests/plugins/utils/json_ld_generators/test_blog_posting_generator.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/utils/json_ld_generators/blog_posting_generator'

class TestBlogPostingLdGenerator < Minitest::Test

  def setup
    @site_config = {
      'url' => 'https://blog.example.com',
      'baseurl' => '',
      'author' => { 'name' => 'Test Author' }
    }
    @site = create_site(@site_config)
    @post_collection = MockCollection.new([], 'posts') # Needed for create_doc
  end

  def test_generate_hash_basic_post
    doc = create_doc(
      { 'layout' => 'post', 'title' => 'My First Post', 'categories' => ['Tech'] },
      '/tech/first-post.html', # url
      '<p>This is the main content.</p>', # content attribute
      '2024-01-15 10:00:00 EST', # date_str
      @post_collection # collection
    )
    expected = {
      "@context" => "https://schema.org",
      "@type" => "BlogPosting",
      "headline" => "My First Post",
      "author" => { "@type" => "Person", "name" => "Test Author" },
      "publisher" => { "@type" => "Person", "name" => "Test Author", "url" => "https://blog.example.com/" },
      "datePublished" => "2024-01-15T10:00:00-05:00",
      "dateModified" => "2024-01-15T10:00:00-05:00",
      "url" => "https://blog.example.com/tech/first-post.html",
      "mainEntityOfPage" => { "@type" => "WebPage", "@id" => "https://blog.example.com/tech/first-post.html" },
      "articleBody" => "This is the main content.", # Cleaned from content attribute
      "keywords" => "Tech"
    }
    assert_equal expected, BlogPostingLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_excerpt_and_description
    doc = create_doc(
      {
        'layout' => 'post', 'title' => 'Post With Excerpt',
        'excerpt_output_override' => '<p>This is the <strong>excerpt</strong>.</p>',
        'description' => 'This front matter description should be ignored for LD description.',
        'tags' => ['Example', 'Test']
      },
      '/test/excerpt-post.html',
      '<p>Full content here.</p>', # content attribute
      '2024-02-10',
      @post_collection
    )
    expected = {
      "@context" => "https://schema.org",
      "@type" => "BlogPosting",
      "headline" => "Post With Excerpt",
      "author" => { "@type" => "Person", "name" => "Test Author" },
      "publisher" => { "@type" => "Person", "name" => "Test Author", "url" => "https://blog.example.com/" },
      "datePublished" => Time.parse('2024-02-10').xmlschema, # Let Time parse handle zone
      "dateModified" => Time.parse('2024-02-10').xmlschema,
      "url" => "https://blog.example.com/test/excerpt-post.html",
      "mainEntityOfPage" => { "@type" => "WebPage", "@id" => "https://blog.example.com/test/excerpt-post.html" },
      "description" => "This is the excerpt.", # From excerpt, cleaned, not truncated (short)
      "articleBody" => "Full content here.", # Cleaned from content attribute
      "keywords" => "Example, Test"
    }
    assert_equal expected, BlogPostingLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_description_no_excerpt
    doc = create_doc(
      {
        'layout' => 'post', 'title' => 'Post With Description',
        'excerpt_output_override' => '', # Empty excerpt
        'description' => ' This is the <strong>description</strong> from front matter. ',
        'categories' => ['Info'], 'tags' => ['Test'] # Both cats and tags
      },
      '/test/desc-post.html',
      '<p>Main body.</p>',
      '2024-03-01',
      @post_collection
    )
    expected = {
      "@context" => "https://schema.org",
      "@type" => "BlogPosting",
      "headline" => "Post With Description",
      "author" => { "@type" => "Person", "name" => "Test Author" },
      "publisher" => { "@type" => "Person", "name" => "Test Author", "url" => "https://blog.example.com/" },
      "datePublished" => Time.parse('2024-03-01').xmlschema,
      "dateModified" => Time.parse('2024-03-01').xmlschema,
      "url" => "https://blog.example.com/test/desc-post.html",
      "mainEntityOfPage" => { "@type" => "WebPage", "@id" => "https://blog.example.com/test/desc-post.html" },
      "description" => "This is the description from front matter.", # From description, cleaned
      "articleBody" => "Main body.",
      "keywords" => "Info, Test" # Combined, unique
    }
    assert_equal expected, BlogPostingLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_image_and_last_modified
    doc = create_doc(
      {
        'layout' => 'post', 'title' => 'Updated Post',
        'image' => '/images/featured.png',
        'last_modified_at' => Time.parse('2024-04-01 12:00:00 UTC') # Explicit Time object
      },
      '/updates/updated-post.html',
      '<p>Updated content.</p>',
      '2024-03-15', # Original date
      @post_collection
    )
    expected = {
      "@context" => "https://schema.org",
      "@type" => "BlogPosting",
      "headline" => "Updated Post",
      "author" => { "@type" => "Person", "name" => "Test Author" },
      "publisher" => { "@type" => "Person", "name" => "Test Author", "url" => "https://blog.example.com/" },
      "datePublished" => Time.parse('2024-03-15').xmlschema,
      "dateModified" => "2024-04-01T12:00:00Z", # Should use last_modified_at
      "image" => { "@type" => "ImageObject", "url" => "https://blog.example.com/images/featured.png" },
      "url" => "https://blog.example.com/updates/updated-post.html",
      "mainEntityOfPage" => { "@type" => "WebPage", "@id" => "https://blog.example.com/updates/updated-post.html" },
      "articleBody" => "Updated content."
      # No description, no keywords - should be omitted
    }
    assert_equal expected, BlogPostingLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_long_description_truncation
    long_desc = "Word " * 60 # 60 words
    doc = create_doc(
      {
        'layout' => 'post', 'title' => 'Long Desc Post',
        'description' => "<p>#{long_desc}</p>"
      },
      '/test/long-desc.html',
      'Body', '2024-01-01', @post_collection
    )
    expected_truncated_desc = ("Word " * 49 + "Word...") # 50th word replaced by ...

    result_hash = BlogPostingLdGenerator.generate_hash(doc, @site)
    assert_equal expected_truncated_desc, result_hash["description"]
    assert result_hash.key?("headline") # Check other keys still exist
  end

  def test_generate_hash_minimal_data
    # Create the doc. It will have a default date from Time.now via create_doc
    doc = create_doc(
      { 'layout' => 'post', 'title' => 'Minimal' }, # Only title
      '/minimal.html',
      '', # Empty content attribute
      nil, # This will default to Time.now in create_doc
      @post_collection
    )

    actual_hash = BlogPostingLdGenerator.generate_hash(doc, @site)

    # Expected structure without specific date values
    expected_structure = {
      "@context" => "https://schema.org",
      "@type" => "BlogPosting",
      "headline" => "Minimal",
      "author" => { "@type" => "Person", "name" => "Test Author" },
      "publisher" => { "@type" => "Person", "name" => "Test Author", "url" => "https://blog.example.com/" },
      "url" => "https://blog.example.com/minimal.html",
      "mainEntityOfPage" => { "@type" => "WebPage", "@id" => "https://blog.example.com/minimal.html" }
      # datePublished and dateModified will be present due to create_doc default
    }

    # Check the static parts
    expected_structure.each do |key, value|
      assert_equal value, actual_hash[key.to_s], "Mismatch for key '#{key}'"
    end

    # Check for the presence and format of date fields
    assert actual_hash.key?("datePublished"), "Expected datePublished to be present"
    assert actual_hash.key?("dateModified"), "Expected dateModified to be present"

    # Validate XML Schema format (basic regex check)
    xml_schema_date_regex = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$/
    assert_match xml_schema_date_regex, actual_hash["datePublished"]
    assert_match xml_schema_date_regex, actual_hash["dateModified"]

    # Ensure no other unexpected keys are present (optional, but good for strictness)
    expected_keys = expected_structure.keys.map(&:to_s) + ["datePublished", "dateModified"]
    # Sort keys for consistent comparison
    assert_equal expected_keys.sort, actual_hash.keys.sort, "Hash keys do not match expected set"
  end

end
