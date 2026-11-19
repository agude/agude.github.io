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

  def self.fetch(target)
    SUITES.fetch(target) do
      abort "Unknown Ruby test target #{target.inspect}. Choose #{SUITES.keys.join(', ')}."
    end
  end

  def self.load_tests(suite)
    suite.each_key { |path| require_relative "../#{path}" }
  end
end

PropertyTestSuites.load_tests(PropertyTestSuites.fetch(ARGV.shift)) if $PROGRAM_NAME == __FILE__
