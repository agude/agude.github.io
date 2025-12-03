# frozen_string_literal: true

# _tests/plugins/utils/test_card_renderer_utils.rb
require_relative '../../../test_helper'
# CardRendererUtils will be loaded by test_helper once we add its require there.

# Tests for CardRendererUtils module.
#
# Verifies that the utility correctly renders HTML card components from card data.
class TestCardRendererUtils < Minitest::Test
  def setup
    # Minimal context, primarily for completeness if render_card ever needs it.
    # Currently, render_card doesn't use site/page from context if card_data is complete.
    @site = create_site
    @context = create_context({}, { site: @site, page: create_doc({}, '/current.html') })
  end

  def test_render_minimal_card_data
    card_data = {
      base_class: 'minimal-card',
      url: '/item/1',
      title_html: '<strong>Minimal Title</strong>'
      # image_url, image_alt, image_div_class, description_html, etc., are all nil/missing
    }
    output = CardRendererUtils.render_card(context: @context, card_data: card_data)

    assert_match(/<div class="minimal-card">/, output)
    assert_match(/<div class="card-element card-text">/, output)
    assert_match %r{<a href="/item/1">\s*<strong>Minimal Title</strong>\s*</a>}, output
    refute_match(/<img src=/, output, 'Image should not be present for minimal card')
    refute_match(/<br>/, output, 'Description break should not be present') # Assuming default wrappers are empty
    # Check that no extra elements are rendered
    # This is harder to assert directly without knowing what they might be,
    # but the structure should be simple.
  end

  def test_render_card_with_image
    card_data = {
      base_class: 'image-card',
      url: '/item/image-item',
      title_html: '<strong>Image Card Title</strong>',
      image_url: '/images/pic.jpg',
      image_alt: 'A picture',
      image_div_class: 'custom-image-class'
    }
    output = CardRendererUtils.render_card(context: @context, card_data: card_data)

    assert_match(/<div class="image-card">/, output)
    assert_match(/<div class="card-element custom-image-class">/, output)
    assert_match %r{<a href="/item/image-item">\s*<img src="/images/pic.jpg" alt="A picture" />\s*</a>}, output
    assert_match %r{<a href="/item/image-item">\s*<strong>Image Card Title</strong>\s*</a>}, output
  end

  def test_render_card_with_image_alt_escaping
    card_data = {
      base_class: 'image-card',
      url: '/item/image-item',
      title_html: '<strong>Title</strong>',
      image_url: '/images/pic.jpg',
      image_alt: 'Alt with "quotes" & <tags>',
      image_div_class: 'custom-image-class'
    }
    output = CardRendererUtils.render_card(context: @context, card_data: card_data)
    expected_alt = 'Alt with &quot;quotes&quot; &amp; &lt;tags&gt;'
    assert_match %r{<img src="/images/pic.jpg" alt="#{expected_alt}" />}, output
  end

  def test_render_card_with_description_and_simple_wrapper
    card_data = {
      base_class: 'desc-card',
      url: '/item/desc-item',
      title_html: '<strong>Desc Card Title</strong>',
      description_html: 'This is the description.',
      description_wrapper_html_open: "<br />\n    ", # NOTE: render_card appends description_html after this
      description_wrapper_html_close: ''
    }
    output = CardRendererUtils.render_card(context: @context, card_data: card_data)
    # The regex needs to account for how render_card assembles this.
    # It will be open_wrapper + description_html + close_wrapper
    # So, "<br />\n    This is the description."
    assert_match %r{<br />\s*This is the description.}, output
  end

  def test_render_card_with_description_and_div_wrapper
    card_data = {
      base_class: 'desc-card-div',
      url: '/item/desc-div-item',
      title_html: '<strong>Desc Div Title</strong>',
      description_html: 'Description in a div.',
      description_wrapper_html_open: "<div class=\"desc-wrapper\">\n      ",
      description_wrapper_html_close: "\n    </div>"
    }
    output = CardRendererUtils.render_card(context: @context, card_data: card_data)
    # Expecting: <div class="desc-wrapper">\n      Description in a div.\n    </div>
    assert_match %r{<div class="desc-wrapper">\s*Description in a div.\s*</div>}, output
  end

  def test_render_card_with_extra_elements
    card_data = {
      base_class: 'extra-card',
      url: '/item/extra-item',
      title_html: '<strong>Extra Elements Title</strong>',
      extra_elements_html: [
        "<span class=\"author-line\">By Test Author</span>\n", # Ensure newlines are handled if part of the string
        '<div class="rating-line">Rating: 5 stars</div>'
      ]
    }
    output = CardRendererUtils.render_card(context: @context, card_data: card_data)
    assert_match %r{<span class="author-line">By Test Author</span>}, output
    assert_match %r{<div class="rating-line">Rating: 5 stars</div>}, output
    # Check order if important (Author should be before Rating based on array order)
    author_idx = output.index('By Test Author')
    rating_idx = output.index('Rating: 5 stars')
    refute_nil author_idx
    refute_nil rating_idx
    assert author_idx < rating_idx, 'Author element should appear before rating element'
  end

  def test_render_card_all_elements_present
    card_data = {
      base_class: 'full-card',
      url: '/item/full-item',
      image_url: '/img/full.png',
      image_alt: 'Full image',
      image_div_class: 'full-image-div',
      title_html: '<strong>Full Card Title</strong>',
      extra_elements_html: ['<p>Extra info</p>'],
      description_html: 'Full description here.',
      description_wrapper_html_open: '<div class="desc-container">',
      description_wrapper_html_close: '</div>'
    }
    output = CardRendererUtils.render_card(context: @context, card_data: card_data)

    assert_match(/<div class="full-card">/, output)
    assert_match %r{<img src="/img/full.png" alt="Full image"}, output
    assert_match %r{<strong>Full Card Title</strong>}, output
    assert_match %r{<p>Extra info</p>}, output
    assert_match %r{<div class="desc-container">Full description here.</div>}, output
  end

  def test_render_card_missing_required_data_returns_empty_or_logs
    # Test how render_card handles fundamentally broken input.
    # Current implementation prints to STDOUT and returns empty string.
    # This test will capture STDOUT to verify the error message.

    invalid_inputs = [
      'not a hash',
      { url: '/foo', title_html: 'T' }, # Missing :base_class
      { base_class: 'foo', title_html: 'T' }, # Missing :url
      { base_class: 'foo', url: '/foo' } # Missing :title_html
    ]

    invalid_inputs.each do |input|
      stdout_str, = capture_io do
        output = CardRendererUtils.render_card(context: @context, card_data: input)
        assert_equal '', output.strip
      end
      assert_match '[CardRendererUtils ERROR] Invalid or incomplete card_data provided.', stdout_str
    end
  end

  def test_render_card_empty_description_is_skipped
    card_data = {
      base_class: 'test-card',
      url: '/item/1',
      title_html: '<strong>Title</strong>',
      description_html: '   ', # Whitespace only
      description_wrapper_html_open: '<div>',
      description_wrapper_html_close: '</div>'
    }
    output = CardRendererUtils.render_card(context: @context, card_data: card_data)
    refute_match %r{<div>\s*</div>}, output # The wrapper div should not appear if desc is empty
  end

  def test_render_card_nil_image_alt_is_empty_string
    card_data = {
      base_class: 'image-card',
      url: '/item/image-item',
      title_html: '<strong>Title</strong>',
      image_url: '/images/pic.jpg',
      image_alt: nil, # Test nil alt
      image_div_class: 'custom-image-class'
    }
    output = CardRendererUtils.render_card(context: @context, card_data: card_data)
    assert_match %r{<img src="/images/pic.jpg" alt="" />}, output # Expect empty alt attribute
  end
end
