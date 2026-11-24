# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../_plugins/src/seo/json_ld_injector'
require 'json'
require 'nokogiri'
require 'minitest/mock'

# Base test class with shared setup and helpers for Jekyll::SEO::JsonLdInjector tests.
#
# Provides common setup and helper methods for testing JSON-LD injection.
class TestJsonLdInjectorBase < Minitest::Test
  def setup
    @site = create_site
    # Ensure MockSite responds to show_drafts for stubbing and plugin logic
    unless @site.respond_to?(:show_drafts)
      def @site.show_drafts
        config['show_drafts']
      end
    end

    setup_collections
    setup_mock_documents
    setup_expected_hashes
  end

  def assert_json_script(document, site, expected_hash)
    script_tag = get_script_tag_for_document(document, site)
    json_content = extract_json_from_script(script_tag)
    assert_parsed_json_matches(json_content, expected_hash)
  end

  def assert_no_json_script(document, site)
    lookup_url = document.url
    script_storage = site.data['generated_json_ld_scripts']
    script_present = script_storage && lookup_url && script_storage.key?(lookup_url)
    refute script_present, "Expected no json_ld_script for URL '#{lookup_url}', but found one in site.data"
  end

  private

  def setup_collections
    @posts_collection = MockCollection.new([], 'posts')
    @books_collection = MockCollection.new([], 'books')
  end

  def setup_mock_documents
    @blog_post_doc = create_doc(
      { 'layout' => 'post', 'title' => 'Standard Post' },
      '/blog/standard.html',
      'Blog content',
      nil,
      @posts_collection,
    )
    @blog_post_doc.site = @site

    @book_review_doc = create_doc(
      { 'layout' => 'book', 'title' => 'Book Review' },
      '/books/review.html',
      'Book review content',
      nil,
      @books_collection,
    )
    @book_review_doc.site = @site

    @generic_review_post_doc = create_doc(
      { 'layout' => 'review-post', 'title' => 'Generic Review', 'review' => { 'item_name' => 'Gadget V1' } },
      '/blog/generic.html',
      'Generic review content',
      nil,
      @posts_collection,
    )
    @generic_review_post_doc.site = @site

    @author_page_doc = create_doc(
      { 'layout' => 'author_page', 'title' => 'Author Name' },
      '/authors/author.html',
      'Author bio',
      nil,
      nil,
    )
    @author_page_doc.site = @site

    @other_page_doc = create_doc(
      { 'layout' => 'compress', 'title' => 'Other Page' },
      '/other.html',
      'Other content',
      nil,
      nil,
    )
    @other_page_doc.site = @site
  end

  def setup_expected_hashes
    @blog_posting_hash = { '@type' => 'BlogPosting', 'headline' => 'Standard Post', 'test_marker' => 'blog' }
    @author_profile_hash = { '@type' => 'Person', 'name' => 'Author Name', 'test_marker' => 'author' }
  end

  def get_script_tag_for_document(document, site)
    lookup_url = document.url
    refute_nil lookup_url, 'Document URL is nil, cannot look up script.'

    script_storage = site.data['generated_json_ld_scripts']
    refute_nil script_storage, "site.data['generated_json_ld_scripts'] hash does not exist."

    script_tag = script_storage[lookup_url]
    refute_nil script_tag, "Expected json_ld_script to be set for URL '#{lookup_url}', but was nil in site.data"

    verify_script_tag_structure(script_tag)
    script_tag
  end

  def verify_script_tag_structure(script_tag)
    assert_match %r{<script type="application/ld\+json">}, script_tag, 'Script tag opening not found'
    assert_match %r{</script>}, script_tag, 'Script tag closing not found'
  end

  def extract_json_from_script(script_tag)
    match_data = script_tag.match(%r{<script type="application/ld\+json">\s*(.*)\s*</script>}m)
    refute_nil match_data, "Could not extract JSON content from script tag: #{script_tag.inspect}"
    match_data[1]
  end

  def assert_parsed_json_matches(json_content, expected_hash)
    parsed_json = JSON.parse(json_content)
    assert_equal expected_hash, parsed_json
  rescue JSON::ParserError => e
    flunk "Failed to parse JSON content: #{e.message}\nContent was:\n#{json_content}"
  end
