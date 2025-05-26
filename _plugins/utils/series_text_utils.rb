# _plugins/utils/series_text_utils.rb

module SeriesTextUtils
  # Define common words that imply a series type.
  # These are checked as whole words against the normalized series name.
  SERIES_TYPE_WORDS = [
    'anthologies',
    'anthology',
    'arc',
    'book',
    'books',
    'cantos',
    'chronicle',
    'chronicles',
    'collection',
    'collections',
    'cycle',
    'cycles',
    'diaries',
    'mythos',
    'saga',
    'sagas',
    'sequence',
    'sequences',
    'series',
    'song',
    'songs',
    'trilogies',
    'trilogy',
    'universe',
    'universes',
  ].freeze

  # Analyzes a series name to determine grammatical prefix and suffix.
  #
  # @param raw_series_name [String, nil] The raw series name.
  # @return [Hash, nil] A hash with :prefix, :name, :suffix, or nil if input is invalid.
  #   Example: { prefix: "the ", name: "Foundation", suffix: " series" }
  #            { prefix: "", name: "The Expanse", suffix: " series" }
  #            { prefix: "the ", name: "Dune Saga", suffix: "" }
  def self.analyze_series_name(raw_series_name)
    return nil if raw_series_name.nil? || raw_series_name.to_s.strip.empty?

    stripped_name = raw_series_name.to_s.strip
    return nil if stripped_name.empty? # Double check after stripping

    normalized_name_for_logic = stripped_name.downcase

    # Determine Prefix
    prefix = if normalized_name_for_logic.start_with?("the ", "a ", "an ")
               ""
             else
               "the "
             end

    # Determine Suffix
    contains_series_type_word = false
    series_title_words = normalized_name_for_logic.split(/\s+/)
    SERIES_TYPE_WORDS.each do |type_word|
      if series_title_words.any? { |title_word| title_word.gsub(/[[:punct:]]$/, '') == type_word }
        contains_series_type_word = true
        break
      end
    end
    suffix = contains_series_type_word ? "" : " series"

    {
      prefix: prefix,
      name: stripped_name, # Return the original stripped name for linking
      suffix: suffix
    }
  end
end
