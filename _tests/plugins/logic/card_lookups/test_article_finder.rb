# frozen_string_literal: true

# _tests/plugins/logic/card_lookups/test_article_finder.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/logic/card_lookups/article_finder'

# Tests for Jekyll::CardLookups::ArticleFinder.
#
# Verifies that the ArticleFinder correctly finds posts by URL and handles errors.
class TestArticleFinder < Minitest::Test
  def setup
    @post1 = create_doc({ 'title' => 'Post One' }, '/blog/post-one.html')
    @post2 = create_doc({ 'title' => 'Post Two' }, '/blog/post-two.html')
    @post3 = create_doc({ 'title' => 'Post Three' }, '/blog/post-three.html')

    @site = create_site({ 'url' => 'http://example.com' }, {}, [], [@post1, @post2, @post3])
    @context = create_context(
      {},
      { site: @site, page: create_doc({ 'path' => 'current.html' }, '/current.html') }
    )
  end

  def test_finds_post_by_url
    finder = Jekyll::CardLookups::ArticleFinder.new(
      site: @site,
      url_markup: '"/blog/post-one.html"',
      context: @context
    )
    result = finder.find

    assert_nil result[:error]
    assert_equal @post1, result[:post]
    assert_equal '/blog/post-one.html', result[:url]
  end

  def test_finds_post_by_url_from_variable
    @context['my_url'] = '/blog/post-two.html'
    finder = Jekyll::CardLookups::ArticleFinder.new(
      site: @site,
      url_markup: 'my_url',
      context: @context
    )
    result = finder.find

    assert_nil result[:error]
    assert_equal @post2, result[:post]
    assert_equal '/blog/post-two.html', result[:url]
  end

  def test_adds_leading_slash_to_url
    finder = Jekyll::CardLookups::ArticleFinder.new(
      site: @site,
      url_markup: '"blog/post-three.html"',
      context: @context
    )
    result = finder.find

    assert_nil result[:error]
    assert_equal @post3, result[:post]
    assert_equal '/blog/post-three.html', result[:url]
  end

  def test_returns_url_error_when_url_markup_resolves_to_nil
    @context['nil_url'] = nil
    finder = Jekyll::CardLookups::ArticleFinder.new(
      site: @site,
      url_markup: 'nil_url',
      context: @context
    )
    result = finder.find

    assert_nil result[:post]
    assert_nil result[:url]
    assert_equal :url_error, result[:error][:type]
  end

  def test_returns_url_error_when_url_markup_resolves_to_empty
    @context['empty_url'] = '   '
    finder = Jekyll::CardLookups::ArticleFinder.new(
      site: @site,
      url_markup: 'empty_url',
      context: @context
    )
    result = finder.find

    assert_nil result[:post]
    assert_nil result[:url]
    assert_equal :url_error, result[:error][:type]
  end

  def test_returns_collection_error_when_posts_docs_is_not_array
    bad_site = create_site({ 'url' => 'http://example.com' }, {}, [], 'not_an_array')
    finder = Jekyll::CardLookups::ArticleFinder.new(
      site: bad_site,
      url_markup: '"/blog/post-one.html"',
      context: @context
    )
    result = finder.find

    assert_nil result[:post]
    assert_equal '/blog/post-one.html', result[:url]
    assert_equal :collection_error, result[:error][:type]
    assert_equal 'String', result[:error][:details]
  end

  def test_returns_collection_error_when_posts_is_nil
    @site.instance_variable_set(:@posts, nil)
    finder = Jekyll::CardLookups::ArticleFinder.new(
      site: @site,
      url_markup: '"/blog/post-one.html"',
      context: @context
    )
    result = finder.find

    assert_nil result[:post]
    assert_equal '/blog/post-one.html', result[:url]
    assert_equal :collection_error, result[:error][:type]
    assert_equal 'nil', result[:error][:details]
  end

  def test_returns_post_not_found_when_url_does_not_match
    finder = Jekyll::CardLookups::ArticleFinder.new(
      site: @site,
      url_markup: '"/blog/nonexistent.html"',
      context: @context
    )
    result = finder.find

    assert_nil result[:post]
    assert_equal '/blog/nonexistent.html', result[:url]
    assert_equal :post_not_found, result[:error][:type]
    assert_equal '/blog/nonexistent.html', result[:error][:details]
  end

  def test_returns_first_matching_post_if_duplicates_exist
    duplicate_post = create_doc({ 'title' => 'Duplicate Post' }, '/blog/post-one.html')
    site_with_duplicate = create_site(
      { 'url' => 'http://example.com' },
      {},
      [],
      [@post1, duplicate_post, @post2]
    )
    finder = Jekyll::CardLookups::ArticleFinder.new(
      site: site_with_duplicate,
      url_markup: '"/blog/post-one.html"',
      context: @context
    )
    result = finder.find

    assert_nil result[:error]
    assert_equal @post1, result[:post]
  end
end