end

# Tests for successful JSON-LD injection into documents.
#
# Verifies that the injector correctly generates and stores JSON-LD scripts.
class TestJsonLdInjectorInjection < TestJsonLdInjectorBase
  def test_injects_for_standard_blog_post
    Jekyll::SEO::JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
    result = JSON.parse(extract_json_from_script(get_script_tag_for_document(@blog_post_doc, @site)))

    assert_equal 'BlogPosting', result['@type']
    assert_equal 'Standard Post', result['headline']
  end

  def test_injects_for_book_review
    Jekyll::SEO::JsonLdInjector.inject_json_ld(@book_review_doc, @site)
    result = JSON.parse(extract_json_from_script(get_script_tag_for_document(@book_review_doc, @site)))

    assert_equal 'Review', result['@type']
    assert_equal 'Book', result.dig('itemReviewed', '@type')
  end

  def test_injects_for_generic_review_post
    Jekyll::SEO::JsonLdInjector.inject_json_ld(@generic_review_post_doc, @site)
    result = JSON.parse(extract_json_from_script(get_script_tag_for_document(@generic_review_post_doc, @site)))

    assert_equal 'Review', result['@type']
    assert_equal({ '@type' => 'Product', 'name' => 'Gadget V1' }, result['itemReviewed'])
  end

  def test_injects_for_author_page
    Jekyll::SEO::JsonLdInjector.inject_json_ld(@author_page_doc, @site)
    result = JSON.parse(extract_json_from_script(get_script_tag_for_document(@author_page_doc, @site)))

    assert_equal 'CollectionPage', result['@type']
    assert_equal 'Author Name - Book Reviews', result['name']
  end
end

