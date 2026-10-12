# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/seo/generators/blog_posting_generator'
require_relative '../../../../_plugins/src/seo/generators/person_generator'
require_relative '../../../../_plugins/src/seo/generators/profile_page_generator'

# Tests for Jekyll::SEO::Generators::BlogPostingLdGenerator module.
#
# Verifies that the generator correctly creates JSON-LD structured data for blog posts.
class TestBlogPostingLdGenerator < Minitest::Test
  # Verbatim book link with hover preview, from the built
  # /books/a_fire_upon_the_deep/ page (BookPreviewRenderer output).
  BLINDSIGHT_LINK_WITH_PREVIEW = '<a href="/books/blindsight/"><cite class="book-title">Blindsight</cite><!--book-preview--><span class="book-link-preview" aria-hidden="true" hidden=""><img class="book-link-preview-cover" src="/books/covers/blindsight.jpg" alt="Cover of Blindsight" loading="lazy" decoding="async" /><span class="book-link-preview-text"><span class="book-link-preview-title">Blindsight</span><span class="book-link-preview-author">by Peter Watts</span><span class="book-rating star-rating-5" role="img" aria-label="Rating: 5 out of 5 stars. Masterpiece — I loved it" title="Masterpiece — I loved it"><span class="book_star full_star" aria-hidden="true">★</span><span class="book_star full_star" aria-hidden="true">★</span><span class="book_star full_star" aria-hidden="true">★</span><span class="book_star full_star" aria-hidden="true">★</span><span class="book_star full_star" aria-hidden="true">★</span></span><span class="book-link-preview-series"><span class="book-series">Firefall</span> #1</span></span><span class="book-link-preview-lede"><cite class="book-title">Blindsight</cite> is a hard sci-fi novel about first contact with aliens in the near future. A crew of four transhumans and a vampire are sent on a spaceship to investigate an anomaly in the solar system after a swarm of alien probes scan Earth.</span></span><!--/book-preview--></a>'

  def setup
    @site_config = {
      'url' => 'https://blog.example.com',
      'baseurl' => '',
      'author' => { 'name' => 'Test Author', 'url' => '/resume/' },
    }
    @site = create_site(@site_config)
    @post_collection = MockCollection.new([], 'posts')
  end

  def test_generate_hash_basic_post
    doc = create_basic_post_doc
    expected = build_expected_basic_post_hash
    assert_equal expected, Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, @site)
  end

  # The meta description tag prefers front-matter description over the
  # excerpt. JSON-LD uses the same source priority. The outputs are not
  # required to be identical: JSON-LD truncates to 50 words and the meta
  # tag applies typography.
  def test_generate_hash_with_excerpt_and_description
    doc = create_excerpt_and_description_doc
    expected = build_expected_excerpt_hash
    assert_equal expected, Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_description_no_excerpt
    doc = create_description_no_excerpt_doc
    expected = build_expected_description_hash
    assert_equal expected, Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_image_and_last_modified
    doc = create_image_and_modified_doc
    expected = build_expected_image_modified_hash
    assert_equal expected, Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, @site)
  end

  def test_generate_hash_with_long_description_truncation
    doc = create_long_description_doc
    result_hash = Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, @site)
    expected_truncated_desc = build_expected_truncated_description
    assert_equal expected_truncated_desc, result_hash['description']
    assert result_hash.key?('headline')
  end

  def test_generate_hash_minimal_data
    doc = create_minimal_doc
    actual_hash = Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, @site)
    assert_minimal_hash_structure(actual_hash)
    assert_date_fields_present_and_valid(actual_hash)
    assert_expected_keys_only(actual_hash)
  end

  def test_description_falls_back_to_excerpt_without_front_matter
    doc = create_doc(
      { 'layout' => 'post', 'title' => 'Post', 'excerpt_output_override' => '<p>Only the excerpt.</p>' },
      '/blog/post/',
      '<p>Body.</p>',
      '2024-01-01',
      @post_collection,
    )
    result = Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, @site)
    assert_equal 'Only the excerpt.', result['description']
  end

  def test_description_falls_back_to_excerpt_when_front_matter_blank
    doc = create_doc(
      {
        'layout' => 'post',
        'title' => 'Post',
        'excerpt_output_override' => '<p>Only the excerpt.</p>',
        'description' => "   \n",
      },
      '/blog/post/',
      '<p>Body.</p>',
      '2024-01-01',
      @post_collection,
    )
    result = Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, @site)
    assert_equal 'Only the excerpt.', result['description']
  end

  def test_article_body_and_word_count_exclude_book_link_preview
    doc = create_doc(
      { 'layout' => 'post', 'title' => 'Favorite Books' },
      '/blog/favorites/',
      "<p>My favorite is #{BLINDSIGHT_LINK_WITH_PREVIEW}.</p>",
      '2024-01-01',
      @post_collection,
    )
    result = Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, @site)
    assert_equal 'My favorite is Blindsight.', result['articleBody']
    assert_equal 4, result['wordCount']
  end

  # Titles may contain <br> and &nbsp; for on-page display
  # (TypographyUtils::ALLOWED_TITLE_ENTITIES). JSON-LD is plain text.
  def test_headline_is_plain_text
    doc = create_doc(
      { 'layout' => 'post', 'title' => 'Clever(ly&nbsp;Terrible)<br>Code' },
      '/blog/clever/',
      '<p>Body.</p>',
      '2024-01-01',
      @post_collection,
    )
    result = Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, @site)
    assert_equal "Clever(ly\u00A0Terrible) Code", result['headline']
  end

  def test_author_and_publisher_share_site_owner_id
    site = create_site(@site_config.merge('author' => { 'name' => 'Test Author', 'url' => '/resume/' }))
    doc = create_basic_post_doc
    result = Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, site)

    owner = {
      '@type' => 'Person',
      '@id' => 'https://blog.example.com/resume/#person',
      'url' => 'https://blog.example.com/resume/',
      'name' => 'Test Author',
    }
    assert_equal owner, result['author']
    assert_equal owner, result['publisher']
  end

  # The resume's mainEntity and the linktree's mainEntity are the site
  # owner every post credits as author. All must share one @id so
  # consumers merge them into one Person.
  def test_site_owner_id_matches_resume_and_linktree
    site = create_site(@site_config.merge('author' => { 'name' => 'Test Author', 'url' => '/resume/' }))
    resume = create_doc({ 'layout' => 'resume', 'title' => 'Resume' }, '/resume/', 'Resume content', nil, nil)
    linktree = create_doc({ 'layout' => 'default', 'title' => 'Linktree' }, '/linktree/', 'Links', nil, nil)

    post_author = Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(create_basic_post_doc, site)['author']
    resume_person = Jekyll::SEO::Generators::PersonLdGenerator.generate_hash(resume, site)['mainEntity']
    linktree_person = Jekyll::SEO::Generators::ProfilePageLdGenerator.generate_hash(linktree, site)['mainEntity']

    assert_equal 'https://blog.example.com/resume/#person', post_author['@id']
    assert_equal post_author['@id'], resume_person['@id']
    assert_equal post_author['@id'], linktree_person['@id']
    assert_equal post_author['url'], resume_person['url']
    assert_equal post_author['url'], linktree_person['url']
  end

  private

  def create_basic_post_doc
    create_doc(
      { 'layout' => 'post', 'title' => 'My First Post', 'categories' => ['Tech'] },
      '/tech/first-post.html',
      '<p>This is the main content.</p>',
      '2024-01-15 10:00:00 EST',
      @post_collection,
    )
  end

  def build_expected_basic_post_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'BlogPosting',
      'license' => 'https://creativecommons.org/licenses/by-sa/4.0/',
      'headline' => 'My First Post',
      'author' => { '@type' => 'Person', 'name' => 'Test Author', '@id' => 'https://blog.example.com/resume/#person', 'url' => 'https://blog.example.com/resume/' },
      'publisher' => { '@type' => 'Person', 'name' => 'Test Author', '@id' => 'https://blog.example.com/resume/#person', 'url' => 'https://blog.example.com/resume/' },
      'datePublished' => '2024-01-15T10:00:00-05:00',
      'dateModified' => '2024-01-15T10:00:00-05:00',
      'url' => 'https://blog.example.com/tech/first-post.html',
      'mainEntityOfPage' => {
        '@type' => 'WebPage',
        '@id' => 'https://blog.example.com/tech/first-post.html',
      },
      'articleBody' => 'This is the main content.',
      'wordCount' => 5,
      'keywords' => 'Tech',
    }
  end

  def create_excerpt_and_description_doc
    create_doc(
      {
        'layout' => 'post',
        'title' => 'Post With Excerpt',
        'excerpt_output_override' => '<p>This is the <strong>excerpt</strong>.</p>',
        'description' => 'Hand-written description wins over the excerpt.',
        'tags' => %w[Example Test],
      },
      '/test/excerpt-post.html',
      '<p>Full content here.</p>',
      '2024-02-10',
      @post_collection,
    )
  end

  def build_expected_excerpt_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'BlogPosting',
      'license' => 'https://creativecommons.org/licenses/by-sa/4.0/',
      'headline' => 'Post With Excerpt',
      'author' => { '@type' => 'Person', 'name' => 'Test Author', '@id' => 'https://blog.example.com/resume/#person', 'url' => 'https://blog.example.com/resume/' },
      'publisher' => { '@type' => 'Person', 'name' => 'Test Author', '@id' => 'https://blog.example.com/resume/#person', 'url' => 'https://blog.example.com/resume/' },
      'datePublished' => Time.parse('2024-02-10').xmlschema,
      'dateModified' => Time.parse('2024-02-10').xmlschema,
      'url' => 'https://blog.example.com/test/excerpt-post.html',
      'mainEntityOfPage' => {
        '@type' => 'WebPage',
        '@id' => 'https://blog.example.com/test/excerpt-post.html',
      },
      'description' => 'Hand-written description wins over the excerpt.',
      'articleBody' => 'Full content here.',
      'wordCount' => 3,
      'keywords' => 'Example, Test',
    }
  end

  def create_description_no_excerpt_doc
    create_doc(
      {
        'layout' => 'post',
        'title' => 'Post With Description',
        'excerpt_output_override' => '',
        'description' => ' This is the <strong>description</strong> from front matter. ',
        'categories' => ['Info'],
        'tags' => ['Test'],
      },
      '/test/desc-post.html',
      '<p>Main body.</p>',
      '2024-03-01',
      @post_collection,
    )
  end

  def build_expected_description_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'BlogPosting',
      'license' => 'https://creativecommons.org/licenses/by-sa/4.0/',
      'headline' => 'Post With Description',
      'author' => { '@type' => 'Person', 'name' => 'Test Author', '@id' => 'https://blog.example.com/resume/#person', 'url' => 'https://blog.example.com/resume/' },
      'publisher' => { '@type' => 'Person', 'name' => 'Test Author', '@id' => 'https://blog.example.com/resume/#person', 'url' => 'https://blog.example.com/resume/' },
      'datePublished' => Time.parse('2024-03-01').xmlschema,
      'dateModified' => Time.parse('2024-03-01').xmlschema,
      'url' => 'https://blog.example.com/test/desc-post.html',
      'mainEntityOfPage' => {
        '@type' => 'WebPage',
        '@id' => 'https://blog.example.com/test/desc-post.html',
      },
      'description' => 'This is the description from front matter.',
      'articleBody' => 'Main body.',
      'wordCount' => 2,
      'keywords' => 'Info, Test',
    }
  end

  def create_image_and_modified_doc
    create_doc(
      {
        'layout' => 'post',
        'title' => 'Updated Post',
        'image' => '/images/featured.png',
        'last_modified_at' => Time.parse('2024-04-01 12:00:00 UTC'),
      },
      '/updates/updated-post.html',
      '<p>Updated content.</p>',
      '2024-03-15',
      @post_collection,
    )
  end

  def build_expected_image_modified_hash
    {
      '@context' => 'https://schema.org',
      '@type' => 'BlogPosting',
      'license' => 'https://creativecommons.org/licenses/by-sa/4.0/',
      'headline' => 'Updated Post',
      'author' => { '@type' => 'Person', 'name' => 'Test Author', '@id' => 'https://blog.example.com/resume/#person', 'url' => 'https://blog.example.com/resume/' },
      'publisher' => { '@type' => 'Person', 'name' => 'Test Author', '@id' => 'https://blog.example.com/resume/#person', 'url' => 'https://blog.example.com/resume/' },
      'datePublished' => Time.parse('2024-03-15').xmlschema,
      'dateModified' => '2024-04-01T12:00:00Z',
      'image' => { '@type' => 'ImageObject', 'url' => 'https://blog.example.com/images/featured.png' },
      'url' => 'https://blog.example.com/updates/updated-post.html',
      'mainEntityOfPage' => {
        '@type' => 'WebPage',
        '@id' => 'https://blog.example.com/updates/updated-post.html',
      },
      'articleBody' => 'Updated content.',
      'wordCount' => 2,
    }
  end

  def create_long_description_doc
    long_desc = 'Word ' * 60
    create_doc(
      {
        'layout' => 'post',
        'title' => 'Long Desc Post',
        'description' => "<p>#{long_desc}</p>",
      },
      '/test/long-desc.html',
      'Body',
      '2024-01-01',
      @post_collection,
    )
  end

  def build_expected_truncated_description
    "#{'Word ' * 49}Word..."
  end

  def create_minimal_doc
    create_doc(
      { 'layout' => 'post', 'title' => 'Minimal' },
      '/minimal.html',
      '',
      nil,
      @post_collection,
    )
  end

  def assert_minimal_hash_structure(actual_hash)
    expected_structure = {
      '@context' => 'https://schema.org',
      '@type' => 'BlogPosting',
      'license' => 'https://creativecommons.org/licenses/by-sa/4.0/',
      'headline' => 'Minimal',
      'author' => { '@type' => 'Person', 'name' => 'Test Author', '@id' => 'https://blog.example.com/resume/#person', 'url' => 'https://blog.example.com/resume/' },
      'publisher' => { '@type' => 'Person', 'name' => 'Test Author', '@id' => 'https://blog.example.com/resume/#person', 'url' => 'https://blog.example.com/resume/' },
      'url' => 'https://blog.example.com/minimal.html',
      'mainEntityOfPage' => { '@type' => 'WebPage', '@id' => 'https://blog.example.com/minimal.html' },
    }

    expected_structure.each do |key, value|
      assert_equal value, actual_hash[key.to_s], "Mismatch for key '#{key}'"
    end
  end

  def assert_date_fields_present_and_valid(actual_hash)
    assert actual_hash.key?('datePublished'), 'Expected datePublished to be present'
    assert actual_hash.key?('dateModified'), 'Expected dateModified to be present'

    xml_schema_date_regex = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$/
    assert_match xml_schema_date_regex, actual_hash['datePublished']
    assert_match xml_schema_date_regex, actual_hash['dateModified']
  end

  def assert_expected_keys_only(actual_hash)
    expected_keys = [
      '@context',
      '@type',
      'license',
      'headline',
      'author',
      'publisher',
      'url',
      'mainEntityOfPage',
      'datePublished',
      'dateModified',
    ]
    assert_equal expected_keys.sort, actual_hash.keys.sort, 'Hash keys do not match expected set'
  end

  def test_generate_hash_with_markdown_alternate_href_includes_encoding
    doc = create_doc(
      {
        'layout' => 'post',
        'title' => 'Post With Markdown',
        'markdown_alternate_href' => '/tech/markdown-post.md',
      },
      '/tech/markdown-post.html',
      '<p>Content</p>',
      '2024-01-15',
      @post_collection,
    )
    result = Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, @site)
    expected_encoding = {
      '@type' => 'MediaObject',
      'encodingFormat' => 'text/markdown',
      'contentUrl' => 'https://blog.example.com/tech/markdown-post.md',
    }
    assert_equal expected_encoding, result['encoding']
  end

  def test_generate_hash_without_markdown_alternate_href_omits_encoding
    doc = create_basic_post_doc
    result = Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, @site)
    refute result.key?('encoding'), 'No markdown_alternate_href should omit encoding'
  end

  def test_generate_hash_with_empty_title_omits_headline
    # Tests line 36: `if headline && !headline.strip.empty?` else branch
    doc = create_doc(
      { 'layout' => 'post', 'title' => '   ' },
      '/empty-title.html',
      '<p>Content</p>',
      '2024-01-15',
      @post_collection,
    )

    result = Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, @site)
    refute result.key?('headline'), 'Empty title should not produce headline'
  end

  def test_generate_hash_without_site_author_omits_author_fields
    # Tests lines 41 and 44: `if author_entity` and `if publisher_entity` else branches
    site_no_author = create_site({ 'url' => 'https://example.com', 'baseurl' => '' })
    doc = create_doc(
      { 'layout' => 'post', 'title' => 'Test' },
      '/test.html',
      '<p>Content</p>',
      '2024-01-15',
      @post_collection,
    )

    result = Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, site_no_author)
    refute result.key?('author'), 'No site author should omit author'
    refute result.key?('publisher'), 'No site author should omit publisher'
  end

  def test_generate_hash_without_date_omits_date_fields
    # Tests line 48: `return unless document.date` - no date on document
    doc = create_doc(
      { 'layout' => 'post', 'title' => 'No Date Post' },
      '/no-date.html',
      '<p>Content</p>',
      nil,
      @post_collection,
    )
    # Manually set date to nil to ensure no date
    doc.stub :date, nil do
      result = Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, @site)
      refute result.key?('datePublished'), 'Nil date should omit datePublished'
      refute result.key?('dateModified'), 'Nil date should omit dateModified'
    end
  end

  def test_generate_hash_without_url_omits_url_fields
    # Tests line 63: `unless doc_url_abs && !doc_url_abs.strip.empty?`
    doc = create_doc(
      { 'layout' => 'post', 'title' => 'No URL Post' },
      nil,
      '<p>Content</p>',
      '2024-01-15',
      @post_collection,
    )

    result = Jekyll::SEO::Generators::BlogPostingLdGenerator.generate_hash(doc, @site)
    refute result.key?('url'), 'Nil URL should omit url field'
    refute result.key?('mainEntityOfPage'), 'Nil URL should omit mainEntityOfPage'
  end
end
