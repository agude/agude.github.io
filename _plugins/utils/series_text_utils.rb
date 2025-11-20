# frozen_string_literal: true

# _plugins/utils/series_text_utils.rb

module SeriesTextUtils
  # Define common words that imply a series type.
  # These are checked as whole words against the normalized series name.
  SERIES_TYPE_WORDS = %w[
    adventures
    anthologies
    anthology
    arc
    book
    books
    cantos
    chronicle
    chronicles
    collection
    collections
    cycle
    cycles
    diaries
    mythos
    saga
    sagas
    sequence
    sequences
    series
    song
    songs
    trilogies
    trilogy
    universe
    universes
  ].freeze

  # Analyzes a series name to determine grammatical prefix and suffix.
  #
  # @param raw_series_name [String, nil] The raw series name.
  # @return [Hash, nil] A hash with :prefix, :name, :suffix, or nil if input is invalid.
  #   Example: { prefix: "the ", name: "Foundation", suffix: " series" }
  #            { prefix: "", name: "The Expanse", suffix: " series" }
  #            { prefix: "the ", name: "Dune Saga", suffix: "" }
  def self.analyze_series_name(raw_series_name)
    stripped_name = _validate_and_strip_name(raw_series_name)
    return nil if stripped_name.nil?

    normalized_name = stripped_name.downcase
    prefix = _determine_prefix(normalized_name)
    suffix = _determine_suffix(normalized_name)

    {
      prefix: prefix,
      name: stripped_name,
      suffix: suffix
    }
  end

  # Validates and strips the series name.
  #
  # @param raw_series_name [String, nil] The raw series name.
  # @return [String, nil] The stripped name, or nil if invalid.
  def self._validate_and_strip_name(raw_series_name)
    return nil if raw_series_name.nil?

    stripped_name = raw_series_name.to_s.strip
    stripped_name.empty? ? nil : stripped_name
  end

  # Determines the appropriate prefix for the series name.
  #
  # @param normalized_name [String] The lowercased series name.
  # @return [String] The prefix ("the " or "").
  def self._determine_prefix(normalized_name)
    if normalized_name.start_with?('the ', 'a ', 'an ')
      ''
    else
      'the '
    end
  end

  # Determines the appropriate suffix for the series name.
  #
  # @param normalized_name [String] The lowercased series name.
  # @return [String] The suffix (" series" or "").
  def self._determine_suffix(normalized_name)
    if _contains_series_type_word?(normalized_name)
      ''
    else
      ' series'
    end
  end

  # Checks if the series name contains a series type word.
  #
  # @param normalized_name [String] The lowercased series name.
  # @return [Boolean] True if the name contains a series type word.
  def self._contains_series_type_word?(normalized_name)
    series_title_words = normalized_name.split(/\s+/)
    SERIES_TYPE_WORDS.any? do |type_word|
      series_title_words.any? { |title_word| _strip_punctuation(title_word) == type_word }
    end
  end

  # Strips trailing punctuation from a word.
  #
  # @param word [String] The word to strip.
  # @return [String] The word without trailing punctuation.
  def self._strip_punctuation(word)
    word.gsub(/[[:punct:]]$/, '')
  end
end
