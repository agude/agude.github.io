# frozen_string_literal: true

# Test files and Mutant subjects for each Ruby property suite.
module PropertyTestSuites
  SUITES = {
    'html' => {
      'src/infrastructure/test_html_scan' => {
        'TestHtmlScan' => ['Jekyll::Infrastructure::HtmlScan.start_tag'],
      },
      'src/infrastructure/test_html_attributes' => {
        'TestHtmlAttributes' => %w[
          Jekyll::Infrastructure::HtmlAttributes.parse
          Jekyll::Infrastructure::HtmlAttributes.remove
          Jekyll::Infrastructure::HtmlAttributes.append
        ],
      },
      'src/infrastructure/test_image_dimensions_injector' => {
        'TestImageDimensionsInjector' => ['Jekyll::Infrastructure::HtmlAttributes.append'],
      },
      'src/infrastructure/test_code_block_region_injector' => {
        'TestCodeBlockRegionInjector' => ['Jekyll::Infrastructure::HtmlAttributes.append'],
      },
    },
    'link-cache' => {
      'src/infrastructure/link_cache/test_book_candidate_selector' => {
        'TestBookCandidateSelector' => ['Jekyll::Infrastructure::LinkCache::BookCandidateSelector.'],
      },
      'src/infrastructure/link_cache/test_book_candidate_selector_properties' => {
        'TestBookCandidateSelectorProperties' => ['Jekyll::Infrastructure::LinkCache::BookCandidateSelector.'],
      },
      'src/infrastructure/link_cache/test_book_family_validator' => {
        'TestBookFamilyValidator' => ['Jekyll::Infrastructure::LinkCache::BookFamilyValidator#'],
      },
      'src/infrastructure/link_cache/test_book_family_validator_properties' => {
        'TestBookFamilyValidatorProperties' => ['Jekyll::Infrastructure::LinkCache::BookFamilyValidator#'],
      },
      'src/seo/test_book_identity_resolver' => {
        'TestBookIdentityResolver' => ['Jekyll::SEO::BookIdentityResolver.'],
      },
      'src/infrastructure/test_link_cache_generator_properties' => {
        'TestLinkCacheGeneratorProperties' => %w[
          Jekyll::Infrastructure::LinkCache::BookCandidateSelector.
          Jekyll::SEO::BookIdentityResolver.
        ],
      },
    },
    'backlinks' => {
      'src/infrastructure/link_cache/test_backlink_builder' => {
        'TestBacklinkBuilder' => %w[
          Jekyll::Infrastructure::LinkCache::BacklinkBuilder#add_link
          Jekyll::Infrastructure::LinkCache::BacklinkBuilder#merge_entry
        ],
      },
      'src/infrastructure/link_cache/test_backlink_builder_captures' => {
        'TestBacklinkBuilderCaptures' => %w[
          Jekyll::Infrastructure::LinkCache::BacklinkBuilder::ScanState#handle_capture
          Jekyll::Infrastructure::LinkCache::BacklinkBuilder::ScanResult#compute_usages
        ],
      },
      'src/infrastructure/link_cache/test_backlink_builder_forward_links' => {
        'TestForwardLinkBuilder' => %w[
          Jekyll::Infrastructure::LinkCache::BacklinkBuilder#add_link
          Jekyll::Infrastructure::LinkCache::BacklinkBuilder#merge_entry
        ],
      },
      'src/infrastructure/link_cache/test_backlink_builder_properties' => {
        'TestBacklinkBuilderProperties' => %w[
          Jekyll::Infrastructure::LinkCache::BacklinkBuilder::ScanState#handle_capture
          Jekyll::Infrastructure::LinkCache::BacklinkBuilder::ScanResult#compute_usages
          Jekyll::Infrastructure::LinkCache::BacklinkBuilder#add_link
          Jekyll::Infrastructure::LinkCache::BacklinkBuilder#merge_entry
        ],
      },
    },
    'markdown' => {
      'src/infrastructure/test_markdown_whitespace_normalizer' => {
        'TestMarkdownWhitespaceNormalizer' => %w[
          Jekyll::Infrastructure::MarkdownWhitespaceNormalizer.normalize
          Jekyll::Infrastructure::MarkdownWhitespaceNormalizer.normalize_prose_line
        ],
      },
      'src/infrastructure/test_markdown_whitespace_normalizer_properties' => {
        'TestMarkdownWhitespaceNormalizerProperties' => %w[
          Jekyll::Infrastructure::MarkdownWhitespaceNormalizer.normalize
          Jekyll::Infrastructure::MarkdownWhitespaceNormalizer.normalize_prose_line
        ],
      },
      'bin/test_reference_link_scanner' => {
        'TestReferenceLinkScanner' => %w[ReferenceLinkScanner.scan ReferenceLinkScanner.neutralize_liquid],
      },
      'bin/test_reference_link_scanner_properties' => {
        'TestReferenceLinkScannerProperties' => %w[ReferenceLinkScanner.scan ReferenceLinkScanner.neutralize_liquid],
      },
    },
  }.freeze

  # Mutant subject count each suite must match. Mutant silently generates no
  # mutants for a subject expression that matches nothing (for example a
  # method defined in a Struct.new block, or one behind module_function), so
  # the runner compares Mutant's matched count against this before mutating.
  # Update the count with the subject list when a subject is added or removed.
  DECLARED_SUBJECT_COUNTS = {
    'html' => 4,
    'link-cache' => 10,
    'backlinks' => 4,
    'markdown' => 4,
  }.freeze

  def self.fetch(target)
    SUITES.fetch(target) do
      abort "Unknown Ruby test target #{target.inspect}. Choose #{SUITES.keys.join(', ')}."
    end
  end

  def self.load_tests(suite)
    suite.each_key { |path| require_relative "../#{path}" }
  end

  # Test modes for `make test-mutations TESTS=...`. 'all' loads every test file
  # and runs every inline property test. 'examples' loads only the example
  # files and skips inline property tests, so a mutant can be killed only by
  # an example test. Both modes use the same subjects.
  TEST_MODES = %w[all examples].freeze

  # Returns `value` when it names a test mode, and raises otherwise.
  def self.test_mode(value)
    return value if TEST_MODES.include?(value)

    raise ArgumentError, "Unknown TESTS value #{value.inspect}. Choose #{TEST_MODES.join(', ')}."
  end

  # True when the mutation run in `env` should skip inline property tests.
  # check_property reads this flag, so it changes nothing outside a mutation run.
  def self.examples_only?(env = ENV)
    test_mode(env.fetch('MUTATION_TEST_TESTS', 'all')) == 'examples'
  end

  # Files of a suite that a mutation run in `mode` loads and covers. Subjects
  # come from the whole suite, so the subject list does not depend on the mode.
  def self.mutation_files(suite, mode)
    return suite if test_mode(mode) == 'all'

    suite.reject { |path, _tests| property_file?(path) }
  end

  # The *_properties files hold generated tests only.
  def self.property_file?(path)
    path.end_with?('_properties')
  end

  # Unique Mutant subject expressions for a suite, in declaration order.
  def self.subjects(suite)
    suite.values.flat_map(&:values).flatten.uniq
  end

  # Reads the count from `mutant environment subject list` output, whose first
  # line is "Subjects in environment: N". Returns nil when the line is absent.
  def self.parse_subject_count(output)
    match = output.match(/^Subjects in environment: (\d+)$/)
    match && match[1].to_i
  end

  # Returns the error message when Mutant's matched count differs from the
  # declared count for `target`, or nil when they agree.
  def self.subject_count_error(target, actual)
    expected = DECLARED_SUBJECT_COUNTS.fetch(target)
    return nil if actual == expected

    "Mutation subject count mismatch for suite #{target.inspect}: " \
      "expected #{expected} subjects, Mutant matched #{actual}. " \
      'Fix the subject expressions or update DECLARED_SUBJECT_COUNTS in ' \
      '_tests/support/property_test_suites.rb.'
  end
end

PropertyTestSuites.load_tests(PropertyTestSuites.fetch(ARGV.shift)) if $PROGRAM_NAME == __FILE__
