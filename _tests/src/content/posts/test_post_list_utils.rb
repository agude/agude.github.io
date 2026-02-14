# frozen_string_literal: true

# _tests/plugins/utils/post_list_utils/test_post_list_utils.rb
require_relative '../../../test_helper'
# Jekyll::Posts::PostListUtils is loaded by test_helper

# Tests for Jekyll::Posts::PostListUtils module.
#
# Verifies that the utility correctly retrieves and filters posts by category.
class TestPostListUtils < Minitest::Test
  def setup
    create_test_posts
    @site_categories_data = build_site_categories
    @site = build_test_site
    @context = build_test_context
    @silent_logger_stub = create_silent_logger
  end

  # Helper to call the utility method under test
  def get_category_posts(category_name, exclude_url = nil, context = @context, site = @site)
    result = {}
    Jekyll.stub :logger, @silent_logger_stub do
      result = Jekyll::Posts::PostListUtils.get_posts_by_category(
        site: site,
        category_name: category_name,
        context: context,
        exclude_url: exclude_url,
      )
    end
    result
  end

  def test_get_posts_for_existing_category_tech
    result = get_category_posts('Tech')
    assert_valid_tech_posts_result(result)
  end

  def test_get_posts_for_existing_category_gadgets_case_insensitive
    result = get_category_posts('gadgets')
    assert_valid_gadgets_posts_result(result)
  end

  def test_get_posts_excludes_url
    result = get_category_posts('Tech', @post1_tech_gadgets.url)
    assert_empty result[:log_messages].to_s
    assert_equal 1, result[:posts].size
    assert_equal @post2_tech_recent.data['title'], result[:posts][0].data['title']
  end

  def test_get_posts_category_not_found_logs_info
    @site.config['plugin_logging']['POST_LIST_UTIL_CATEGORY'] = true
    result = get_category_posts('NonExistentCategory')
    assert_empty result[:posts]
    expected_pattern = build_category_not_found_pattern
    assert_match expected_pattern, result[:log_messages]
  end

  def test_get_posts_category_exists_but_no_published_posts_logs_info
    site_only_unpub = build_site_with_unpublished_only
    context_only_unpub = build_context_for_site(site_only_unpub)
    result = get_category_posts('Tech', nil, context_only_unpub, site_only_unpub)
    assert_empty result[:posts]
    expected_pattern = build_no_posts_after_filtering_pattern
    assert_match expected_pattern, result[:log_messages]
  end

  def test_get_posts_category_exists_but_all_excluded_logs_info
    site_one_tech_post = build_site_with_one_post
    context_one_tech_post = build_context_for_site(site_one_tech_post)
    result = get_category_posts('Tech', @post2_tech_recent.url, context_one_tech_post, site_one_tech_post)
    assert_empty result[:posts]
    expected_pattern = build_all_excluded_pattern
    assert_match expected_pattern, result[:log_messages]
  end

  def test_get_posts_nil_category_name_logs_warn
    @site.config['plugin_logging']['POST_LIST_UTIL_CATEGORY'] = true
    result = get_category_posts(nil)
    assert_empty result[:posts]
    expected_pattern = build_nil_category_pattern
    assert_match expected_pattern, result[:log_messages]
  end

  def test_get_posts_empty_category_name_logs_warn
    @site.config['plugin_logging']['POST_LIST_UTIL_CATEGORY'] = true
    result = get_category_posts('   ')
    assert_empty result[:posts]
    expected_pattern = build_empty_category_pattern
    assert_match expected_pattern, result[:log_messages]
  end

  def test_get_posts_category_exists_in_keys_but_empty_array
    # This tests lines 66-67 and the branch on line 37 (then path)
    # Create a site where the category key exists but the array is empty
    site_empty_category = create_site(
      {}, {}, [], [], { 'EmptyCategory' => [] },
    )
    site_empty_category.config['plugin_logging']['POST_LIST_UTIL_CATEGORY'] = true
    context = build_context_for_site(site_empty_category)

    result = get_category_posts('EmptyCategory', nil, context, site_empty_category)
    assert_empty result[:posts]
    # Should log "No posts found in category"
    assert_match(
      /\[INFO\] POST_LIST_UTIL_CATEGORY_FAILURE: Reason='No posts found in category\.'/,
      result[:log_messages],
    )
  end

  private

  def create_test_posts
    @post1_tech_gadgets = create_doc(
      {
        'title' => 'Tech & Gadgets Post 1',
        'categories' => %w[Tech Gadgets],
        'date' => Time.parse('2024-03-15'),
        'published' => true,
      },
      '/tech/post1.html',
    )
    @post2_tech_recent = create_doc(
      {
        'title' => 'Tech Post Recent',
        'categories' => ['Tech'],
        'date' => Time.parse('2024-03-20'),
        'published' => true,
      },
      '/tech/post2.html',
    )
    @post3_gadgets_only = create_doc(
      {
        'title' => 'Gadgets Only Post',
        'categories' => ['Gadgets'],
        'date' => Time.parse('2024-03-01'),
        'published' => true,
      },
      '/gadgets/post3.html',
    )
    @post4_tech_unpublished = create_doc(
      {
        'title' => 'Tech Post Unpublished',
        'categories' => ['Tech'],
        'date' => Time.parse('2024-02-01'),
        'published' => false,
      },
      '/tech/post4.html',
    )
    @post5_other = create_doc(
      {
        'title' => 'Other Category Post',
        'categories' => ['Other'],
        'date' => Time.parse('2024-03-05'),
        'published' => true,
      },
      '/other/post5.html',
    )
  end

  def build_site_categories
    # site.categories is a hash where keys are category names and values are arrays of posts
    {
      'Tech' => [@post2_tech_recent, @post1_tech_gadgets, @post4_tech_unpublished].sort_by(&:date).reverse,
      'Gadgets' => [@post1_tech_gadgets, @post3_gadgets_only].sort_by(&:date).reverse,
      'Other' => [@post5_other].sort_by(&:date).reverse,
    }
  end

  def build_test_site
    all_posts = [
      @post1_tech_gadgets,
      @post2_tech_recent,
      @post3_gadgets_only,
      @post4_tech_unpublished,
      @post5_other,
    ]
    create_site({}, {}, [], all_posts, @site_categories_data)
  end

  def build_test_context
    page = create_doc({ 'path' => 'current_page.html' }, '/current_page.html')
    create_context({}, { site: @site, page: page })
  end

  def create_silent_logger
    Object.new.tap do |logger|
      def logger.warn(topic, message); end
      def logger.error(topic, message); end
      def logger.info(topic, message); end
      def logger.debug(topic, message); end
    end
  end

  def assert_valid_tech_posts_result(result)
    assert_empty result[:log_messages].to_s
    # @post2_tech_recent, @post1_tech_gadgets (@post4 is unpublished)
    assert_equal 2, result[:posts].size
    # Most recent first
    assert_equal @post2_tech_recent.data['title'], result[:posts][0].data['title']
    assert_equal @post1_tech_gadgets.data['title'], result[:posts][1].data['title']
  end

  def assert_valid_gadgets_posts_result(result)
    # Test with lowercase input, should match 'Gadgets'
    assert_empty result[:log_messages].to_s
    assert_equal 2, result[:posts].size
    # Order: @post1_tech_gadgets (Mar 15), then @post3_gadgets_only (Mar 01)
    assert_equal @post1_tech_gadgets.data['title'], result[:posts][0].data['title']
    assert_equal @post3_gadgets_only.data['title'], result[:posts][1].data['title']
  end

  def build_category_not_found_pattern
    /<!-- \[INFO\] POST_LIST_UTIL_CATEGORY_FAILURE: Reason='Category not found\.' /
  end

  def build_no_posts_after_filtering_pattern
    pattern_str = '<!-- \[INFO\] POST_LIST_UTIL_CATEGORY_FAILURE: ' \
                  'Reason=\'No posts found in category after filtering ' \
                  '\(e\.g\., excluded current page or unpublished\)\.\' ' \
                  'category_name=\'Tech\' ' \
                  'excluded_url=\'N/A\' ' \
                  'SourcePage=\'current_page\.html\' -->'
    Regexp.new(pattern_str)
  end

  def build_all_excluded_pattern
    pattern_str = '<!-- \[INFO\] POST_LIST_UTIL_CATEGORY_FAILURE: ' \
                  'Reason=\'No posts found in category after filtering ' \
                  '\(e\.g\., excluded current page or unpublished\)\.\' ' \
                  'category_name=\'Tech\' ' \
                  "excluded_url='#{@post2_tech_recent.url}' " \
                  'SourcePage=\'current_page\.html\' -->'
    Regexp.new(pattern_str)
  end

  def build_nil_category_pattern
    pattern_str = '<!-- \[WARN\] POST_LIST_UTIL_CATEGORY_FAILURE: ' \
                  'Reason=\'Category name was nil or empty\.\' ' \
                  'category_input=\'N/A\' ' \
                  'SourcePage=\'current_page\.html\' -->'
    Regexp.new(pattern_str)
  end

  def build_empty_category_pattern
    pattern_str = '<!-- \[WARN\] POST_LIST_UTIL_CATEGORY_FAILURE: ' \
                  'Reason=\'Category name was nil or empty\.\' ' \
                  'category_input=\'   \' ' \
                  'SourcePage=\'current_page\.html\' -->'
    Regexp.new(pattern_str)
  end

  def build_site_with_unpublished_only
    site_only_unpub = create_site(
      {}, {}, [], [@post4_tech_unpublished], { 'Tech' => [@post4_tech_unpublished] },
    )
    site_only_unpub.config['plugin_logging']['POST_LIST_UTIL_CATEGORY'] = true
    site_only_unpub
  end

  def build_site_with_one_post
    site_one_tech_post = create_site(
      {}, {}, [], [@post2_tech_recent], { 'Tech' => [@post2_tech_recent] },
    )
    site_one_tech_post.config['plugin_logging']['POST_LIST_UTIL_CATEGORY'] = true
    site_one_tech_post
  end

  def build_context_for_site(site)
    page = create_doc({ 'path' => 'current_page.html' })
    create_context({}, { site: site, page: page })
  end
end
