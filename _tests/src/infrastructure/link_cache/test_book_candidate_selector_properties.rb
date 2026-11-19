# frozen_string_literal: true

require_relative '../../../test_helper'

# Exhaustive comparisons against a direct scan of book author metadata.
class TestBookCandidateSelectorProperties < Minitest::Test
  Selector = Jekyll::Infrastructure::LinkCache::BookCandidateSelector

  AUTHOR_ALIASES = {
    'Author 0' => 'Author 0',
    'Pen Name 0' => 'Author 0',
    'Author 1' => 'Author 1',
    'Pen Name 1' => 'Author 1',
    'Author 2' => 'Author 2',
    'Pen Name 2' => 'Author 2',
  }.freeze

  AUTHOR_CACHE = AUTHOR_ALIASES.each_with_object({}) do |(alias_name, canonical_name), cache|
    cache[alias_name.downcase] = { 'title' => canonical_name }
  end.freeze

  # Every additional_author_ids array of length 0..2 over ids 0..2 (13 inputs).
  ADDITIONAL_AUTHOR_IDS = (0..2).flat_map { |length| [0, 1, 2].repeated_permutation(length).to_a }.freeze

  def test_selection_matches_a_linear_author_scan
    assert_equal 13, ADDITIONAL_AUTHOR_IDS.length

    ADDITIONAL_AUTHOR_IDS.each do |additional_author_ids|
      candidates = [
        { 'url' => '/books/no-authors/' },
        { 'url' => '/books/blank-author/', 'authors' => [' '] },
        *candidates_for(additional_author_ids),
      ]
      filters = [nil, " \t ", 'Pen Name 0', '  AUTHOR 0  ', 'Author 1', 'Unknown Author']

      filters.each do |author_filter|
        expected = linear_scan(candidates, author_filter)
        actual = Selector.select_book(candidates, author_filter, AUTHOR_CACHE)
        message = "additional_author_ids=#{additional_author_ids.inspect}, " \
                  "filter=#{author_filter.inspect}, candidates=#{candidates.inspect}"
        assert_equal expected, actual, message
      end

      single_candidate = candidates.last(1)
      message = "additional_author_ids=#{additional_author_ids.inspect}, single candidate"
      assert_equal single_candidate.first, Selector.select_book(single_candidate, nil, AUTHOR_CACHE), message
    end
  end

  private

  def candidates_for(additional_author_ids)
    [0, 1, *additional_author_ids].each_with_index.map do |author_id, index|
      author_name = if index.zero? || index.even?
                      "Pen Name #{author_id}"
                    else
                      "Author #{author_id}"
                    end

      { 'url' => "/books/candidate-#{index}/", 'authors' => [author_name] }
    end
  end

  def linear_scan(candidates, author_filter)
    requested_name = author_filter.to_s.strip
    return candidates.length > 1 ? :ambiguous : candidates.first if requested_name.empty?

    canonical_request = resolve_from_fixture_aliases(requested_name)
    candidates.find do |candidate|
      Array(candidate['authors']).any? do |author_name|
        resolve_from_fixture_aliases(author_name).casecmp(canonical_request).zero?
      end
    end || :author_mismatch
  end

  def resolve_from_fixture_aliases(name)
    trimmed_name = name.to_s.strip
    AUTHOR_ALIASES.find do |alias_name, _canonical_name|
      alias_name.casecmp(trimmed_name).zero?
    end&.last || trimmed_name
  end
end
