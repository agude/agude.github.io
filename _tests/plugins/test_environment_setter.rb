# frozen_string_literal: true

# _tests/plugins/test_environment_setter.rb
require_relative '../test_helper'
require_relative '../../_plugins/environment_setter' # Load the generator

# Tests for EnvironmentSetterGenerator.
#
# Verifies that the generator correctly sets site.config['environment'] from ENV.
class TestEnvironmentSetterGenerator < Minitest::Test
  def setup
    @original_jekyll_env = ENV.fetch('JEKYLL_ENV', nil) # Store original ENV value
    # Create a site with a default 'environment' to test against
    @site = create_site({ 'environment' => 'default_from_config' })
    @generator = Jekyll::EnvironmentSetterGenerator.new
  end

  def teardown
    ENV['JEKYLL_ENV'] = @original_jekyll_env # Restore original ENV value
  end

  def test_env_set_and_different_from_site_config
    current_env_val = 'production'
    ENV['JEKYLL_ENV'] = current_env_val
    @site.config['environment'] = 'development' # Initial site config

    stdout_str, _stderr_str = capture_io do
      @generator.generate(@site)
    end

    assert_equal current_env_val, @site.config['environment']
    # Assert the new initial log line
    assert_match(
      /ENVIRONMENT_SETTER_PLUGIN: Current value of JEKYLL_ENV: '#{current_env_val}'/,
      stdout_str
    )
    # Assert the subsequent update log line
    assert_match(
      /ENVIRONMENT_SETTER_PLUGIN: Updated site\.config\['environment'\] from '"development"' to '#{current_env_val}' \(based on ENV\['JEKYLL_ENV'\]\)\./,
      stdout_str
    )
  end

  def test_env_set_and_same_as_site_config
    current_env_val = 'staging'
    ENV['JEKYLL_ENV'] = current_env_val
    @site.config['environment'] = current_env_val # Initial site config matches ENV

    stdout_str, _stderr_str = capture_io do
      @generator.generate(@site)
    end

    assert_equal current_env_val, @site.config['environment']
    assert_match(
      /ENVIRONMENT_SETTER_PLUGIN: Current value of JEKYLL_ENV: '#{current_env_val}'/,
      stdout_str
    )
    assert_match(
      /ENVIRONMENT_SETTER_PLUGIN: site\.config\['environment'\] already matched ENV\['JEKYLL_ENV'\] \('#{current_env_val}'\)\. No change needed\./,
      stdout_str
    )
  end

  def test_env_not_set_site_config_remains
    ENV['JEKYLL_ENV'] = nil # current_env_val will be empty string in the log
    @site.config['environment'] = 'development' # Initial site config

    stdout_str, _stderr_str = capture_io do
      @generator.generate(@site)
    end

    assert_equal 'development', @site.config['environment']
    # ENV is nil, so logged as empty
    assert_match(/ENVIRONMENT_SETTER_PLUGIN: Current value of JEKYLL_ENV: ''/, stdout_str)
    assert_match(
      /ENVIRONMENT_SETTER_PLUGIN: ENV\['JEKYLL_ENV'\] not found or empty\. site\.config\['environment'\] is '"development"'\./,
      stdout_str
    )
  end

  def test_env_set_to_empty_string_site_config_remains
    current_env_val = ''
    ENV['JEKYLL_ENV'] = current_env_val
    @site.config['environment'] = 'development' # Initial site config

    stdout_str, _stderr_str = capture_io do
      @generator.generate(@site)
    end

    assert_equal 'development', @site.config['environment']
    assert_match(/ENVIRONMENT_SETTER_PLUGIN: Current value of JEKYLL_ENV: '#{current_env_val}'/, stdout_str)
    assert_match(
      /ENVIRONMENT_SETTER_PLUGIN: ENV\['JEKYLL_ENV'\] not found or empty\. site\.config\['environment'\] is '"development"'\./,
      stdout_str
    )
  end

  def test_site_config_initially_nil_env_is_set
    current_env_val = 'test_override'
    ENV['JEKYLL_ENV'] = current_env_val
    @site.config['environment'] = nil # Explicitly set to nil

    stdout_str, _stderr_str = capture_io do
      @generator.generate(@site)
    end

    assert_equal current_env_val, @site.config['environment']
    assert_match(
      /ENVIRONMENT_SETTER_PLUGIN: Current value of JEKYLL_ENV: '#{current_env_val}'/,
      stdout_str
    )
    assert_match(
      /ENVIRONMENT_SETTER_PLUGIN: Updated site\.config\['environment'\] from 'nil' to '#{current_env_val}' \(based on ENV\['JEKYLL_ENV'\]\)\./,
      stdout_str
    )
  end

  def test_site_config_initially_nil_env_not_set
    ENV['JEKYLL_ENV'] = nil # current_env_val will be empty string in the log
    @site.config['environment'] = nil # Explicitly set to nil

    stdout_str, _stderr_str = capture_io do
      @generator.generate(@site)
    end

    assert_nil @site.config['environment']
    # ENV is nil, so logged as empty
    assert_match(/ENVIRONMENT_SETTER_PLUGIN: Current value of JEKYLL_ENV: ''/, stdout_str)
    assert_match(
      /ENVIRONMENT_SETTER_PLUGIN: ENV\['JEKYLL_ENV'\] not found or empty\. site\.config\['environment'\] is 'nil'\./,
      stdout_str
    )
  end

  def test_generator_priority_is_highest
    assert_equal :highest, Jekyll::EnvironmentSetterGenerator.priority
  end
end