# Tests for skipped injection scenarios where JSON-LD shouldn't be generated.
#
# Verifies that the injector correctly skips invalid or inappropriate documents.
class TestJsonLdInjectorSkip < TestJsonLdInjectorBase
  def test_skips_injection_for_unhandled_layout
    Jekyll::SEO::JsonLdInjector.inject_json_ld(@other_page_doc, @site)
    assert_no_json_script(@other_page_doc, @site)
  end

  def test_skips_injection_if_generator_returns_nil
    Jekyll::SEO::JsonLdInjector.stub :_generator_for_layout, [->(*_args) {}, 'Post'] do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
    end
    assert_no_json_script(@blog_post_doc, @site)
  end

  def test_skips_injection_if_generator_returns_false
    Jekyll::SEO::JsonLdInjector.stub :_generator_for_layout, [->(*_args) { false }, 'Post'] do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
    end
    assert_no_json_script(@blog_post_doc, @site)
  end

  def test_skips_injection_if_generator_returns_empty_hash
    Jekyll::SEO::JsonLdInjector.stub :_generator_for_layout, [->(*_args) { {} }, 'Post'] do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
    end
    assert_no_json_script(@blog_post_doc, @site)
  end

  def test_skips_injection_for_document_without_url
    # Create doc with all URL-related fields nil/empty
    doc_no_url = MockDocument.new(
      { 'layout' => 'post', 'title' => 'No URL Post', 'published' => true },
      nil, # url
      'Content',
      Time.now,
      @site,
      @posts_collection,
      nil, # relative_path
    )

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:warn, nil) do |prefix, message|
      prefix == 'JSON-LD:' && message.include?('Skipping document without URL')
    end

    Jekyll.stub :logger, mock_logger do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(doc_no_url, @site)
    end

    assert_no_json_script(doc_no_url, @site)
    mock_logger.verify
  end

  def test_skips_injection_for_document_with_empty_url
    doc_empty_url = create_doc(
      { 'layout' => 'post', 'title' => 'Empty URL Post' },
      '', # URL is empty string
      'Content',
      nil,
      @posts_collection,
    )
    doc_empty_url.site = @site

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:warn, nil) do |prefix, message|
      prefix == 'JSON-LD:' && message.include?('Skipping document without URL')
    end

    Jekyll.stub :logger, mock_logger do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(doc_empty_url, @site)
    end

    assert_no_json_script(doc_empty_url, @site)
    mock_logger.verify
  end

  def test_json_generation_error_stops_build
    # Create a hash that will cause JSON.pretty_generate to raise an error
    invalid_hash = { '@type' => 'BlogPosting', 'invalid' => Float::INFINITY }

    error = Jekyll::SEO::JsonLdInjector.stub :generate_hash, invalid_hash do
      assert_raises(Jekyll::Errors::FatalException) do
        Jekyll::SEO::JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
      end
    end

    assert_match @blog_post_doc.url, error.message
    assert_match 'Failed to generate JSON', error.message
    assert_no_json_script(@blog_post_doc, @site)
  end

  # articleBody is post text with entities decoded, so code samples become
  # literal markup inside the JSON. Two HTML parser states can end or hijack
  # the <script> element: a closing tag in any letter case, and `<!--`
  # followed by `<script`, which makes the parser ignore the real closing
  # tag and swallow the rest of the head. Parse a full head with an HTML5
  # parser and check that the JSON and a following element both survive.
  def test_script_tag_survives_html_parsing_of_hostile_text
    hostile_bodies = [
      'Close the tag with </script> and keep going.',
      'Mixed case </ScRiPt> also closes it.',
      'An HTML comment <!-- <script> swallows what follows.',
    ]

    hostile_bodies.each do |body|
      @site.data['generated_json_ld_scripts'] = {}
      hash = { '@type' => 'BlogPosting', 'articleBody' => body }
      Jekyll::SEO::JsonLdInjector.stub :generate_hash, hash do
        Jekyll::SEO::JsonLdInjector.inject_json_ld(@blog_post_doc, @site)
      end

      script_tag = @site.data['generated_json_ld_scripts'][@blog_post_doc.url]
      html = "<!DOCTYPE html><html><head>#{script_tag}<meta name=\"sentinel\" content=\"after\"></head>" \
             '<body></body></html>'
      doc = Nokogiri::HTML5(html)

      refute_nil doc.at_css('head meta[name="sentinel"]'), "Sentinel element swallowed for: #{body.inspect}"
      scripts = doc.css('script[type="application/ld+json"]')
      assert_equal 1, scripts.size, "Expected one JSON-LD script for: #{body.inspect}"
      assert_equal body, JSON.parse(scripts.first.text)['articleBody'], "JSON text altered for: #{body.inspect}"
    end
  end

  def test_review_without_item_name_stops_build
    @generic_review_post_doc.data['review'].delete('item_name')

    error = assert_raises(Jekyll::Errors::FatalException) do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(@generic_review_post_doc, @site)
    end

    assert_match @generic_review_post_doc.url, error.message
    assert_match 'review.item_name', error.message
  end
end

# Tests for edge cases with non-Document objects (Pages, etc.).
#
# Verifies that type checkers correctly handle objects which are
# not Jekyll::Document instances (triggers else branches in type checkers).
class TestJsonLdInjectorNonDocuments < TestJsonLdInjectorBase
  # Struct to mimic Jekyll::Page behavior (not a Jekyll::Document)
  PageLike = Struct.new(:data, :url, :path, :relative_path)

  def test_handles_page_like_object_with_matching_layout
    # Create a page-like object (not a Jekyll::Document)
    author_page = PageLike.new(
      { 'layout' => 'author_page', 'title' => 'Page Author' },
      '/authors/page-author.html',
      'authors/page-author.html',
      'authors/page-author.html',
    )

    Jekyll::SEO::JsonLdInjector.inject_json_ld(author_page, @site)
    result = JSON.parse(extract_json_from_script(get_script_tag_for_document(author_page, @site)))

    assert_equal 'CollectionPage', result['@type']
    assert_equal 'Page Author', result.dig('about', 'name')
  end

  def test_handles_page_like_object_with_skipped_layout
    # Create a page-like object with a layout in SKIP_LAYOUTS
    regular_page = PageLike.new(
      { 'layout' => 'compress', 'title' => 'Regular Page' },
      '/regular.html',
      'regular.html',
      'regular.html',
    )

    Jekyll::SEO::JsonLdInjector.inject_json_ld(regular_page, @site)

    # Should not have generated script
    assert_no_json_script(regular_page, @site)
  end

  def test_raises_for_unknown_layout
    unknown_page = PageLike.new(
      { 'layout' => 'totally-made-up', 'title' => 'Bad Layout' },
      '/bad.html',
      'bad.html',
      'bad.html',
    )

    assert_raises(Jekyll::Errors::FatalException) do
      Jekyll::SEO::JsonLdInjector.inject_json_ld(unknown_page, @site)
    end
  end
