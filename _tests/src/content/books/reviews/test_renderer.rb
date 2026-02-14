# frozen_string_literal: true

# _tests/plugins/logic/previous_reviews/test_renderer.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/reviews/renderer'

# Tests for Jekyll::Books::Reviews::Renderer.
#
# Verifies that the Renderer correctly generates HTML structure and subtitles.
class TestPreviousReviewsRenderer < Minitest::Test
  def setup
    @context = create_context({}, {})
    @archive_new = create_doc(
      {
        'title' => 'Archived (New)',
        'date' => Time.parse('2023-01-01'),
      },
      '/books/archive-new.html',
    )

    @archive_old = create_doc(
      {
        'title' => 'Archived (Old)',
        'date' => Time.parse('2022-01-01'),
      },
      '/books/archive-old.html',
    )
  end

  def test_returns_empty_string_when_reviews_empty
    renderer = Jekyll::Books::Reviews::Renderer.new(@context, [])
    output = renderer.render

    assert_equal '', output
  end

  def test_generates_correct_html_structure
    captured_args = []
    Jekyll::Books::Core::BookCardUtils.stub :render,
                                            lambda { |doc, _ctx, subtitle:|
                                              captured_args << { doc: doc, subtitle: subtitle }
                                              "<!-- Card for #{doc.data['title']} -->"
                                            } do
      renderer = Jekyll::Books::Reviews::Renderer.new(@context, [@archive_new, @archive_old])
      output = renderer.render

      assert_match(/<aside class="previous-reviews">/, output)
      assert_match %r{<h2 class="previous-reviews-headline">Previous Reviews</h2>}, output
      assert_match(/<div class="card-grid">/, output)
      assert_match(%r{</aside>}, output)
    end
  end

  def test_calls_book_card_utils_with_correct_subtitle_format
    captured_args = []
    Jekyll::Books::Core::BookCardUtils.stub :render,
                                            lambda { |doc, _ctx, subtitle:|
                                              captured_args << { doc: doc, subtitle: subtitle }
                                              ''
                                            } do
      renderer = Jekyll::Books::Reviews::Renderer.new(@context, [@archive_new, @archive_old])
      renderer.render

      assert_equal 2, captured_args.length
      assert_equal @archive_new, captured_args[0][:doc]
      assert_equal 'Review from January 01, 2023', captured_args[0][:subtitle]
      assert_equal @archive_old, captured_args[1][:doc]
      assert_equal 'Review from January 01, 2022', captured_args[1][:subtitle]
    end
  end

  def test_renders_cards_in_given_order
    captured_args = []
    Jekyll::Books::Core::BookCardUtils.stub :render,
                                            lambda { |doc, _ctx, subtitle:|
                                              captured_args << { doc: doc, subtitle: subtitle }
                                              "<!-- Card for #{doc.data['title']} -->"
                                            } do
      # Pass reviews in a specific order
      renderer = Jekyll::Books::Reviews::Renderer.new(@context, [@archive_old, @archive_new])
      output = renderer.render

      # Verify the cards appear in the order given
      assert_equal 2, captured_args.length
      assert_equal @archive_old, captured_args[0][:doc]
      assert_equal @archive_new, captured_args[1][:doc]

      # Verify output contains cards in correct order
      old_index = output.index('Archived (Old)')
      new_index = output.index('Archived (New)')
      assert old_index < new_index, 'Old card should appear before new card in output'
    end
  end

  def test_includes_all_rendered_cards_in_output
    Jekyll::Books::Core::BookCardUtils.stub :render,
                                            lambda { |doc, _ctx, subtitle:|
                                              "<div class=\"card\">#{doc.data['title']}</div>"
                                            } do
      renderer = Jekyll::Books::Reviews::Renderer.new(@context, [@archive_new, @archive_old])
      output = renderer.render

      assert_includes output, '<div class="card">Archived (New)</div>'
      assert_includes output, '<div class="card">Archived (Old)</div>'
    end
  end
end
