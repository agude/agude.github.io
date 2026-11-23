# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/fixture_site'

# Build failures must reach the Jekyll process exit status with their diagnostics.
class TestBuildFailures < Minitest::Test
  AUTHOR_PAGE = <<~MARKDOWN
    ---
    layout: author_page
    title: Fixture Author
    wikidata_qid: Q2
    ---
  MARKDOWN

  def test_inline_svg_stops_post_build
    assert_build_fails(
      '_posts/2024-01-01-sample.md',
      "---\nlayout: post\ntitle: Sample Post\n---\n<svg></svg>\n",
      'InlineSvgValidator: <svg> with no class needs aria-hidden="true"',
    )
  end

  def test_inline_svg_stops_page_build
    assert_build_fails(
      'sample.md',
      "---\nlayout: page\ntitle: Sample Page\n---\n<svg></svg>\n",
      'InlineSvgValidator: <svg> with no class needs aria-hidden="true"',
    )
  end

  def test_boolean_isbn_stops_book_build
    assert_invalid_isbn('false', 'FalseClass')
  end

  def test_array_isbn_stops_book_build
    assert_invalid_isbn('[1]', 'Array')
  end

  def test_single_character_llms_index_argument_stops_build
    assert_build_fails(
      '_posts/2024-01-01-sample.md',
      "---\nlayout: post\ntitle: Sample Post\n---\n{% llms_txt_index x %}\n",
      "Syntax Error in 'llms_txt_index': This tag does not accept any arguments.",
    )
  end

  def test_favorites_lookup_without_date_stops_build
    assert_build_fails(
      '_posts/2024-01-01-favorites.md',
      <<~MARKDOWN,
        ---
        layout: post
        title: Favorites 2023
        is_favorites_list: 2023
        ---
        {% book_card_lookup title="Fixture Book" %}
      MARKDOWN
      'FavoritesValidator: Missing date parameter on book_card_lookup tags',
      '_books/fixture.md' => <<~MARKDOWN,
        ---
        title: Fixture Book
        book_authors: Fixture Author
        book_number: 1
        wikidata_qid: Q1
        ---
        A book review.
      MARKDOWN
      'books/authors/fixture_author.md' => AUTHOR_PAGE,
    )
  end

  private

  def assert_invalid_isbn(value, yaml_type)
    assert_build_fails(
      '_books/fixture.md',
      <<~MARKDOWN,
        ---
        title: Fixture Book
        book_authors: Fixture Author
        book_number: 1
        wikidata_qid: Q1
        isbn: #{value}
        ---
        A book review.
      MARKDOWN
      "has isbn #{value}, which YAML parsed as type #{yaml_type}",
      'books/authors/fixture_author.md' => AUTHOR_PAGE,
    )
  end

  def assert_build_fails(path, content, diagnostic, other_files = {})
    build = FixtureSite.build(files: other_files.merge(path => content))

    assert build.status.exited? && !build.status.success?,
           "Expected Jekyll to reject #{path} (#{build.status}).\n#{build.output}"
    assert_includes build.output, diagnostic
  end
end
