# frozen_string_literal: true

# _tests/plugins/test_environment_setter.rb
require_relative '../../test_helper'
require_relative '../../../_plugins/src/infrastructure/environment_setter' # Load the generator

# Tests for Jekyll::Infrastructure::EnvironmentSetterGenerator.
#
# Verifies that the generator correctly sets site.config['environment'] from ENV.
class TestEnvironmentSetterGenerator < Minitest::Test
  def setup
    @original_jekyll_env = ENV.fetch('JEKYLL_ENV', nil) # Store original ENV value
    # Create a site with a default 'environment' to test against
    @site = create_site({ 'environment' => 'default_from_config' })
    @generator = Jekyll::Infrastructure::EnvironmentSetterGenerator.new
  end

  def teardown
    ENV['JEKYLL_ENV'] = @original_jekyll_env # Restore original ENV value
  end

  def test_env_set_and_different_from_site_config
    current_env_val = 'production'
    ENV['JEKYLL_ENV'] = current_env_val
    @site.config['environment'] = 'development' # Initial site config

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:info, nil, ['EnvironmentSetter:', "Current value of JEKYLL_ENV: '#{current_env_val}'"])
    mock_logger.expect(:info, nil) do |prefix, msg|
      prefix == 'EnvironmentSetter:' && msg.include?("Updated site.config['environment'] from '\"development\"' to '#{current_env_val}'")
    end

    Jekyll.stub :logger, mock_logger do
      @generator.generate(@site)
    end

    assert_equal current_env_val, @site.config['environment']
    mock_logger.verify
  end

  def test_env_set_and_same_as_site_config
    current_env_val = 'staging'
    ENV['JEKYLL_ENV'] = current_env_val
    @site.config['environment'] = current_env_val # Initial site config matches ENV

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:info, nil, ['EnvironmentSetter:', "Current value of JEKYLL_ENV: '#{current_env_val}'"])
    mock_logger.expect(:info, nil) do |prefix, msg|
      prefix == 'EnvironmentSetter:' && msg.include?("site.config['environment'] already matched ENV['JEKYLL_ENV'] ('#{current_env_val}')")
    end

    Jekyll.stub :logger, mock_logger do
      @generator.generate(@site)
    end

    assert_equal current_env_val, @site.config['environment']
    mock_logger.verify
  end

  def test_env_not_set_site_config_remains
    ENV['JEKYLL_ENV'] = nil
    @site.config['environment'] = 'development' # Initial site config

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:info, nil, ['EnvironmentSetter:', "Current value of JEKYLL_ENV: ''"])
    mock_logger.expect(:info, nil) do |prefix, msg|
      prefix == 'EnvironmentSetter:' && msg.include?("ENV['JEKYLL_ENV'] not found or empty") && msg.include?("site.config['environment'] is '\"development\"'")
    end

    Jekyll.stub :logger, mock_logger do
      @generator.generate(@site)
    end

    assert_equal 'development', @site.config['environment']
    mock_logger.verify
  end

  def test_env_set_to_empty_string_site_config_remains
    current_env_val = ''
    ENV['JEKYLL_ENV'] = current_env_val
    @site.config['environment'] = 'development' # Initial site config

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:info, nil, ['EnvironmentSetter:', "Current value of JEKYLL_ENV: '#{current_env_val}'"])
    mock_logger.expect(:info, nil) do |prefix, msg|
      prefix == 'EnvironmentSetter:' && msg.include?("ENV['JEKYLL_ENV'] not found or empty") && msg.include?("site.config['environment'] is '\"development\"'")
    end

    Jekyll.stub :logger, mock_logger do
      @generator.generate(@site)
    end

    assert_equal 'development', @site.config['environment']
    mock_logger.verify
  end

  def test_site_config_initially_nil_env_is_set
    current_env_val = 'test_override'
    ENV['JEKYLL_ENV'] = current_env_val
    @site.config['environment'] = nil # Explicitly set to nil

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:info, nil, ['EnvironmentSetter:', "Current value of JEKYLL_ENV: '#{current_env_val}'"])
    mock_logger.expect(:info, nil) do |prefix, msg|
      prefix == 'EnvironmentSetter:' && msg.include?("Updated site.config['environment'] from 'nil' to '#{current_env_val}'")
    end

    Jekyll.stub :logger, mock_logger do
      @generator.generate(@site)
    end

    assert_equal current_env_val, @site.config['environment']
    mock_logger.verify
  end

  def test_site_config_initially_nil_env_not_set
    ENV['JEKYLL_ENV'] = nil
    @site.config['environment'] = nil # Explicitly set to nil

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:info, nil, ['EnvironmentSetter:', "Current value of JEKYLL_ENV: ''"])
    mock_logger.expect(:info, nil) do |prefix, msg|
      prefix == 'EnvironmentSetter:' && msg.include?("ENV['JEKYLL_ENV'] not found or empty") && msg.include?("site.config['environment'] is 'nil'")
    end

    Jekyll.stub :logger, mock_logger do
      @generator.generate(@site)
    end

    assert_nil @site.config['environment']
    mock_logger.verify
  end

  def test_generator_priority_is_highest
    assert_equal :highest, Jekyll::Infrastructure::EnvironmentSetterGenerator.priority
  end
end
