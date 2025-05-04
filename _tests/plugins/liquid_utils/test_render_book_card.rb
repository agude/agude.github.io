require_relative '../../test_helper'

class TestLiquidUtils < Minitest::Test

  # --- render_book_card ---
  def test_render_book_card_basic
    book = create_doc({ 'title' => "Basic Book" }, '/books/basic.html')
    site = create_site
    ctx = create_context({}, { site: site, page: create_doc({}, '/current.html') })

    output = LiquidUtils.render_book_card(book, ctx)
    # Basic structure checks
    assert_match(/<div class="book-card">/, output)
    assert_match(/<a href="\/books\/basic.html">/, output)
    assert_match(/<strong><cite class="book-title">Basic Book<\/cite><\/strong>/, output)
    # Check things that shouldn't be there
    refute_match(/<div class="card-element card-book-cover">/, output) # No image
    refute_match(/<span class="by-author">/, output) # No author
    refute_match(/class="book-rating star-rating-/, output) # No rating
    refute_match(/<div class="card-element card-text">.*<\/div>/m, output[/<a href=.*<\/a>\s*(.*)/m]) # No description block after title link
  end

  def test_render_book_card_all_fields
    author_page = create_doc({ 'title' => 'Jane Doe', 'layout' => 'author_page' }, '/authors/jane-doe.html')
    excerpt_obj = Struct.new(:string) { def to_s; string; end }.new("Book desc.")
    book = create_doc({
      'title' => "It's \"Great\"!",
      'book_author' => 'Jane Doe',
      'rating' => 4,
      'image' => '/covers/great.jpg',
      'excerpt' => excerpt_obj
    }, '/books/great.html')
    site = create_site({}, {}, [author_page]) # Need author page for link
    ctx = create_context({}, { site: site, page: create_doc({}, '/current.html') })

    output = LiquidUtils.render_book_card(book, ctx)

    # Check title (processed)
    assert_match(/<cite class="book-title">It’s “Great”!<\/cite>/, output)
    # Check image
    assert_match(/<div class="card-element card-book-cover">/, output)
    assert_match(/<img src="\/covers\/great.jpg" alt="Book cover of It&#39;s &quot;Great&quot;!." \/>/, output) # Alt text uses original title, escaped
    # Check author (linked)
    assert_match(/<span class="by-author"> by <a href="\/authors\/jane-doe.html"><span class="author-name">Jane Doe<\/span><\/a><\/span>/, output)
    # Check rating
    assert_match(/class="book-rating star-rating-4"/, output)
    assert_match(/★.*★.*★.*★.*☆/, output) # 4 full, 1 empty star
    # Check description
    assert_match(/<div class="card-element card-text">\s*Book desc.\s*<\/div>/m, output)
  end
end
