# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../_plugins/src/seo/standard_site_well_known_generator'

# Tests for Jekyll::SEO::StandardSiteWellKnownGenerator.
class TestStandardSiteWellKnownGenerator < Minitest::Test
  VALID_URI = 'at://did:plc:y5qiqqtzjmlwggzuttldivxq/site.standard.publication/3mpwdqt4xn42j'

  def setup
    @generator = Jekyll::SEO::StandardSiteWellKnownGenerator.new({})
  end

  def site_with_uri(uri)
    create_site('standard_site' => { 'publication_uri' => uri })
  end

  # --- Missing / empty config ---

  def test_missing_standard_site_key_skips_generation
    site = create_site
    Jekyll.stub :logger, silent_logger do
      @generator.generate(site)
    end
    assert_empty site.static_files
  end

  def test_empty_publication_uri_skips_generation
    site = site_with_uri('')
    Jekyll.stub :logger, silent_logger do
      @generator.generate(site)
    end
    assert_empty site.static_files
  end

  def test_nil_publication_uri_skips_generation
    site = site_with_uri(nil)
    Jekyll.stub :logger, silent_logger do
      @generator.generate(site)
    end
    assert_empty site.static_files
  end

  def test_missing_config_logs_warning
    site = create_site
    warned = false
    warn_logger = Object.new.tap do |l|
      def l.info(_topic, _msg = nil); end

      def l.error(_topic, _msg = nil); end

      def l.debug(_topic, _msg = nil); end

      l.define_singleton_method(:warn) { |_topic, _msg = nil| warned = true }
    end
    Jekyll.stub :logger, warn_logger do
      @generator.generate(site)
    end
    assert warned, 'expected a warning to be logged when publication_uri is absent'
  end

  # --- Malformed URI ---

  def test_malformed_uri_raises_fatal_exception
    site = site_with_uri('https://not-an-at-uri.example.com')
    Jekyll.stub :logger, silent_logger do
      err = assert_raises Jekyll::Errors::FatalException do
        @generator.generate(site)
      end
      assert_match 'malformed', err.message
    end
  end

  def test_uri_with_wrong_collection_raises_fatal_exception
    bad = 'at://did:plc:y5qiqqtzjmlwggzuttldivxq/site.standard.document/3mpwdqt4xn42j'
    site = site_with_uri(bad)
    Jekyll.stub :logger, silent_logger do
      assert_raises Jekyll::Errors::FatalException do
        @generator.generate(site)
      end
    end
  end

  def test_uri_with_trailing_slash_raises_fatal_exception
    site = site_with_uri("#{VALID_URI}/")
    Jekyll.stub :logger, silent_logger do
      assert_raises Jekyll::Errors::FatalException do
        @generator.generate(site)
      end
    end
  end

  # --- Valid URI → static file ---

  def test_valid_uri_adds_one_static_file
    site = site_with_uri(VALID_URI)
    Jekyll.stub :logger, silent_logger do
      @generator.generate(site)
    end
    assert_equal 1, site.static_files.length
  end

  def test_static_file_has_correct_dir
    site = site_with_uri(VALID_URI)
    Jekyll.stub :logger, silent_logger do
      @generator.generate(site)
    end
    assert_equal '.well-known', site.static_files.first.generated_dir
  end

  def test_static_file_has_correct_name
    site = site_with_uri(VALID_URI)
    Jekyll.stub :logger, silent_logger do
      @generator.generate(site)
    end
    assert_equal 'site.standard.publication', site.static_files.first.generated_name
  end

  def test_static_file_content_is_exact_uri_with_no_trailing_newline
    site = site_with_uri(VALID_URI)
    Jekyll.stub :logger, silent_logger do
      @generator.generate(site)
    end
    file = site.static_files.first
    # Inspect the generated content via write to a temp path
    Dir.mktmpdir do |dir|
      file.write(dir)
      dest = File.join(dir, '.well-known', 'site.standard.publication')
      content = File.read(dest)
      assert_equal VALID_URI, content
      refute_match(/\n\z/, content, 'content must not end with a newline')
    end
  end

  def test_static_file_is_generated_static_file_instance
    site = site_with_uri(VALID_URI)
    Jekyll.stub :logger, silent_logger do
      @generator.generate(site)
    end
    assert_instance_of Jekyll::Infrastructure::GeneratedStaticFile, site.static_files.first
  end
end
