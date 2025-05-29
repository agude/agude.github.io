# _tests/plugins/utils/test_feed_utils.rb
require_relative '../../test_helper'
# FeedUtils is loaded by test_helper

class TestFeedUtils < Minitest::Test
  def setup
    @ref_time = Time.parse("2024-06-01 12:00:00 UTC")

    # Posts
    @post1 = create_doc({ 'title' => 'Post 1 (Recent)', 'date' => @ref_time - (1 * 24 * 60 * 60), 'published' => true }, '/p1.html', 'content', nil, MockCollection.new(nil, 'posts')) # May 31
    @post2 = create_doc({ 'title' => 'Post 2 (Old)', 'date' => @ref_time - (10 * 24 * 60 * 60), 'published' => true }, '/p2.html', 'content', nil, MockCollection.new(nil, 'posts')) # May 22
    @post_unpub = create_doc({ 'title' => 'Post Unpublished', 'date' => @ref_time - (3 * 24 * 60 * 60), 'published' => false }, '/punpub.html', 'content', nil, MockCollection.new(nil, 'posts')) # May 29
    @post_no_date_val_template = { 'title' => 'Post No Date Val', 'published' => true } # Date will be Time.now

    # Books
    @book1 = create_doc({ 'title' => 'Book 1 (Mid)', 'date' => @ref_time - (2 * 24 * 60 * 60), 'published' => true }, '/b1.html', 'content', nil, MockCollection.new(nil, 'books')) # May 30
    @book2 = create_doc({ 'title' => 'Book 2 (Oldest)', 'date' => @ref_time - (20 * 24 * 60 * 60), 'published' => true }, '/b2.html', 'content', nil, MockCollection.new(nil, 'books')) # May 12
    @book_unpub = create_doc({ 'title' => 'Book Unpublished', 'date' => @ref_time - (5 * 24 * 60 * 60), 'published' => false }, '/bunpub.html', 'content', nil, MockCollection.new(nil, 'books')) # May 27
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
      post_no_date_current = create_doc(@post_no_date_val_template, '/pnodate.html', 'content', nil, MockCollection.new(nil, 'posts'))
      book_no_date_current = create_doc(@book_no_date_val_template, '/bnodate.html', 'content', nil, MockCollection.new(nil, 'books'))

      current_test_posts = [@post1, @post2, post_no_date_current] # Only published posts with valid/defaulted dates
      current_test_books = [@book1, @book2, book_no_date_current] # Only published books with valid/defaulted dates
      
      temp_posts_collection = MockCollection.new(current_test_posts, 'posts')
      temp_books_collection = MockCollection.new(current_test_books, 'books')
      temp_site = create_site({}, { 'books' => temp_books_collection.docs }, [], temp_posts_collection.docs)
      temp_site.posts = temp_posts_collection

      items = FeedUtils.get_combined_feed_items(site: temp_site)
      
      assert_equal 5, items.size, "Should return default limit of 5 items"
      actual_titles = items.map { |item| item.data['title'] }
      
      expected_first_two_titles_sorted = [post_no_date_current.data['title'], book_no_date_current.data['title']].sort
      actual_first_two_titles_sorted = [actual_titles[0], actual_titles[1]].sort
      assert_equal expected_first_two_titles_sorted, actual_first_two_titles_sorted, "The two most recent items (with identical dates) are not correct or not at the start"
      
      assert_equal @post1.data['title'], actual_titles[2]
      assert_equal @book1.data['title'], actual_titles[3]
      assert_equal @post2.data['title'], actual_titles[4]

      (items.size - 1).times do |i|
        assert items[i].date >= items[i+1].date, "Items not sorted by date descending: #{items[i].data['title']} ( #{items[i].date} ) vs #{items[i+1].data['title']} ( #{items[i+1].date} )"
      end
    end
  end

  def test_get_combined_feed_items_custom_limit
    fixed_current_time = @ref_time + (1 * 24 * 60 * 60)
    Time.stub :now, fixed_current_time do
      post_no_date_current = create_doc(@post_no_date_val_template, '/pnodate.html', 'content', nil, MockCollection.new(nil, 'posts'))
      book_no_date_current = create_doc(@book_no_date_val_template, '/bnodate.html', 'content', nil, MockCollection.new(nil, 'books'))
      
      current_test_posts = [@post1, @post2, post_no_date_current]
      current_test_books = [@book1, @book2, book_no_date_current]
      temp_posts_collection = MockCollection.new(current_test_posts, 'posts')
      temp_books_collection = MockCollection.new(current_test_books, 'books')
      temp_site = create_site({}, { 'books' => temp_books_collection.docs }, [], temp_posts_collection.docs)
      temp_site.posts = temp_posts_collection

      items = FeedUtils.get_combined_feed_items(site: temp_site, limit: 3)
      assert_equal 3, items.size
      actual_titles = items.map { |item| item.data['title'] }

      expected_first_two_titles_sorted = [post_no_date_current.data['title'], book_no_date_current.data['title']].sort
      actual_first_two_titles_sorted = [actual_titles[0], actual_titles[1]].sort
      assert_equal expected_first_two_titles_sorted, actual_first_two_titles_sorted
      assert_equal @post1.data['title'], actual_titles[2]
    end
  end

  def test_get_combined_feed_items_filters_unpublished
    fixed_current_time = @ref_time + (1 * 24 * 60 * 60) # Ensure "now" is most recent
    Time.stub :now, fixed_current_time do
        post_no_date_current = create_doc(@post_no_date_val_template, '/pnodate.html', 'content', nil, MockCollection.new(nil, 'posts'))
        book_no_date_current = create_doc(@book_no_date_val_template, '/bnodate.html', 'content', nil, MockCollection.new(nil, 'books'))
        
        # Include unpublished items in the source collections for this test
        all_test_posts = [@post1, @post2, @post_unpub, post_no_date_current]
        all_test_books = [@book1, @book2, @book_unpub, book_no_date_current]
        
        temp_posts_collection = MockCollection.new(all_test_posts, 'posts')
        temp_books_collection = MockCollection.new(all_test_books, 'books')
        temp_site = create_site({}, { 'books' => temp_books_collection.docs }, [], temp_posts_collection.docs)
        temp_site.posts = temp_posts_collection

        items = FeedUtils.get_combined_feed_items(site: temp_site, limit: 10) # High limit
        titles = items.map { |item| item.data['title'] }
        
        refute_includes titles, @post_unpub.data['title']
        refute_includes titles, @book_unpub.data['title']
        assert_includes titles, @post1.data['title']
        assert_includes titles, book_no_date_current.data['title']
        
        # Published posts: post1, post2, post_no_date_current
        assert_equal 3, items.select{|item| item.collection.label == 'posts'}.count
        # Published books: book1, book2, book_no_date_current
        assert_equal 3, items.select{|item| item.collection.label == 'books'}.count
        assert_equal 6, items.size # Total published items
    end
  end

  def test_get_combined_feed_items_handles_missing_posts_collection
    # Setup site with books but nil posts
    site_no_posts = create_site({}, { 'books' => @mock_books_collection_initial.docs }, [], [])
    site_no_posts.posts = nil

    items = FeedUtils.get_combined_feed_items(site: site_no_posts, limit: 5)
    # Expected: @book1, @book2 (original @book_no_date_val not in this site's setup for books)
    # @mock_books_collection_initial contains @book1, @book2, @book_unpub
    # So, 2 published books.
    assert_equal 2, items.size
    titles = items.map{|i| i.data['title']}
    assert_includes titles, @book1.data['title']
    assert_includes titles, @book2.data['title']
  end

  def test_get_combined_feed_items_handles_missing_books_collection
    # Setup site with posts but no books collection
    site_no_books = create_site({}, {}, [], @mock_posts_collection_initial.docs)
    site_no_books.collections.delete('books')

    items = FeedUtils.get_combined_feed_items(site: site_no_books, limit: 5)
    # Expected: @post1, @post2
    assert_equal 2, items.size
    titles = items.map{|i| i.data['title']}
    assert_includes titles, @post1.data['title']
    assert_includes titles, @post2.data['title']
  end

  def test_get_combined_feed_items_empty_if_no_valid_items
    post_unpub_only = create_doc({'published'=>false, 'date'=>Time.now }, '/p.html', 'c', nil, MockCollection.new(nil, 'posts'))
    book_unpub_only = create_doc({'published'=>false, 'date'=>Time.now }, '/b.html', 'c', nil, MockCollection.new(nil, 'books'))
    
    site_empty = create_site( {}, { 'books' => [book_unpub_only] }, [], [post_unpub_only] )
    site_empty.posts = MockCollection.new([post_unpub_only], 'posts')

    items = FeedUtils.get_combined_feed_items(site: site_empty, limit: 5)
    assert_empty items, "Expected no items when all are unpublished"
  end

  def test_get_combined_feed_items_handles_items_without_time_date_object
    post_bad_date_obj = create_doc({ 'title' => 'Post Bad Date', 'published' => true }, '/pbad.html', 'c', nil, MockCollection.new(nil, 'posts'))
    post_bad_date_obj.data['date'] = "Not a Time object"
    post_bad_date_obj.define_singleton_method(:date) { self.data['date'] }

    book_valid_date = create_doc({ 'title' => 'Valid Book', 'date' => Time.parse("2024-01-01"), 'published' => true }, '/bvalid.html', 'c', nil, MockCollection.new(nil, 'books'))

    site_with_bad_date = create_site(
        {},
        {'books' => [book_valid_date]},
        [],
        [post_bad_date_obj]
    )
    site_with_bad_date.posts = MockCollection.new([post_bad_date_obj], 'posts')

    items = FeedUtils.get_combined_feed_items(site: site_with_bad_date, limit: 5)
    assert_equal 1, items.size
    assert_equal book_valid_date.data['title'], items[0].data['title']
  end
end