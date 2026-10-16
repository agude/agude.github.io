# frozen_string_literal: true

module Jekyll
  module Infrastructure
    # Sets site.config['environment'] from a non-empty JEKYLL_ENV, and
    # otherwise keeps the configured value. Plugins such as
    # PluginLoggerUtils read site.config['environment']; Liquid templates
    # read jekyll.environment, which Jekyll sets on its own.
    class EnvironmentSetterGenerator < Generator
      priority :highest # Run before any plugin reads the value.

      def generate(site)
        configured = site.config['environment']
        jekyll_env = ENV.fetch('JEKYLL_ENV', '')
        site.config['environment'] = jekyll_env unless jekyll_env.empty?

        Jekyll.logger.info 'EnvironmentSetter:',
                           "site.config['environment'] is #{site.config['environment'].inspect} " \
                           "(JEKYLL_ENV: #{jekyll_env.inspect}, configured: #{configured.inspect})."
      end
    end
  end
end
