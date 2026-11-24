# frozen_string_literal: true

require_relative '../../../test_helper'

# Shared card markup validation and image defaults.
class TestCardRendererUtils < Minitest::Test
  def test_render_card_missing_required_data_fails_build
    invalid_inputs = [
      'not a hash',
      { url: '/foo', title_html: 'T' }, # Missing :base_class
      { base_class: 'foo', title_html: 'T' }, # Missing :url
      { base_class: 'foo', url: '/foo' }, # Missing :title_html
      { base_class: '', url: '/foo', title_html: 'T' },
      { base_class: 'foo', url: '  ', title_html: 'T' },
      { base_class: 'foo', url: '/foo', title_html: '' },
      { base_class: 'foo', url: '/foo', title_html: " \t " },
    ]

    invalid_inputs.each do |input|
      error = assert_raises(Jekyll::Errors::FatalException) do
        Jekyll::UI::Cards::CardRendererUtils.render_card(card_data: input)
      end
      assert_match 'Card data missing required fields:', error.message
    end
  end

  def test_render_card_failure_identifies_available_card_fields
    error = assert_raises(Jekyll::Errors::FatalException) do
      Jekyll::UI::Cards::CardRendererUtils.render_card(
        card_data: { base_class: 'book-card', url: '/books/example', title_html: ' ' },
      )
    end

    assert_match 'title_html', error.message
    assert_match 'base_class="book-card"', error.message
    assert_match 'url="/books/example"', error.message
  end

  def test_render_card_nil_image_alt_is_empty_string
    card_data = {
      base_class: 'image-card',
      url: '/item/image-item',
      title_html: '<strong>Title</strong>',
      image_url: '/images/pic.jpg',
      image_alt: nil, # Test nil alt
      image_div_class: 'custom-image-class',
    }
    output = Jekyll::UI::Cards::CardRendererUtils.render_card(card_data: card_data)
    assert_match %r{<img src="/images/pic.jpg" alt="" loading="lazy" decoding="async" />}, output # Expect empty alt attribute
  end

  def test_render_card_omits_false_excerpt
    output = Jekyll::UI::Cards::CardRendererUtils.render_card(
      card_data: { base_class: 'card', url: '/x/', title_html: 'X', excerpt: false },
    )
    refute_includes output, 'false'
  end

  def test_render_card_rejects_non_string_excerpt
    assert_raises(NoMethodError) do
      Jekyll::UI::Cards::CardRendererUtils.render_card(
        card_data: { base_class: 'card', url: '/x/', title_html: 'X', excerpt: ['Atlas'] },
      )
    end
  end
end
