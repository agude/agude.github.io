# frozen_string_literal: true

require_relative '../../test_helper'

# Tests for Jekyll::SEO::SeoMetaGenerator
#
# Verifies that the generator produces meta tags matching jekyll-seo-tag behavior.
# Each content type (book, post, author, series, page, homepage) has specific expectations.
class TestSeoMetaGenerator < Minitest::Test
  def setup
    @site_config = {
      'url' => 'https://alexgude.com',
      'baseurl' => '',
      'title' => 'Alex Gude',
      'tagline' => 'Data Scientist',
      'author' => { 'name' => 'Alexander Gude' },
      'description' => 'A blog about technology, data science, machine learning, and more!',
      'locale' => 'en_US',
      'webmaster_verifications' => {
        'google' => 'NnoUcVom5yrsNeAcRLx7yQvWortvmqEP-yazzCmGSMA',
        'bing' => '529AEED96113CF6F5C0DB973E3336D9E',
      },
    }
    @books_collection = MockCollection.new([], 'books')
    @posts_collection = MockCollection.new([], 'posts')
  end

  # --- Title Tag Tests ---

  def test_title_book_review_single_author
    doc = create_book_doc(title: 'A Fire Upon The Deep')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'A Fire Upon The Deep by Test Author - Book Review', result['title']
  end

  def test_title_book_review_two_authors_shared_surname
    doc = create_book_doc(title: 'Roadside Picnic', authors: ['Arkady Strugatsky', 'Boris Strugatsky'])
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'Roadside Picnic by Arkady & Boris Strugatsky - Book Review', result['title']
  end

  def test_title_book_review_two_authors_different_surname
    doc = create_book_doc(title: 'Good Omens', authors: ['Terry Pratchett', 'Neil Gaiman'])
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'Good Omens by Terry Pratchett & Neil Gaiman - Book Review', result['title']
  end

  def test_title_book_review_anthology_drops_authors
    doc = create_book_doc(
      title: 'Honor of the Regiment',
      authors: ['S. M. Stirling', 'S. N. Lewitt', 'J. Andrew Keith', 'Mike Resnick'],
    )
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'Honor of the Regiment - Book Review', result['title']
  end

  def test_title_book_review_handles_jr_suffix_solo_author
    doc = create_book_doc(title: 'A Canticle for Leibowitz', authors: ['Walter M. Miller Jr.'])
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    # Solo author: suffix stays attached, used verbatim.
    assert_equal 'A Canticle for Leibowitz by Walter M. Miller Jr. - Book Review', result['title']
  end

  def test_title_book_review_handles_jr_suffix_in_pair
    doc = create_book_doc(
      title: 'Imagined Book',
      authors: ['John Doe Jr.', 'Jane Doe'],
    )
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    # Suffix stripped before surname comparison; collapse triggers.
    assert_equal 'Imagined Book by John & Jane Doe - Book Review', result['title']
  end

  def test_title_book_review_handles_comma_suffix
    doc = create_book_doc(
      title: 'Imagined Book',
      authors: ['William H. Keith, Jr.', 'William H. Keith'],
    )
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    # Comma + Jr. variants normalize to the same surname/given-names.
    assert_equal 'Imagined Book by William H. & William H. Keith - Book Review', result['title']
  end

  def test_title_book_review_no_authors
    doc = create_book_doc(title: 'Mystery Book', authors: [])
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'Mystery Book - Book Review', result['title']
  end

  def test_title_blog_post
    doc = create_post_doc(title: 'Plotting the 2019 Tour de France')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'Plotting the 2019 Tour de France', result['title']
  end

  def test_title_author_page
    doc = create_page_doc(title: 'Adrian Tchaikovsky', layout: 'author_page')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'Adrian Tchaikovsky - Book Reviews', result['title']
  end

  def test_title_series_page
    doc = create_page_doc(title: 'Bobiverse', layout: 'series_page')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'Bobiverse - Book Reviews', result['title']
  end

  def test_title_regular_page
    doc = create_page_doc(title: 'Papers', layout: 'page')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'Papers', result['title']
  end

  def test_title_homepage
    doc = create_page_doc(title: 'Home', layout: 'homepage', url: '/')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'Alex Gude - Data Scientist', result['title']
  end

  def test_title_category_page
    doc = create_page_doc(title: 'Data Science', layout: 'category')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'Data Science - Articles', result['title']
  end

  def test_title_seo_title_override
    doc = create_doc(
      { 'layout' => 'page', 'title' => 'Papers', 'seo_title' => 'Papers by Alexander Gude' },
      '/papers/',
      'Content',
      nil,
      nil,
    )
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'Papers by Alexander Gude', result['title']
  end

  def test_missing_title_raises_exception
    doc = create_page_doc(title: nil, layout: 'page')
    site = create_site(@site_config)

    assert_raises(Jekyll::Errors::FatalException) { generate_meta(doc, site) }
  end

  def test_empty_title_raises_exception
    doc = create_page_doc(title: '   ', layout: 'page')
    site = create_site(@site_config)

    assert_raises(Jekyll::Errors::FatalException) { generate_meta(doc, site) }
  end

  def test_title_decodes_html_entities
    doc = create_post_doc(title: 'Clever(ly&nbsp;Terrible) Code')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    # Should decode &nbsp; to actual U+00A0 character, not leave as entity
    refute_includes result['title'], '&nbsp;'
    refute_includes result['title'], '&amp;'
    assert_includes result['title'], ' '
  end

  # --- Open Graph Type Tests ---

  def test_og_type_book_review_is_article
    doc = create_book_doc(title: 'Test Book')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'article', result['og_type']
  end

  def test_og_type_blog_post_is_article
    doc = create_post_doc(title: 'Test Post')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'article', result['og_type']
  end

  def test_og_type_review_post_is_article
    doc = create_review_post_doc(title: 'Gadget Review')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'article', result['og_type']
  end

  def test_og_type_author_page_is_website
    doc = create_page_doc(title: 'Author Name', layout: 'author_page')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'website', result['og_type']
  end

  def test_og_type_series_page_is_website
    doc = create_page_doc(title: 'Series Name', layout: 'series_page')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'website', result['og_type']
  end

  def test_og_type_regular_page_is_website
    doc = create_page_doc(title: 'About', layout: 'page')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'website', result['og_type']
  end

  def test_og_type_category_page_is_website
    doc = create_page_doc(title: 'Data Science', layout: 'category')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'website', result['og_type']
  end

  # --- Open Graph Title Tests ---

  def test_og_title_matches_title
    doc = create_book_doc(title: 'A Fire Upon The Deep')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal result['title'], result['og_title']
  end

  # --- Description Tests ---

  def test_description_from_page_description
    doc = create_page_doc(
      title: 'Papers',
      layout: 'page',
      description: 'A list of papers by Alexander Gude.',
    )
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'A list of papers by Alexander Gude.', result['description']
  end

  def test_description_from_excerpt
    doc = create_post_doc(
      title: 'Test Post',
      excerpt: 'This is the excerpt text.',
    )
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'This is the excerpt text.', result['description']
  end

  def test_description_normalizes_whitespace
    doc = create_post_doc(
      title: 'Test Post',
      excerpt: "Line one.\n\n  Line two.",
    )
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'Line one. Line two.', result['description']
  end

  def test_description_fallback_to_site_description
    doc = create_page_doc(title: 'Bare Page', layout: 'page')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal @site_config['description'], result['description']
  end

  def test_description_strips_trailing_whitespace
    doc = create_page_doc(
      title: 'Test',
      layout: 'page',
      description: "Description with trailing space. \n",
    )
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'Description with trailing space.', result['description']
    refute_match(/\s\z/, result['description'])
  end

  # --- Image Tests ---

  def test_og_image_from_page_image
    doc = create_book_doc(
      title: 'Test Book',
      image: '/books/covers/test_book.jpg',
    )
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'https://alexgude.com/books/covers/test_book.jpg', result['image']
  end

  def test_og_image_fallback_to_default
    doc = create_page_doc(title: 'No Image Page', layout: 'page')
    site = create_site(@site_config.merge('logo' => '/files/headshot.jpg'))
    result = generate_meta(doc, site)

    assert_equal 'https://alexgude.com/files/headshot.jpg', result['image']
  end

  # --- Canonical URL Tests ---

  def test_canonical_url_absolute
    doc = create_book_doc(title: 'Test', url: '/books/test/')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'https://alexgude.com/books/test/', result['canonical']
  end

  def test_og_url_uses_canonical
    doc = create_book_doc(title: 'Test', url: '/books/test/')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'https://alexgude.com/books/test/', result['canonical']
  end

  # --- og:description Tests ---

  def test_og_description_uses_description
    doc = create_page_doc(
      title: 'Papers',
      layout: 'page',
      description: 'A list of papers.',
    )
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'A list of papers.', result['description']
  end

  # --- Twitter Card Tests ---

  def test_twitter_card_summary_large_image_when_image_present
    doc = create_book_doc(title: 'Test', image: '/books/covers/test.jpg')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'summary_large_image', result['twitter_card']
  end

  def test_twitter_card_summary_when_no_page_image
    doc = create_page_doc(title: 'Test', layout: 'page')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'summary', result['twitter_card']
  end

  # --- Article Published Time Tests ---

  def test_article_published_time_for_posts
    doc = create_post_doc(title: 'Test', date: '2024-08-22')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert result['article_published_time']
    assert_match(/2024-08-22/, result['article_published_time'])
  end

  def test_article_published_time_for_books
    doc = create_book_doc(title: 'Test', date: '2024-08-22')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert result['article_published_time']
  end

  def test_article_published_time_for_review_posts
    doc = create_review_post_doc(title: 'Gadget Review', date: '2024-08-22')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert result['article_published_time']
    assert_match(/2024-08-22/, result['article_published_time'])
  end

  def test_no_article_published_time_for_pages
    doc = create_page_doc(title: 'Test', layout: 'page')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_nil result['article_published_time']
  end

  # Forces every layout known to JSON-LD to be explicitly classified
  # as either an article or a non-article. Catches the regression where
  # adding a new layout silently defaults to og:type=website (the bug
  # that landed for `review-post`).
  def test_every_known_layout_has_article_classification
    require_relative '../../../_plugins/src/seo/json_ld_injector'

    article_layouts = %w[book post review-post]
    non_article_layouts = %w[
      author_page resume series_page category page page-not-on-sidebar
      standalone-page homepage linktree
    ]

    classified = (article_layouts + non_article_layouts).sort
    registered = Jekyll::SEO::JsonLdInjector::LAYOUT_GENERATORS.keys.sort

    assert_equal registered, classified,
                 'Every layout in JsonLdInjector::LAYOUT_GENERATORS must be ' \
                 'classified as either article or non-article in this test. ' \
                 'If you added a new layout, also add it to ARTICLE_LAYOUTS ' \
                 'in seo_meta_generator.rb if it represents article content.'
    assert_equal Jekyll::SEO::SeoMetaGenerator::ARTICLE_LAYOUTS.sort, article_layouts.sort
  end

  # --- Site Author Tests ---

  def test_author_meta_from_site_config
    doc = create_page_doc(title: 'Test', layout: 'page')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'Alexander Gude', result['author']
  end

  # --- Locale Tests ---

  def test_og_locale_from_site_config
    doc = create_page_doc(title: 'Test', layout: 'page')
    site = create_site(@site_config.merge('locale' => 'en_US'))
    result = generate_meta(doc, site)

    assert_equal 'en_US', result['og_locale']
  end

  # --- Site Name Tests ---

  def test_og_site_name_from_site_title
    doc = create_page_doc(title: 'Test', layout: 'page')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'Alex Gude', result['og_site_name']
  end

  # --- Verification Tags Tests ---

  def test_google_site_verification
    doc = create_page_doc(title: 'Test', layout: 'page')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal 'NnoUcVom5yrsNeAcRLx7yQvWortvmqEP-yazzCmGSMA', result['google_site_verification']
  end

  def test_bing_site_verification
    doc = create_page_doc(title: 'Test', layout: 'page')
    site = create_site(@site_config)
    result = generate_meta(doc, site)

    assert_equal '529AEED96113CF6F5C0DB973E3336D9E', result['bing_site_verification']
  end

  private

  # --- Document Creation Helpers ---

  def create_book_doc(title:, url: '/books/test/', image: nil, date: '2024-01-01', description: nil, excerpt: nil, authors: ['Test Author'])
    data = {
      'layout' => 'book',
      'title' => title,
      'book_authors' => authors,
    }
    data['image'] = image if image
    data['description'] = description if description
    data['excerpt'] = mock_excerpt(excerpt) if excerpt

    create_doc(data, url, 'Test content', date, @books_collection)
  end

  def create_post_doc(title:, url: '/blog/test/', date: '2024-01-01', description: nil, excerpt: nil)
    data = {
      'layout' => 'post',
      'title' => title,
    }
    data['description'] = description if description
    data['excerpt'] = mock_excerpt(excerpt) if excerpt

    create_doc(data, url, 'Test content', date, @posts_collection)
  end

  def create_review_post_doc(title:, url: '/blog/review/', date: '2024-01-01')
    data = {
      'layout' => 'review-post',
      'title' => title,
    }
    create_doc(data, url, 'Test content', date, @posts_collection)
  end

  def create_page_doc(title:, layout:, url: '/test/', description: nil)
    data = {
      'layout' => layout,
      'title' => title,
    }
    data['description'] = description if description

    create_doc(data, url, 'Test content', nil, nil)
  end

  def mock_excerpt(text)
    return nil unless text

    Struct.new(:output).new("<p>#{text}</p>")
  end

  def generate_meta(doc, site)
    Jekyll::SEO::SeoMetaGenerator.generate(doc, site)
  end
end
