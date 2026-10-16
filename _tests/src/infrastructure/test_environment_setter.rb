# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../_plugins/src/infrastructure/environment_setter' # Load the generator

# Tests for Jekyll::Infrastructure::EnvironmentSetterGenerator.
#
# Verifies the value the generator leaves in site.config['environment'],
# which PluginLoggerUtils reads to decide whether to emit HTML comments.
class TestEnvironmentSetterGenerator < Minitest::Test
  def setup
    @original_jekyll_env = ENV.fetch('JEKYLL_ENV', nil)
    @generator = Jekyll::Infrastructure::EnvironmentSetterGenerator.new
  end

  def teardown
    ENV['JEKYLL_ENV'] = @original_jekyll_env
  end

  # Runs the generator with JEKYLL_ENV set to +jekyll_env+ (nil unsets it)
  # and returns [site, logged messages].
  def run_generator(jekyll_env:, configured:)
    ENV['JEKYLL_ENV'] = jekyll_env
    site = create_site({ 'environment' => configured })
    messages = []
    logger = silent_logger
    logger.define_singleton_method(:info) { |_topic, message = nil| messages << message }
    Jekyll.stub(:logger, logger) { @generator.generate(site) }
    [site, messages]
  end

  def test_jekyll_env_sets_environment
    site, = run_generator(jekyll_env: 'production', configured: nil)
    assert_equal 'production', site.config['environment']
  end

  def test_empty_jekyll_env_keeps_configured_value
    site, = run_generator(jekyll_env: '', configured: 'development')
    assert_equal 'development', site.config['environment']
  end

  def test_unset_jekyll_env_keeps_configured_value
    site, = run_generator(jekyll_env: nil, configured: 'development')
    assert_equal 'development', site.config['environment']
  end

  def test_jekyll_env_overrides_configured_value
    site, messages = run_generator(jekyll_env: 'production', configured: 'development')
    assert_equal 'production', site.config['environment']
    names_both = messages.any? { |m| m.include?('development') && m.include?('production') }
    assert names_both, "Expected a log line naming both values, got: #{messages.inspect}"
  end

  # PluginLoggerUtils reads site.config['environment'] when a tag logs a
  # failure, which happens during render, after this generator has run.
  def test_plugin_logger_reads_the_overridden_value
    site, = run_generator(jekyll_env: 'production', configured: 'development')
    site.config['plugin_logging'] = { 'TEST_TAG' => true }
    context = create_context({}, { site: site })
    output = Jekyll.stub(:logger, silent_logger) do
      Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
        context: context, tag_type: 'TEST_TAG', reason: 'probe',
      )
    end
    assert_equal '', output
  end

  def test_generator_priority_is_highest
    assert_equal :highest, Jekyll::Infrastructure::EnvironmentSetterGenerator.priority
  end
end
