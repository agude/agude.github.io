# frozen_string_literal: true
# _plugins/environment_setter.rb
# Ensures that site.config['environment'] is set from ENV['JEKYLL_ENV']
# if ENV['JEKYLL_ENV'] is present. This helps make the environment
# consistently available throughout the Jekyll build process.
#
# This *WORKS* for future plugins reading site.config['environment'] but does
# not work for pages that try to read it in Liquid.

module Jekyll
  class EnvironmentSetterGenerator < Generator
    priority :highest # Run this generator as early as possible

    def generate(site)
      # Store the original value for logging, if any
      original_config_env = site.config['environment']
      env_var_jekyll_env = ENV.fetch('JEKYLL_ENV', nil)
      puts "ENVIRONMENT_SETTER_PLUGIN: Current value of JEKYLL_ENV: '#{env_var_jekyll_env}'"

      if env_var_jekyll_env && !env_var_jekyll_env.empty?
        # If JEKYLL_ENV is set, make sure site.config['environment'] matches it.
        # This is useful because Jekyll might populate site.config['environment']
        # later than some plugins (like this generator) run.
        site.config['environment'] = env_var_jekyll_env
        if original_config_env == site.config['environment']
          puts "ENVIRONMENT_SETTER_PLUGIN: site.config['environment'] already matched ENV['JEKYLL_ENV'] ('#{site.config['environment']}'). No change needed."
        else
          puts "ENVIRONMENT_SETTER_PLUGIN: Updated site.config['environment'] from '#{original_config_env.inspect}' to '#{site.config['environment']}' (based on ENV['JEKYLL_ENV'])."
        end
      else
        # If JEKYLL_ENV is not set or is empty, Jekyll will typically default
        # site.config['environment'] to 'development'. We'll log what it is.
        # If it's nil at this very early stage, PluginLoggerUtils will still default to 'development'.
        puts "ENVIRONMENT_SETTER_PLUGIN: ENV['JEKYLL_ENV'] not found or empty. site.config['environment'] is '#{original_config_env.inspect}'."
      end
    end
  end
end
