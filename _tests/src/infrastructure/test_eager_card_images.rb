# frozen_string_literal: true

require 'test_helper'
require 'src/infrastructure/eager_card_images'

# Tests for EagerCardImages: the first card images on a card-list page
# load eagerly; every other image is unchanged.
class TestEagerCardImages < Minitest::Test
  Loader = Jekyll::Infrastructure::EagerCardImages

  def card(name, href: "/books/#{name}/")
    image = %(<img src="/books/covers/#{name}.jpg" alt="Cover" loading="lazy" decoding="async" sizes="auto, 200px" />)
    %(<li class="book-card"> <div class="card-element card-book-cover"> <a href="#{href}"> #{image} </a> </div></li>)
  end

  def apply(html)
    Loader.apply(html, source: 'books/authors/a.md')
  end

  def loading(html)
    Nokogiri::HTML5.fragment(html).css('img').map { |img| img['loading'] }
  end

  def test_first_two_cards_on_a_card_list_page_load_eagerly
    html = "<h1>Author</h1><ul>#{card('a')}#{card('b')}#{card('c')}</ul>"

    assert_equal [nil, nil, 'lazy'], loading(apply(html))
  end

  # `auto` in `sizes` is valid only on a lazy image.
  def test_eager_card_drops_auto_sizes_and_keeps_its_other_attributes
    assert_includes apply(card('a')), '<img src="/books/covers/a.jpg" alt="Cover" decoding="async" sizes="200px" />'
  end

  def test_lazy_card_keeps_auto_sizes
    assert_includes apply(card('a') + card('b') + card('c')), 'loading="lazy" decoding="async" sizes="auto, 200px"'
  end

  def test_card_with_a_long_link_is_still_found
    assert_equal [nil], loading(apply(card('a', href: "/books/#{'x' * 2000}/")))
  end

  def test_page_opening_with_a_lead_image_keeps_cards_lazy
    html = %(<img id="lead-image" src="/files/lead.png" alt="Lead"><ul>#{card('a')}#{card('b')}</ul>)

    assert_equal html, apply(html)
  end

  def test_images_in_comments_and_scripts_do_not_count_as_first
    html = %(<!-- <img src="/x.png"> --><script>"<img src='/y.png'>"</script>#{card('a')})

    assert_equal [nil], loading(apply(html)).last(1)
  end

  def test_card_markup_quoted_in_an_attribute_is_not_a_card
    html = %(<div data-example='#{card('x').gsub("'", '"')}'></div><img id="lead-image" src="/l.png">#{card('a')})

    # The lead image comes first, so the real card stays lazy.
    assert_equal [nil, 'lazy'], loading(apply(html))
  end

  # A commented-out card is neither a card nor counted as one.
  def test_commented_out_card_is_not_counted
    html = "<!-- #{card('x')} -->#{card('a')}"

    assert_equal [nil], loading(apply(html))
  end

  def test_non_card_images_after_the_first_card_are_untouched
    html = %(#{card('a')}<img src="/files/x.png" alt="X" loading="lazy">#{card('b')}#{card('c')})

    assert_equal [nil, 'lazy', nil, 'lazy'], loading(apply(html))
  end

  def test_card_image_that_is_not_lazy_fails
    html = card('a').sub(' loading="lazy"', '')

    error = assert_raises(Jekyll::Errors::FatalException) { apply(html) }
    assert_includes error.message, 'books/authors/a.md'
  end

  def test_card_image_in_unrecognized_markup_fails
    html = card('a').sub('<a href="/books/a/"> ', '<a href="/books/a/"> <span class="badge">New</span> ')

    error = assert_raises(Jekyll::Errors::FatalException) { apply(html) }
    assert_includes error.message, 'recognized 0 of 1 card images'
    assert_includes error.message, 'books/authors/a.md'
  end

  # One card variant changing its markup must fail even when others parse.
  def test_one_unrecognized_card_among_recognized_ones_fails
    changed = card('c').sub('<a href="/books/c/"> ', '<a href="/books/c/"> <span>New</span> ')

    error = assert_raises(Jekyll::Errors::FatalException) { apply(card('a') + card('b') + changed) }
    assert_includes error.message, 'recognized 2 of 3 card images'
  end

  # A book-link preview in a card's excerpt carries a cover <img>; it is
  # not a card image.
  def test_preview_image_in_card_text_is_not_a_card_image
    text = '<div class="card-element card-text"><p><a href="/books/x/">X<span class="book-link-preview" hidden>' \
           '<img class="book-link-preview-cover" src="/x.jpg" alt="X" loading="lazy"></span></a></p></div>'
    html = card('a').sub('</li>', "#{text}</li>")

    assert_equal [nil, 'lazy'], loading(apply(html))
  end

  def test_card_without_an_image_passes
    html = '<li class="article-card"><div class="card-element card-text"><a href="/x/">X</a></div></li>'

    assert_equal html, apply(html)
  end

  def test_applies_only_to_html_with_cards
    item = ->(ext, output) { Struct.new(:output_ext, :output).new(ext, output) }
    assert Loader.applies_to?(item.call('.html', card('a')))
    refute Loader.applies_to?(item.call('.html', '<img src="/x.png">'))
    refute Loader.applies_to?(item.call('.md', card('a')))
  end
end
