require_relative '../../test_helper'

class TestLiquidUtils < Minitest::Test

  # --- render_article_card ---
  def test_render_article_card_basic
    post = create_doc({ 'title' => "Basic Post" }, '/blog/basic.html')
    site = create_site
    ctx = create_context({}, { site: site, page: create_doc({}, '/current.html') }) # Need page for context

    output = LiquidUtils.render_article_card(post, ctx)

    assert_match(/<div class="article-card">/, output)
    assert_match(/<a href="\/blog\/basic.html">/, output)
    assert_match(/<strong>Basic Post<\/strong>/, output)
    # Check it DOESN'T have image or description sections
    refute_match(/<div class="card-element card-image">/, output)
    refute_match(/<br>/, output) # No description means no <br> before it
  end

  def test_render_article_card_with_image_and_alt
    post = create_doc({ 'title' => "Post with Image", 'image' => '/img.png', 'image_alt' => 'My Alt Text' }, '/blog/img.html')
    site = create_site
    ctx = create_context({}, { site: site, page: create_doc({}, '/current.html') })

    output = LiquidUtils.render_article_card(post, ctx)

    assert_match(/<div class="card-element card-image">/, output)
    assert_match(/<img src="\/img.png" alt="My Alt Text" \/>/, output)
    assert_match(/<strong>Post with Image<\/strong>/, output)
  end

  def test_render_article_card_with_description
    post = create_doc({ 'title' => "Post with Desc", 'description' => 'Desc text.' }, '/blog/desc.html')
    site = create_site
    ctx = create_context({}, { site: site, page: create_doc({}, '/current.html') })

    output = LiquidUtils.render_article_card(post, ctx)

    assert_match(/<strong>Post with Desc<\/strong>/, output)
    assert_match(/<br>\s*Desc text./, output) # Check for <br> and description
  end

  def test_render_article_card_with_excerpt_fallback
    # Mock excerpt object (Jekyll 4 uses data['excerpt'])
    excerpt_obj = Struct.new(:string) { def to_s; string; end }.new("Excerpt text.")
    post = create_doc({ 'title' => "Post with Excerpt", 'excerpt' => excerpt_obj }, '/blog/ex.html')
    # Note: No 'description' field in data
    site = create_site
    ctx = create_context({}, { site: site, page: create_doc({}, '/current.html') })

    output = LiquidUtils.render_article_card(post, ctx)

    assert_match(/<strong>Post with Excerpt<\/strong>/, output)
    assert_match(/<br>\s*Excerpt text./, output)
  end

  def test_render_article_card_title_typography_and_br
    post = create_doc({ 'title' => "It's a <br> \"Test\" -- Title" }, '/blog/smart.html')
    site = create_site
    ctx = create_context({}, { site: site, page: create_doc({}, '/current.html') })

    output = LiquidUtils.render_article_card(post, ctx)

    # Check that _prepare_display_title was effectively used
    assert_match(/<strong>It’s a <br> “Test” – Title<\/strong>/, output)
  end
end