end

# Tests for Jekyll Hooks registration and execution.
#
# Verifies that the plugin correctly registers and handles Jekyll hooks
# for site reset, document processing, and page processing.
class TestJsonLdInjectorHooks < TestJsonLdInjectorBase
  def test_site_after_reset_hook_initializes_storage
    # Clear existing storage to verify hook re-initializes it
    @site.data.delete('generated_json_ld_scripts')

    Jekyll::Hooks.trigger(:site, :after_reset, @site)

    assert @site.data.key?('generated_json_ld_scripts'),
           "Expected 'generated_json_ld_scripts' to be initialized in site.data"
    assert_equal({}, @site.data['generated_json_ld_scripts'])
  end

  def test_documents_post_convert_hook_injects_json_ld
    # Verify that the hook calls inject_json_ld (evidenced by script generation)
    Jekyll::SEO::JsonLdInjector.stub :generate_hash, @blog_posting_hash do
      Jekyll::Hooks.trigger(:documents, :post_convert, @blog_post_doc)
    end

    assert_json_script(@blog_post_doc, @site, @blog_posting_hash)
  end

  def test_documents_post_convert_hook_skips_static_files
    static_file = Jekyll::StaticFile.new(@site, @site.source, 'assets', 'image.jpg')

    # Should not raise error
    Jekyll::Hooks.trigger(:documents, :post_convert, static_file)

    # Verify no script storage was created for a static file (it wouldn't have a URL key in the same way)
  end

  def test_documents_post_convert_hook_skips_drafts_when_disabled
    # Create a draft document
    draft_doc = create_doc(
      { 'layout' => 'post', 'title' => 'Draft Post' },
      '/drafts/post.html',
      'Draft content',
      nil,
      @posts_collection,
    )
    draft_doc.site = @site

    # Mock draft? to return true
    draft_doc.define_singleton_method(:draft?) { true }

    # Force site.show_drafts to false
    @site.stub :show_drafts, false do
      Jekyll::Hooks.trigger(:documents, :post_convert, draft_doc)
    end

    assert_no_json_script(draft_doc, @site)
  end

  def test_documents_post_convert_hook_logs_error_when_site_missing
    # Create document with nil site
    doc_no_site = MockDocument.new(
      { 'layout' => 'post' }, '/no-site.html', 'Content', Time.now, nil, @posts_collection, 'no-site.html',
    )

    error_logged = false
    logger_stub = Object.new
    logger_stub.define_singleton_method(:error) do |prefix, message|
      error_logged = true if prefix == 'JSON-LD Hook:' && message.include?('Site object not available')
    end
    logger_stub.define_singleton_method(:method_missing) { |*| nil }

    Jekyll.stub :logger, logger_stub do
      Jekyll::Hooks.trigger(:documents, :post_convert, doc_no_site)
    end

    assert error_logged, 'Expected error log for missing site'
  end

  def test_pages_post_convert_hook_injects_json_ld
    # Create a page-like object that responds to :site
    page_struct = Struct.new(:site, :data, :url, :path, :relative_path)
    page = page_struct.new(
      @site,
      { 'layout' => 'author_page', 'title' => 'Page Author' },
      '/page-author.html',
      'page-author.html',
      'page-author.html',
    )

    Jekyll::SEO::JsonLdInjector.stub :generate_hash, @author_profile_hash do
      Jekyll::Hooks.trigger(:pages, :post_convert, page)
    end

    assert_json_script(page, @site, @author_profile_hash)
  end

  def test_pages_post_convert_hook_skips_static_files
    static_file = Jekyll::StaticFile.new(@site, @site.source, 'assets', 'style.css')
    Jekyll::Hooks.trigger(:pages, :post_convert, static_file)
  end

  def test_pages_post_convert_hook_logs_error_when_site_missing
    # Page without site
    page_no_site_struct = Struct.new(:site, :data, :url, :relative_path)
    page_no_site = page_no_site_struct.new(
      nil,
      { 'layout' => 'page' },
      '/no-site-page.html',
      'no-site-page.html',
    )

    error_logged = false
    logger_stub = Object.new
    logger_stub.define_singleton_method(:error) do |prefix, message|
      error_logged = true if prefix == 'JSON-LD Hook:' && message.include?('Site object not available')
    end
    logger_stub.define_singleton_method(:method_missing) { |*| nil }

    Jekyll.stub :logger, logger_stub do
      Jekyll::Hooks.trigger(:pages, :post_convert, page_no_site)
    end

    assert error_logged, 'Expected error log for missing site'
  end
