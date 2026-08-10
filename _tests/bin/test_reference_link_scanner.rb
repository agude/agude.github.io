# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../_bin/reference_link_scanner'

# Covers ReferenceLinkScanner (_bin/reference_link_scanner.rb), the pure
# scanning logic behind `make check-refs`. The regression cases at the bottom
# are the false positives that made the first version of the checker unusable.
class TestReferenceLinkScanner < Minitest::Test
  def scan(content, line_offset: 0)
    ReferenceLinkScanner.scan(content, line_offset: line_offset)
  end

  def messages(entries)
    entries.map { |entry| "#{entry[:line]}: #{entry[:message]}" }
  end

  # --- Undefined references ---

  def test_undefined_full_reference_is_an_error
    result = scan("See [the docs][docs].\n")

    assert_equal ['1: undefined reference link [docs]'], messages(result[:errors])
  end

  def test_defined_full_reference_is_clean
    result = scan("See [the docs][docs].\n\n[docs]: https://example.com\n")

    assert_empty result[:errors]
    assert_empty result[:warnings]
  end

  def test_reference_id_matching_is_case_insensitive
    result = scan("See [the docs][Docs].\n\n[docs]: https://example.com\n")

    assert_empty result[:errors]
    assert_empty result[:warnings]
  end

  def test_full_reference_may_wrap_across_lines
    result = scan("See [the very long\ndocs title][docs].\n\n[docs]: https://example.com\n")

    assert_empty result[:errors]
  end

  def test_implicit_link_name_uses_the_link_text_as_the_id
    result = scan("See [docs][].\n\n[docs]: https://example.com\n")

    assert_empty result[:errors]
    assert_empty result[:warnings]
  end

  def test_shorthand_reference_never_reports_undefined
    # Editorial brackets in prose are indistinguishable from shorthand refs.
    result = scan("He said [sic] it was [...] fine.\n")

    assert_empty result[:errors]
  end

  def test_footnote_reference_is_not_a_link_reference
    result = scan("A claim[^note].\n\n[^note]: The footnote body.\n")

    assert_empty result[:errors]
    assert_empty result[:warnings]
  end

  # --- Duplicate definitions ---

  def test_duplicate_definition_is_an_error
    content = "See [a][dup] and [b][dup].\n\n[dup]: https://one.example\n[dup]: https://two.example\n"
    result = scan(content)

    assert_equal ['4: duplicate link definition [dup] (first defined on line 3)'],
                 messages(result[:errors])
  end

  # --- Orphaned definitions ---

  def test_orphaned_definition_is_a_warning
    result = scan("Nothing links here.\n\n[unused]: https://example.com\n")

    assert_empty result[:errors]
    assert_equal ['3: orphaned link definition [unused]'], messages(result[:warnings])
  end

  def test_shorthand_reference_keeps_a_definition_from_being_orphaned
    result = scan("See [docs] for more.\n\n[docs]: https://example.com\n")

    assert_empty result[:warnings]
  end

  # --- Line numbers ---

  def test_line_offset_shifts_reported_lines
    result = scan("See [the docs][docs].\n", line_offset: 10)

    assert_equal ['11: undefined reference link [docs]'], messages(result[:errors])
  end

  def test_multi_line_liquid_does_not_shift_later_line_numbers
    content = <<~MARKDOWN
      {% citation
        author_last="Someone"
        work_title="A Title"
      %}

      [unused]: https://example.com
    MARKDOWN
    result = scan(content)

    assert_equal ['6: orphaned link definition [unused]'], messages(result[:warnings])
  end

  def test_content_line_offset_counts_the_front_matter_lines
    path = File.join(Dir.tmpdir, "ref_scanner_#{Process.pid}.md")
    File.write(path, "---\ntitle: Test\nlayout: post\n---\n\nBody text.\n")

    assert_equal 4, ReferenceLinkScanner.content_line_offset(path, "\nBody text.\n")
  ensure
    FileUtils.rm_f(path)
  end

  def test_content_line_offset_is_zero_without_front_matter
    path = File.join(Dir.tmpdir, "ref_scanner_bare_#{Process.pid}.md")
    File.write(path, "Body text only.\n")

    assert_equal 0, ReferenceLinkScanner.content_line_offset(path, "Body text only.\n")
  ensure
    FileUtils.rm_f(path)
  end

  def test_content_line_offset_falls_back_to_zero_when_content_is_not_found
    path = File.join(Dir.tmpdir, "ref_scanner_missing_#{Process.pid}.md")
    File.write(path, "Body text only.\n")

    assert_equal 0, ReferenceLinkScanner.content_line_offset(path, 'rewritten by a plugin')
  ensure
    FileUtils.rm_f(path)
  end

  # --- Liquid neutralization ---

  def test_liquid_in_a_definition_url_still_defines_the_id
    result = scan("See [the post][p].\n\n[p]: {% post_url 2016-01-01-thing %}\n")

    assert_empty result[:errors]
    assert_empty result[:warnings]
  end

  def test_liquid_output_in_a_definition_url_still_defines_the_id
    result = scan("See [the file][f].\n\n[f]: {{ file_dir }}/data.json\n")

    assert_empty result[:errors]
    assert_empty result[:warnings]
  end

  def test_liquid_array_index_is_not_a_reference
    result = scan("Value is {{ arr[0] }} here.\n")

    assert_empty result[:errors]
    assert_empty result[:warnings]
  end

  def test_commented_out_markup_is_ignored
    result = scan("{% comment %}[text][gone]{% endcomment %}\n")

    assert_empty result[:errors]
  end

  def test_brackets_inside_fenced_code_are_not_references
    result = scan("```python\nrow = data[0]\nlink = \"[text][id]\"\n```\n")

    assert_empty result[:errors]
    assert_empty result[:warnings]
  end

  def test_brackets_inside_inline_code_are_not_references
    result = scan("Use `data[0]` and `[text][id]` in code.\n")

    assert_empty result[:errors]
  end

  # --- Regressions ---

  def test_reference_inside_a_capture_block_is_not_orphaned
    # The captured variable expands to [Soldier][soldier] at render time, so
    # the definition is used. Deleting capture bodies reported a false orphan.
    content = <<~MARKDOWN
      {% capture soldier_movie %}[{% movie_title "Soldier" %}][soldier]{% endcapture %}

      {{ soldier_movie }} is worth watching.

      [soldier]: https://example.com/soldier
    MARKDOWN
    result = scan(content)

    assert_empty result[:errors]
    assert_empty result[:warnings]
  end

  def test_reference_after_liquid_in_a_footnote_definition_is_not_orphaned
    # Truncating a definition line at its first Liquid tag lost the reference
    # that followed, reporting a false orphan.
    content = <<~MARKDOWN
      Hammered home[^lampshade] repeatedly.

      [^lampshade]: {{ the_author }} [lampshades][lampshade] this.

      [lampshade]: https://example.com/lampshade
    MARKDOWN
    result = scan(content)

    assert_empty result[:errors]
    assert_empty result[:warnings]
  end

  def test_definition_url_containing_brackets_is_not_a_reference
    content = "See [the page][wiki].\n\n[wiki]: https://example.com/a[b][c]\n"
    result = scan(content)

    assert_empty result[:errors]
  end
end
