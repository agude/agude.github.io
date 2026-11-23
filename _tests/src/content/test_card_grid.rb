# frozen_string_literal: true

require_relative '../../test_helper'

# Checks card-grid markup through the Liquid tags that use it.
class TestCardGrid < Minitest::Test
  def test_renders_cards_in_given_order
    current = create_doc({ 'title' => 'Canonical Book' }, '/books/current/')
    old_review = create_doc(
      { 'title' => 'Old Review', 'canonical_url' => current.url, 'date' => Time.utc(2022, 1, 1) }, '/books/old/',
    )
    new_review = create_doc(
      { 'title' => 'New Review', 'canonical_url' => current.url, 'date' => Time.utc(2023, 1, 1) }, '/books/new/',
    )
    site = create_site({}, { 'books' => [current, old_review, new_review] })
    context = create_context({}, { site: site, page: current })

    output = Liquid::Template.parse('{% display_previous_reviews %}').render!(context)
    aside = Nokogiri::HTML5.fragment(output).at_css('aside.previous-reviews')
    assert_equal 'Previous Reviews', aside.at_css('h2.previous-reviews-headline').text
    cards = aside.css('ul.card-grid > li.book-card')
    assert_equal([new_review.url, old_review.url], cards.map { |card| card.at_css('.card-text a')['href'] })
    assert_includes cards.first.text, 'Review from January 01, 2023'
    assert_includes cards.last.text, 'Review from January 01, 2022'
  end

  def test_renders_multiple_posts_in_given_order
    first = create_doc({ 'title' => 'Post Alpha' }, '/posts/alpha/')
    second = create_doc({ 'title' => 'Post Beta' }, '/posts/beta/')
    site = create_site({}, {}, [], [first, second], { 'Tech' => [first, second] })
    context = create_context({}, { site: site })

    output = Liquid::Template.parse('{% display_category_posts topic="Tech" %}').render!(context)
    grids = Nokogiri::HTML5.fragment(output).css('ul.card-grid')
    assert_equal 1, grids.size
    cards = grids.first.css('li.article-card .card-text > a')
    assert_equal([first.url, second.url], cards.map { |card| card['href'] })
    assert_equal(['Post Alpha', 'Post Beta'], cards.map { |card| card.text.strip })
  end

  def test_renders_mixed_posts_and_books_in_order
    post = create_doc({ 'title' => 'Test Post', 'date' => Time.utc(2024, 5, 3) }, '/post/', '', nil, MockCollection.new([], 'posts'))
    book = create_doc({ 'title' => 'Test Book', 'date' => Time.utc(2024, 5, 1) }, '/book/', '', nil, MockCollection.new([], 'books'))
    unknown = create_doc(
      { 'title' => 'Unknown Item', 'date' => Time.utc(2024, 5, 2) }, '/unknown/', '', nil, MockCollection.new([], 'unknown'),
    )
    config = { 'plugin_logging' => { 'FRONT_PAGE_FEED' => true } }
    site = create_site(config, { 'books' => [book] }, [], [post, unknown])
    context = create_context({}, { site: site })

    template = Liquid::Template.parse('{% front_page_feed %}')
    output = Jekyll.stub(:logger, silent_logger) { template.render!(context) }

    warning, grid = output.split('<ul class="card-grid">', 2)
    assert_match(/\[WARN\] FRONT_PAGE_FEED_FAILURE/, warning)
    assert_includes warning, 'Unknown item type in feed.'
    assert_includes warning, 'Unknown Item'
    assert_includes grid, '</ul>'
    grids = Nokogiri::HTML5.fragment(output).css('ul.card-grid')
    assert_equal 1, grids.size
    cards = grids.first.css('li.article-card, li.book-card')
    assert_equal([post.url, book.url], cards.map { |card| card.at_css('.card-text > a')['href'] })
    refute_includes grid, 'Unknown Item'
  end
end
