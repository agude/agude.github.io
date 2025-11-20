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
      original_config_env = site.config['environment']
      env_var_jekyll_env = ENV.fetch('JEKYLL_ENV', nil)

      log_current_jekyll_env(env_var_jekyll_env)

      if env_var_jekyll_env && !env_var_jekyll_env.empty?
        update_environment(site, original_config_env, env_var_jekyll_env)
      else
        log_jekyll_env_not_set(original_config_env)
      end
    end

    private

    def log_current_jekyll_env(env_var_jekyll_env)
      puts 'ENVIRONMENT_SETTER_PLUGIN: Current value of JEKYLL_ENV: ' \
           "'#{env_var_jekyll_env}'"
    end

    def update_environment(site, original_config_env, env_var_jekyll_env)
      site.config['environment'] = env_var_jekyll_env

      if original_config_env == site.config['environment']
        log_no_change_needed(site.config['environment'])
      else
        log_environment_updated(original_config_env, site.config['environment'])
      end
    end

    def log_no_change_needed(current_env)
      puts "ENVIRONMENT_SETTER_PLUGIN: site.config['environment'] already " \
           "matched ENV['JEKYLL_ENV'] ('#{current_env}'). No change needed."
    end

    def log_environment_updated(original_env, new_env)
      puts "ENVIRONMENT_SETTER_PLUGIN: Updated site.config['environment'] " \
           "from '#{original_env.inspect}' to '#{new_env}' " \
           "(based on ENV['JEKYLL_ENV'])."
    end

    def log_jekyll_env_not_set(original_config_env)
      puts "ENVIRONMENT_SETTER_PLUGIN: ENV['JEKYLL_ENV'] not found or empty. " \
           "site.config['environment'] is '#{original_config_env.inspect}'."
    end
  end
end
