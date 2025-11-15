# _tests/plugins/utils/post_list_utils/test_post_list_utils.rb
require_relative '../../../test_helper'
# PostListUtils is loaded by test_helper

class TestPostListUtils < Minitest::Test
  def setup
    @post1_tech_gadgets = create_doc(
      { 'title' => 'Tech & Gadgets Post 1', 'categories' => %w[Tech Gadgets], 'date' => Time.parse('2024-03-15'),
        'published' => true },
      '/tech/post1.html'
    )
    @post2_tech_recent = create_doc(
      { 'title' => 'Tech Post Recent', 'categories' => ['Tech'], 'date' => Time.parse('2024-03-20'),
        'published' => true },
      '/tech/post2.html'
    )
    @post3_gadgets_only = create_doc(
      { 'title' => 'Gadgets Only Post', 'categories' => ['Gadgets'], 'date' => Time.parse('2024-03-01'),
        'published' => true },
      '/gadgets/post3.html'
    )
    @post4_tech_unpublished = create_doc(
      { 'title' => 'Tech Post Unpublished', 'categories' => ['Tech'], 'date' => Time.parse('2024-02-01'),
        'published' => false },
      '/tech/post4.html'
    )
    @post5_other = create_doc(
      { 'title' => 'Other Category Post', 'categories' => ['Other'], 'date' => Time.parse('2024-03-05'),
        'published' => true },
      '/other/post5.html'
    )

    # site.categories is a hash where keys are category names (case-sensitive as Jekyll stores them)
    # and values are arrays of post objects, sorted by date descending.
    @site_categories_data = {
      'Tech' => [@post2_tech_recent, @post1_tech_gadgets, @post4_tech_unpublished].sort_by(&:date).reverse,
      'Gadgets' => [@post1_tech_gadgets, @post3_gadgets_only].sort_by(&:date).reverse,
      'Other' => [@post5_other].sort_by(&:date).reverse
    }

    @site = create_site(
      {}, # config
      {}, # collections
      [], # pages
      [@post1_tech_gadgets, @post2_tech_recent, @post3_gadgets_only, @post4_tech_unpublished, @post5_other], # site.posts.docs
      @site_categories_data # site.categories
    )
    @context = create_context({},
                              { site: @site,
                                page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
  end

  # Helper to call the utility method under test
  def get_category_posts(category_name, exclude_url = nil, context = @context, site = @site)
    result = {}
    Jekyll.stub :logger, @silent_logger_stub do
      result = PostListUtils.get_posts_by_category(
        site: site,
        category_name: category_name,
        context: context,
        exclude_url: exclude_url
      )
    end
    result
  end

  def test_get_posts_for_existing_category_tech
    result = get_category_posts('Tech')
    assert_empty result[:log_messages].to_s
    assert_equal 2, result[:posts].size # @post2_tech_recent, @post1_tech_gadgets (@post4 is unpublished)
    assert_equal @post2_tech_recent.data['title'], result[:posts][0].data['title'] # Most recent
    assert_equal @post1_tech_gadgets.data['title'], result[:posts][1].data['title']
  end

  def test_get_posts_for_existing_category_gadgets_case_insensitive
    # Test with lowercase input, should match 'Gadgets'
    result = get_category_posts('gadgets')
    assert_empty result[:log_messages].to_s
    assert_equal 2, result[:posts].size
    # Order: @post1_tech_gadgets (Mar 15), then @post3_gadgets_only (Mar 01)
    assert_equal @post1_tech_gadgets.data['title'], result[:posts][0].data['title']
    assert_equal @post3_gadgets_only.data['title'], result[:posts][1].data['title']
  end

  def test_get_posts_excludes_url
    result = get_category_posts('Tech', @post1_tech_gadgets.url) # Exclude Tech & Gadgets Post 1
    assert_empty result[:log_messages].to_s
    assert_equal 1, result[:posts].size
    assert_equal @post2_tech_recent.data['title'], result[:posts][0].data['title']
  end

  def test_get_posts_category_not_found_logs_info
    @site.config['plugin_logging']['POST_LIST_UTIL_CATEGORY'] = true
    result = get_category_posts('NonExistentCategory')
    assert_empty result[:posts]
    assert_match(/<!-- \[INFO\] POST_LIST_UTIL_CATEGORY_FAILURE: Reason='Category not found\.'\s*category_name='NonExistentCategory'\s*SourcePage='current_page\.html' -->/,
                 result[:log_messages])
  end

  def test_get_posts_category_exists_but_no_published_posts_logs_info
    # Create a site where 'Tech' category only has the unpublished post
    site_only_unpub = create_site(
      {}, {}, [], [@post4_tech_unpublished], { 'Tech' => [@post4_tech_unpublished] }
    )
    site_only_unpub.config['plugin_logging']['POST_LIST_UTIL_CATEGORY'] = true
    context_only_unpub = create_context({},
                                        { site: site_only_unpub, page: create_doc({ 'path' => 'current_page.html' }) })

    result = get_category_posts('Tech', nil, context_only_unpub, site_only_unpub)
    assert_empty result[:posts]
    # This log is for "No posts found in category after filtering"
    assert_match %r{<!-- \[INFO\] POST_LIST_UTIL_CATEGORY_FAILURE: Reason='No posts found in category after filtering \(e\.g\., excluded current page or unpublished\)\.'\s*category_name='Tech'\s*excluded_url='N/A'\s*SourcePage='current_page\.html' -->},
                 result[:log_messages]
  end

  def test_get_posts_category_exists_but_all_excluded_logs_info
    @site.config['plugin_logging']['POST_LIST_UTIL_CATEGORY'] = true
    # Exclude both published 'Tech' posts
    # To do this properly, we need to pass multiple exclude URLs or modify the test data.
    # For simplicity, let's test excluding the only remaining post after unpublishing one.
    # Here, we exclude @post2_tech_recent, and @post1_tech_gadgets is also in 'Tech'.
    # If we exclude @post2_tech_recent, @post1_tech_gadgets should remain.
    # To test "all excluded", we need a category with one post and exclude that one.

    site_one_tech_post = create_site(
      {}, {}, [], [@post2_tech_recent], { 'Tech' => [@post2_tech_recent] } # Only one post in Tech
    )
    site_one_tech_post.config['plugin_logging']['POST_LIST_UTIL_CATEGORY'] = true
    context_one_tech_post = create_context({},
                                           { site: site_one_tech_post,
                                             page: create_doc({ 'path' => 'current_page.html' }) })

    result = get_category_posts('Tech', @post2_tech_recent.url, context_one_tech_post, site_one_tech_post)
    assert_empty result[:posts]
    assert_match(/<!-- \[INFO\] POST_LIST_UTIL_CATEGORY_FAILURE: Reason='No posts found in category after filtering \(e\.g\., excluded current page or unpublished\)\.'\s*category_name='Tech'\s*excluded_url='#{@post2_tech_recent.url}'\s*SourcePage='current_page\.html' -->/,
                 result[:log_messages])
  end

  def test_get_posts_nil_category_name_logs_warn
    @site.config['plugin_logging']['POST_LIST_UTIL_CATEGORY'] = true
    result = get_category_posts(nil)
    assert_empty result[:posts]
    assert_match %r{<!-- \[WARN\] POST_LIST_UTIL_CATEGORY_FAILURE: Reason='Category name was nil or empty\.'\s*category_input='N/A'\s*SourcePage='current_page\.html' -->},
                 result[:log_messages]
  end

  def test_get_posts_empty_category_name_logs_warn
    @site.config['plugin_logging']['POST_LIST_UTIL_CATEGORY'] = true
    result = get_category_posts('   ')
    assert_empty result[:posts]
    assert_match(/<!-- \[WARN\] POST_LIST_UTIL_CATEGORY_FAILURE: Reason='Category name was nil or empty\.'\s*category_input='   '\s*SourcePage='current_page\.html' -->/,
                 result[:log_messages])
  end
end
