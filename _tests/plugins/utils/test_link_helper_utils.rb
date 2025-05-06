# _tests/plugins/utils/test_link_helper_utils.rb
require_relative '../../test_helper'
require_relative '../../../_plugins/utils/link_helper_utils' # Load the specific utils

class TestLinkHelperUtils < Minitest::Test

  # --- Tests for _get_link_display_text ---

  def test_get_display_text_basic_input
    assert_equal "Input Text", LinkHelperUtils._get_link_display_text(" Input Text ", nil, nil)
  end

  def test_get_display_text_with_override
    doc = create_doc({ 'title' => 'Canonical Title' })
    # The helper now strips the override text
    assert_equal "Override Text", LinkHelperUtils._get_link_display_text("Input", " Override Text ", doc)
  end

  def test_get_display_text_with_found_doc_no_override
    doc = create_doc({ 'title' => ' Canonical Title ' })
    assert_equal "Canonical Title", LinkHelperUtils._get_link_display_text("Input", nil, doc)
  end

  def test_get_display_text_with_found_doc_empty_title
    doc = create_doc({ 'title' => '  ' })
    # Should fall back to input text because canonical title is empty after stripping
    assert_equal "Input Text", LinkHelperUtils._get_link_display_text(" Input Text ", nil, doc)
  end

  def test_get_display_text_with_found_doc_nil_title
    doc = create_doc({ 'title' => nil })
    assert_equal "Input Text", LinkHelperUtils._get_link_display_text(" Input Text ", nil, doc)
  end

  def test_get_display_text_with_found_doc_no_title_key
    # Explicitly set title to nil in data to override helper default
    # This ensures doc.data['title'] is actually nil inside the helper
    doc = create_doc({ 'title' => nil })
    assert_equal "Input Text", LinkHelperUtils._get_link_display_text(" Input Text ", nil, doc)
  end

  def test_get_display_text_nil_input
    doc = create_doc({ 'title' => 'Canonical' })
    assert_equal "", LinkHelperUtils._get_link_display_text(nil, nil, nil)
    # Helper now strips override text
    assert_equal "Override", LinkHelperUtils._get_link_display_text(nil, " Override ", nil)
    assert_equal "Canonical", LinkHelperUtils._get_link_display_text(nil, nil, doc)
    # Helper now strips override text
    assert_equal "Override", LinkHelperUtils._get_link_display_text(nil, " Override ", doc)
  end

  def test_get_display_text_empty_input
    doc = create_doc({ 'title' => 'Canonical' })
    assert_equal "", LinkHelperUtils._get_link_display_text("", nil, nil)
    # Helper now strips override text
    assert_equal "Override", LinkHelperUtils._get_link_display_text("", " Override ", nil)
    assert_equal "Canonical", LinkHelperUtils._get_link_display_text("", nil, doc)
    # Helper now strips override text
    assert_equal "Override", LinkHelperUtils._get_link_display_text("", " Override ", doc)
  end


  # --- Tests for _generate_link_html ---

  def test_generate_link_doc_found_different_page
    site = create_site
    found_doc = create_doc({ 'title' => 'Found Doc' }, '/found.html')
    current_page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: current_page })
    inner_html = "<cite>Found Doc</cite>"

    expected = "<a href=\"/found.html\">#{inner_html}</a>"
    assert_equal expected, LinkHelperUtils._generate_link_html(ctx, found_doc.url, inner_html)
  end

  def test_generate_link_doc_found_same_page
    site = create_site
    found_doc = create_doc({ 'title' => 'Found Doc' }, '/current.html')
    current_page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: current_page })
    inner_html = "<cite>Found Doc</cite>"

    expected = inner_html # No link
    assert_equal expected, LinkHelperUtils._generate_link_html(ctx, found_doc.url, inner_html)
  end

  def test_generate_link_doc_not_found
    site = create_site
    current_page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: current_page })
    inner_html = "<cite>Not Found</cite>"

    expected = inner_html # No link
    assert_equal expected, LinkHelperUtils._generate_link_html(ctx, nil, inner_html) # Pass nil URL
  end

  def test_generate_link_doc_found_no_url
    site = create_site
    # Test helper now handles nil URL correctly
    found_doc = create_doc({ 'title' => 'Found Doc' }, nil) # URL is nil
    current_page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: current_page })
    inner_html = "<cite>Found Doc</cite>"

    expected = inner_html # No link
    assert_equal expected, LinkHelperUtils._generate_link_html(ctx, found_doc.url, inner_html) # Pass nil URL
  end

  def test_generate_link_doc_found_empty_url
    site = create_site
    found_doc = create_doc({ 'title' => 'Found Doc' }, '') # Empty string URL
    current_page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: current_page })
    inner_html = "<cite>Found Doc</cite>"

    # Helper now checks for empty URL string
    expected = inner_html # No link
    assert_equal expected, LinkHelperUtils._generate_link_html(ctx, found_doc.url, inner_html)
  end

  def test_generate_link_with_baseurl
    site = create_site({ 'baseurl' => '/blog' })
    found_doc = create_doc({ 'title' => 'Found Doc' }, '/found.html')
    current_page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: current_page })
    inner_html = "<cite>Found Doc</cite>"

    expected = "<a href=\"/blog/found.html\">#{inner_html}</a>" # Expect baseurl prepended
    assert_equal expected, LinkHelperUtils._generate_link_html(ctx, found_doc.url, inner_html)
  end

  def test_generate_link_with_baseurl_and_relative_url
    site = create_site({ 'baseurl' => '/blog' })
    # Document URL doesn't start with /
    found_doc = create_doc({ 'title' => 'Found Doc' }, 'found.html')
    current_page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: current_page })
    inner_html = "<cite>Found Doc</cite>"

    # Expect baseurl and a slash prepended
    expected = "<a href=\"/blog/found.html\">#{inner_html}</a>"
    assert_equal expected, LinkHelperUtils._generate_link_html(ctx, found_doc.url, inner_html)
  end

  def test_generate_link_no_current_page_in_context
    site = create_site
    found_doc = create_doc({ 'title' => 'Found Doc' }, '/found.html')
    # Context *without* a :page register
    ctx = create_context({}, { site: site })
    inner_html = "<cite>Found Doc</cite>"

    # Should not link if current page URL can't be determined
    expected = inner_html
    assert_equal expected, LinkHelperUtils._generate_link_html(ctx, found_doc.url, inner_html)
  end

end