end

# Exercises the document-to-hash boundary for layouts without a custom generator.
class TestJsonLdLayoutSchemas < Minitest::Test
  BASE_URL = 'https://example.com'
  OWNER = {
    '@type' => 'Person',
    '@id' => "#{BASE_URL}/resume/#person",
    'name' => 'Site Owner',
    'url' => "#{BASE_URL}/resume/",
  }.freeze
  WEBSITE = {
    '@type' => 'WebSite',
    '@id' => "#{BASE_URL}/#website",
    'name' => 'Example',
    'url' => "#{BASE_URL}/",
  }.freeze

  def setup
    @site = create_site(
      'url' => BASE_URL,
      'title' => 'Example',
      'name' => 'example.com',
      'description' => 'Site description',
      'author' => { 'name' => 'Site Owner', 'url' => '/resume/', 'github' => 'owner' },
    )
  end

  def test_collection_and_web_page_layouts
    [
      ['page', '/blog/', 'Blog', 'CollectionPage'],
      ['papers', '/papers/', 'Publications', 'CollectionPage'],
      ['page-not-on-sidebar', '/topics/', 'Topics', 'CollectionPage'],
      ['standalone-page', '/files/', 'Supplement', 'WebPage'],
    ].each do |layout, path, title, type|
      doc = create_doc({ 'layout' => layout, 'title' => title, 'description' => '<p>Page description.</p>' }, path)
      expected = {
        '@context' => 'https://schema.org',
        '@type' => type,
        'name' => title,
        'url' => BASE_URL + path,
        'description' => 'Page description.',
        'author' => OWNER,
        'isPartOf' => WEBSITE,
      }
      assert_equal expected, generate(doc), layout
    end
  end

  def test_category_title_takes_precedence_and_falls_back_to_title
    doc = create_doc(
      { 'layout' => 'category', 'category-title' => 'Data Science', 'title' => 'Topic', 'description' => 'Articles.' },
      '/topics/data-science/',
    )
    expected = {
      '@context' => 'https://schema.org',
      '@type' => 'CollectionPage',
      'name' => 'Data Science - Articles',
      'url' => "#{BASE_URL}/topics/data-science/",
      'description' => 'Articles.',
      'author' => OWNER,
      'isPartOf' => WEBSITE,
    }
    assert_equal expected, generate(doc)
    doc.data.delete('category-title')
    assert_equal expected.merge('name' => 'Topic - Articles'), generate(doc)
  end

  def test_series_page_describes_the_series
    path = '/books/series/bobiverse/'
    doc = create_doc(
      { 'layout' => 'series_page', 'title' => 'The<br>Bobiverse', 'description' => 'Series reviews.' }, path,
    )
    expected = {
      '@context' => 'https://schema.org',
      '@type' => 'CollectionPage',
      'name' => 'The Bobiverse - Book Reviews',
      'url' => BASE_URL + path,
      'description' => 'Series reviews.',
      'author' => OWNER,
      'isPartOf' => WEBSITE,
      'about' => { '@type' => 'BookSeries', '@id' => "#{BASE_URL}#{path}#series", 'name' => 'The Bobiverse', 'url' => BASE_URL + path },
    }
    assert_equal expected, generate(doc)
  end

  def test_collection_and_web_pages_omit_missing_or_blank_fields
    site = create_site('url' => BASE_URL)
    %w[page papers page-not-on-sidebar standalone-page category series_page].each do |layout|
      [nil, '   '].each do |description|
        doc = create_doc({ 'layout' => layout, 'title' => 'A&nbsp;Title<br>Here', 'description' => description }, '/test/')
        result = generate(doc, site)

        suffix = { 'category' => ' - Articles', 'series_page' => ' - Book Reviews' }.fetch(layout, '')
        assert_equal "A\u00A0Title Here#{suffix}", result['name'], layout
        assert_empty result.keys & %w[description author isPartOf], layout
      end
    end
  end

  def test_homepage_describes_the_website
    doc = create_doc({ 'layout' => 'homepage' }, '/')
    expected = WEBSITE.merge(
      '@context' => 'https://schema.org',
      'alternateName' => 'example.com',
      'description' => 'Site description',
      'author' => OWNER,
      'publisher' => OWNER,
    )
    assert_equal expected, generate(doc)
  end

  def test_homepage_omits_unconfigured_site_fields
    doc = create_doc({ 'layout' => 'homepage' }, '/')
    assert_equal(
      { '@context' => 'https://schema.org', '@type' => 'WebSite', '@id' => "#{BASE_URL}/#website", 'url' => "#{BASE_URL}/" },
      generate(doc, create_site('url' => BASE_URL)),
    )
  end

  def test_linktree_describes_the_site_owner
    @site.config['author'].merge!(
      'linkedin' => 'owner', 'bluesky' => 'example.com', 'mastodon' => 'owner', 'mastodon_instance' => 'fosstodon.org',
    )
    doc = create_doc({ 'layout' => 'linktree', 'title' => 'Find<br>Me', 'description' => 'Social links.' }, '/linktree/')
    expected = {
      '@context' => 'https://schema.org',
      '@type' => 'ProfilePage',
      'name' => 'Find Me',
      'url' => "#{BASE_URL}/linktree/",
      'description' => 'Social links.',
      'mainEntity' => OWNER.merge(
        'sameAs' => [
          'https://www.linkedin.com/in/owner',
          'https://github.com/owner',
          'https://bsky.app/profile/example.com',
          'https://fosstodon.org/@owner',
        ],
      ),
    }
    assert_equal expected, generate(doc)

    %w[resume post].each do |layout|
      related = generate(create_doc({ 'layout' => layout, 'title' => 'Title' }, "/#{layout}/"))
      assert_equal OWNER['@id'], related.dig(layout == 'resume' ? 'mainEntity' : 'author', '@id')
    end
  end

  def test_linktree_omits_missing_person_and_social_fields
    doc = create_doc({ 'layout' => 'linktree', 'title' => 'Find Me' }, '/linktree/')
    result = generate(doc, create_site('url' => BASE_URL))
    assert_empty result.keys & %w[description mainEntity]

    @site.config['author'].delete('github')
    assert_equal OWNER, generate(doc)['mainEntity']
  end

  def test_author_page_keeps_page_text_and_person_identity_separate
    doc = create_doc(
      {
        'layout' => 'author_page',
        'title' => 'Jane&nbsp;Doe<br>Jr.',
        'description' => 'Page description.',
        'excerpt_output_override' => '<p>Page intro.</p>',
        'wikidata_qid' => 'Q42',
        'same_as_urls' => [' https://example.org/jane ', nil, ''],
        'pen_names' => [' J.D. Writer ', nil, ''],
      },
      '/authors/jane/',
    )
    url = "#{BASE_URL}/authors/jane/"
    expected = {
      '@context' => 'https://schema.org',
      '@type' => 'CollectionPage',
      '@id' => url,
      'url' => url,
      'name' => "Jane\u00A0Doe Jr. - Book Reviews",
      'description' => 'Page description.',
      'author' => OWNER,
      'isPartOf' => WEBSITE,
      'about' => {
        '@type' => 'Person',
        '@id' => "#{url}#person",
        'url' => url,
        'name' => "Jane\u00A0Doe Jr.",
        'sameAs' => ['https://www.wikidata.org/wiki/Q42', 'https://example.org/jane'],
        'alternateName' => ['J.D. Writer'],
      },
    }
    assert_equal expected, generate(doc)
  end

  def test_author_page_keeps_identity_when_optional_fields_are_blank
    [nil, []].each do |empty|
      doc = create_doc(
        {
          'layout' => 'author_page',
          'title' => ' ',
          'description' => '',
          'same_as_urls' => empty,
          'pen_names' => empty,
          'excerpt_output_override' => '<p>Page intro.</p>',
        },
        '/authors/jane/',
      )
      result = generate(doc)

      assert_empty result.keys & %w[name description]
      url = "#{BASE_URL}/authors/jane/"
      assert_equal({ '@type' => 'Person', '@id' => "#{url}#person", 'url' => url }, result['about'])
    end
  end

  def test_post_includes_article_metadata_and_visible_text
    doc = create_doc(
      {
        'layout' => 'post',
        'title' => 'Title<br>Here',
        'description' => 'Word ' * 60,
        'excerpt_output_override' => '<p>Excerpt.</p>',
        'image' => '/images/post.png',
        'last_modified_at' => Time.utc(2024, 5, 6),
        'categories' => ['Blog'],
        'tags' => %w[Blog Tag],
        'markdown_alternate_href' => '/blog/post.md',
      },
      '/blog/post/',
      '<p>Read <a href="/books/test/">Test<!--book-preview--><span class="book-link-preview">Hidden text.</span><!--/book-preview--></a>.</p>',
      '2024-01-15T11:00:00-05:00',
    )
    expected = {
      '@context' => 'https://schema.org',
      '@type' => 'BlogPosting',
      'license' => 'https://creativecommons.org/licenses/by-sa/4.0/',
      'headline' => 'Title Here',
      'author' => OWNER,
      'publisher' => OWNER,
      'datePublished' => '2024-01-15T11:00:00-05:00',
      'dateModified' => '2024-05-06T00:00:00Z',
      'image' => { '@type' => 'ImageObject', 'url' => "#{BASE_URL}/images/post.png" },
      'url' => "#{BASE_URL}/blog/post/",
      'mainEntityOfPage' => { '@type' => 'WebPage', '@id' => "#{BASE_URL}/blog/post/" },
      'description' => "#{'Word ' * 49}Word...",
      'articleBody' => 'Read Test.',
      'wordCount' => 2,
      'keywords' => 'Blog, Tag',
      'encoding' => { '@type' => 'MediaObject', 'encodingFormat' => 'text/markdown', 'contentUrl' => "#{BASE_URL}/blog/post.md" },
    }
    assert_equal expected, generate(doc)
  end

  def test_post_uses_excerpt_when_description_is_missing_or_blank
    [nil, '   '].each do |description|
      doc = create_doc(
        { 'layout' => 'post', 'title' => 'Post', 'description' => description, 'excerpt_output_override' => '<p>Excerpt.</p>' },
      )

      assert_equal 'Excerpt.', generate(doc)['description']
    end
  end

  def test_post_uses_description_with_no_excerpt
    doc = create_doc(
      { 'layout' => 'post', 'title' => 'Post', 'description' => '<p>Summary.</p>', 'excerpt_output_override' => '' },
    )
    assert_equal 'Summary.', generate(doc)['description']
  end

  def test_post_omits_missing_optional_fields
    doc = create_doc({ 'layout' => 'post', 'title' => 'Post' }, '/blog/post/', '')
    site = create_site('url' => BASE_URL)

    result = generate(doc, site)
    assert_empty result.keys & %w[description articleBody wordCount keywords image encoding author publisher]
    assert_equal doc.date.xmlschema, result['datePublished']
    assert_equal result['datePublished'], result['dateModified']

    doc.stub :date, nil do
      assert_empty generate(doc, site).keys & %w[datePublished dateModified]
    end
  end

  def test_post_requires_headline_and_url
    [['   ', '/blog/post/', 'headline'], ['Post', nil, 'url']].each do |title, url, missing|
      doc = create_doc({ 'layout' => 'post', 'title' => title }, url)

      error = assert_raises(Jekyll::Errors::FatalException) { generate(doc) }
      assert_includes error.message, "missing required fields: #{missing}"
    end
  end

  private

  def generate(doc, site = @site)
    Jekyll::SEO::JsonLdInjector.generate_hash(doc, site)
  end
end
