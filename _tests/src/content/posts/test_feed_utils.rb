# frozen_string_literal: true

# _tests/plugins/utils/test_feed_utils.rb
require_relative '../../../test_helper'
# Jekyll::Posts::FeedUtils is loaded by test_helper

# Tests for Jekyll::Posts::FeedUtils module.
#
# Verifies that the utility correctly combines and sorts posts and books for feed display.
class TestFeedUtils < Minitest::Test
  def setup
    @ref_time = Time.parse('2024-06-01 12:00:00 UTC')

    # Posts
    post1_data = { 'title' => 'Post 1 (Recent)', 'date' => @ref_time - (1 * 24 * 60 * 60), 'published' => true }
    post2_data = { 'title' => 'Post 2 (Old)', 'date' => @ref_time - (10 * 24 * 60 * 60), 'published' => true }
    post_unpub_data = {
      'title' => 'Post Unpublished', 'date' => @ref_time - (3 * 24 * 60 * 60), 'published' => false
    }
    posts_collection = MockCollection.new(nil, 'posts')
    @post1 = create_doc(post1_data, '/p1.html', 'content', nil, posts_collection) # May 31
    @post2 = create_doc(post2_data, '/p2.html', 'content', nil, posts_collection) # May 22
    @post_unpub = create_doc(post_unpub_data, '/punpub.html', 'content', nil, posts_collection) # May 29
    @post_no_date_val_template = { 'title' => 'Post No Date Val', 'published' => true } # Date will be Time.now

    # Books
    book1_data = { 'title' => 'Book 1 (Mid)', 'date' => @ref_time - (2 * 24 * 60 * 60), 'published' => true }
    book2_data = { 'title' => 'Book 2 (Oldest)', 'date' => @ref_time - (20 * 24 * 60 * 60), 'published' => true }
    book_unpub_data = {
      'title' => 'Book Unpublished', 'date' => @ref_time - (5 * 24 * 60 * 60), 'published' => false
    }
    books_collection = MockCollection.new(nil, 'books')
    @book1 = create_doc(book1_data, '/b1.html', 'content', nil, books_collection) # May 30
    @book2 = create_doc(book2_data, '/b2.html', 'content', nil, books_collection) # May 12
    @book_unpub = create_doc(book_unpub_data, '/bunpub.html', 'content', nil, books_collection) # May 27
    @book_no_date_val_template = { 'title' => 'Book No Date Val', 'published' => true } # Date will be Time.now

    # Initial collections for a generic site setup. Specific tests might override these.
    # These initial collections include unpublished items.
    @mock_posts_collection_initial = MockCollection.new([@post1, @post2, @post_unpub], 'posts')
    @mock_books_collection_initial = MockCollection.new([@book1, @book2, @book_unpub], 'books')

    @site = create_site(
      {},
      { 'books' => @mock_books_collection_initial.docs }, # Pass docs array
      [],
      @mock_posts_collection_initial.docs # Pass docs array
    )
    @site.posts = @mock_posts_collection_initial # Assign MockCollection instance
  end

  def test_get_combined_feed_items_default_limit
    fixed_current_time = @ref_time + (1 * 24 * 60 * 60) # June 2nd, most recent

    Time.stub :now, fixed_current_time do
      post_no_date, book_no_date, temp_site = create_test_site_with_current_date_docs

      items = Jekyll::Posts::FeedUtils.get_combined_feed_items(site: temp_site)

      assert_equal 5, items.size, 'Should return default limit of 5 items'
      actual_titles = items.map { |item| item.data['title'] }

      expected_sorted = [post_no_date.data['title'], book_no_date.data['title']].sort
      actual_sorted = [actual_titles[0], actual_titles[1]].sort
      msg = 'The two most recent items (with identical dates) are not correct or not at the start'
      assert_equal expected_sorted, actual_sorted, msg

      assert_equal @post1.data['title'], actual_titles[2]
      assert_equal @book1.data['title'], actual_titles[3]
      assert_equal @post2.data['title'], actual_titles[4]

      assert_items_sorted_descending_by_date(items)
    end
  end

  private

  # Helper to create a site with documents that have current date
  def create_test_site_with_current_date_docs
    post_no_date_current = create_doc(@post_no_date_val_template, '/pnodate.html', 'content', nil,
                                      MockCollection.new(nil, 'posts'))
    book_no_date_current = create_doc(@book_no_date_val_template, '/bnodate.html', 'content', nil,
                                      MockCollection.new(nil, 'books'))

    current_test_posts = [@post1, @post2, post_no_date_current]
    current_test_books = [@book1, @book2, book_no_date_current]

    temp_posts_collection = MockCollection.new(current_test_posts, 'posts')
    temp_books_collection = MockCollection.new(current_test_books, 'books')
    temp_site = create_site({}, { 'books' => temp_books_collection.docs }, [], temp_posts_collection.docs)
    temp_site.posts = temp_posts_collection

    [post_no_date_current, book_no_date_current, temp_site]
  end

  # Helper to assert items are sorted in descending order by date
  def assert_items_sorted_descending_by_date(items)
    (items.size - 1).times do |i|
      current_title = items[i].data['title']
      current_date = items[i].date
      next_title = items[i + 1].data['title']
      next_date = items[i + 1].date
      error_msg = "Items not sorted by date descending: #{current_title} " \
                  "( #{current_date} ) vs #{next_title} ( #{next_date} )"
      assert items[i].date >= items[i + 1].date, error_msg
    end
  end

  def test_get_combined_feed_items_custom_limit
    fixed_current_time = @ref_time + (1 * 24 * 60 * 60)
    Time.stub :now, fixed_current_time do
      post_no_date, book_no_date, temp_site = create_test_site_with_current_date_docs

      items = Jekyll::Posts::FeedUtils.get_combined_feed_items(site: temp_site, limit: 3)
      assert_equal 3, items.size
      actual_titles = items.map { |item| item.data['title'] }

      expected_sorted = [post_no_date.data['title'], book_no_date.data['title']].sort
      actual_sorted = [actual_titles[0], actual_titles[1]].sort
      assert_equal expected_sorted, actual_sorted
      assert_equal @post1.data['title'], actual_titles[2]
    end
  end

  def test_get_combined_feed_items_filters_unpublished
    fixed_current_time = @ref_time + (1 * 24 * 60 * 60) # Ensure "now" is most recent
    Time.stub :now, fixed_current_time do
      _, book_no_date, temp_site = create_test_site_with_unpublished_docs

      items = Jekyll::Posts::FeedUtils.get_combined_feed_items(site: temp_site, limit: 10) # High limit
      titles = items.map { |item| item.data['title'] }

      refute_includes titles, @post_unpub.data['title']
      refute_includes titles, @book_unpub.data['title']
      assert_includes titles, @post1.data['title']
      assert_includes titles, book_no_date.data['title']

      # Published posts: post1, post2, post_no_date_current
      assert_equal 3, items.select { |item| item.collection.label == 'posts' }.count
      # Published books: book1, book2, book_no_date_current
      assert_equal 3, items.select { |item| item.collection.label == 'books' }.count
      assert_equal 6, items.size # Total published items
    end
  end

  # Helper to create a site with unpublished documents
  def create_test_site_with_unpublished_docs
    post_no_date_current = create_doc(@post_no_date_val_template, '/pnodate.html', 'content', nil,
                                      MockCollection.new(nil, 'posts'))
    book_no_date_current = create_doc(@book_no_date_val_template, '/bnodate.html', 'content', nil,
                                      MockCollection.new(nil, 'books'))

    # Include unpublished items in the source collections for this test
    all_test_posts = [@post1, @post2, @post_unpub, post_no_date_current]
    all_test_books = [@book1, @book2, @book_unpub, book_no_date_current]

    temp_posts_collection = MockCollection.new(all_test_posts, 'posts')
    temp_books_collection = MockCollection.new(all_test_books, 'books')
    temp_site = create_site({}, { 'books' => temp_books_collection.docs }, [], temp_posts_collection.docs)
    temp_site.posts = temp_posts_collection

    [post_no_date_current, book_no_date_current, temp_site]
  end

  def test_get_combined_feed_items_handles_missing_posts_collection
    # Setup site with books but nil posts
    site_no_posts = create_site({}, { 'books' => @mock_books_collection_initial.docs }, [], [])
    site_no_posts.posts = nil

    items = Jekyll::Posts::FeedUtils.get_combined_feed_items(site: site_no_posts, limit: 5)
    # Expected: @book1, @book2 (original @book_no_date_val not in this site's setup for books)
    # @mock_books_collection_initial contains @book1, @book2, @book_unpub
    # So, 2 published books.
    assert_equal 2, items.size
    titles = items.map { |i| i.data['title'] }
    assert_includes titles, @book1.data['title']
    assert_includes titles, @book2.data['title']
  end

  def test_get_combined_feed_items_handles_missing_books_collection
    # Setup site with posts but no books collection
    site_no_books = create_site({}, {}, [], @mock_posts_collection_initial.docs)
    site_no_books.collections.delete('books')

    items = Jekyll::Posts::FeedUtils.get_combined_feed_items(site: site_no_books, limit: 5)
    # Expected: @post1, @post2
    assert_equal 2, items.size
    titles = items.map { |i| i.data['title'] }
    assert_includes titles, @post1.data['title']
    assert_includes titles, @post2.data['title']
  end

  def test_get_combined_feed_items_empty_if_no_valid_items
    post_unpub_only = create_doc({ 'published' => false, 'date' => Time.now }, '/p.html', 'c', nil,
                                 MockCollection.new(nil, 'posts'))
    book_unpub_only = create_doc({ 'published' => false, 'date' => Time.now }, '/b.html', 'c', nil,
                                 MockCollection.new(nil, 'books'))

    site_empty = create_site({}, { 'books' => [book_unpub_only] }, [], [post_unpub_only])
    site_empty.posts = MockCollection.new([post_unpub_only], 'posts')

    items = Jekyll::Posts::FeedUtils.get_combined_feed_items(site: site_empty, limit: 5)
    assert_empty items, 'Expected no items when all are unpublished'
  end

  def test_get_combined_feed_items_handles_items_without_time_date_object
    bad_post_data = { 'title' => 'Post Bad Date', 'published' => true }
    post_bad_date_obj = create_doc(bad_post_data, '/pbad.html', 'c', nil, MockCollection.new(nil, 'posts'))
    post_bad_date_obj.data['date'] = 'Not a Time object'
    post_bad_date_obj.define_singleton_method(:date) { data['date'] }

    book_data = { 'title' => 'Valid Book', 'date' => Time.parse('2024-01-01'), 'published' => true }
    book_valid_date = create_doc(book_data, '/bvalid.html', 'c', nil, MockCollection.new(nil, 'books'))

    site_with_bad_date = create_site(
      {},
      { 'books' => [book_valid_date] },
      [],
      [post_bad_date_obj]
    )
    site_with_bad_date.posts = MockCollection.new([post_bad_date_obj], 'posts')

    items = Jekyll::Posts::FeedUtils.get_combined_feed_items(site: site_with_bad_date, limit: 5)
    assert_equal 1, items.size
    assert_equal book_valid_date.data['title'], items[0].data['title']
  end
end
