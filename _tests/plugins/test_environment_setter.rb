# _tests/plugins/test_environment_setter.rb
require_relative '../test_helper'
require_relative '../../_plugins/environment_setter' # Load the generator

class TestEnvironmentSetterGenerator < Minitest::Test
  def setup
    @original_jekyll_env = ENV['JEKYLL_ENV'] # Store original ENV value
    # Create a site with a default 'environment' to test against
    @site = create_site({ 'environment' => 'default_from_config' })
    @generator = Jekyll::EnvironmentSetterGenerator.new
  end

  def teardown
    ENV['JEKYLL_ENV'] = @original_jekyll_env # Restore original ENV value
  end

  def test_env_set_and_different_from_site_config
    ENV['JEKYLL_ENV'] = 'production'
    @site.config['environment'] = 'development' # Initial site config

    stdout_str, _stderr_str = capture_io do
      @generator.generate(@site)
    end

    assert_equal 'production', @site.config['environment']
    assert_match %r{ENVIRONMENT_SETTER_PLUGIN: Updated site\.config\['environment'\] from '"development"' to 'production' \(based on ENV\['JEKYLL_ENV'\]\)\.}, stdout_str
  end

  def test_env_set_and_same_as_site_config
    ENV['JEKYLL_ENV'] = 'staging'
    @site.config['environment'] = 'staging' # Initial site config matches ENV

    stdout_str, _stderr_str = capture_io do
      @generator.generate(@site)
    end

    assert_equal 'staging', @site.config['environment']
    # Adjusted regex: environment name is NOT inspect-quoted here.
    assert_match %r{ENVIRONMENT_SETTER_PLUGIN: site\.config\['environment'\] already matched ENV\['JEKYLL_ENV'\] \('staging'\)\. No change needed\.}, stdout_str
  end

  def test_env_not_set_site_config_remains
    ENV['JEKYLL_ENV'] = nil
    @site.config['environment'] = 'development' # Initial site config

    stdout_str, _stderr_str = capture_io do
      @generator.generate(@site)
    end

    assert_equal 'development', @site.config['environment']
    assert_match %r{ENVIRONMENT_SETTER_PLUGIN: ENV\['JEKYLL_ENV'\] not found or empty\. site\.config\['environment'\] is '"development"'\.}, stdout_str
  end

  def test_env_set_to_empty_string_site_config_remains
    ENV['JEKYLL_ENV'] = ''
    @site.config['environment'] = 'development' # Initial site config

    stdout_str, _stderr_str = capture_io do
      @generator.generate(@site)
    end

    assert_equal 'development', @site.config['environment']
    assert_match %r{ENVIRONMENT_SETTER_PLUGIN: ENV\['JEKYLL_ENV'\] not found or empty\. site\.config\['environment'\] is '"development"'\.}, stdout_str
  end

  def test_site_config_initially_nil_env_is_set
    ENV['JEKYLL_ENV'] = 'test_override'
    @site.config['environment'] = nil # Explicitly set to nil

    stdout_str, _stderr_str = capture_io do
      @generator.generate(@site)
    end

    assert_equal 'test_override', @site.config['environment']
    assert_match %r{ENVIRONMENT_SETTER_PLUGIN: Updated site\.config\['environment'\] from 'nil' to 'test_override' \(based on ENV\['JEKYLL_ENV'\]\)\.}, stdout_str
  end

  def test_site_config_initially_nil_env_not_set
    ENV['JEKYLL_ENV'] = nil
    @site.config['environment'] = nil # Explicitly set to nil

    stdout_str, _stderr_str = capture_io do
      @generator.generate(@site)
    end

    assert_nil @site.config['environment']
    assert_match %r{ENVIRONMENT_SETTER_PLUGIN: ENV\['JEKYLL_ENV'\] not found or empty\. site\.config\['environment'\] is 'nil'\.}, stdout_str
  end

  def test_generator_priority_is_highest
    assert_equal :highest, Jekyll::EnvironmentSetterGenerator.priority
  end
end
