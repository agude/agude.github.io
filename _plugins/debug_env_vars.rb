# _plugins/debug_env_vars.rb
module Jekyll
  class DebugEnvVarsGenerator < Generator
    priority :highest # Run it early
    def generate(site)
      puts "GH_ACTIONS_DEBUG_PLUGIN: Initial site.config['environment'] = #{site.config['environment'].inspect}"
      puts "GH_ACTIONS_DEBUG_PLUGIN: Initial Ruby ENV['JEKYLL_ENV'] = #{ENV['JEKYLL_ENV'].inspect}"

      # You could even try to force it here for testing, though this isn't a solution
      # site.config['environment'] = ENV['JEKYLL_ENV'] if ENV['JEKYLL_ENV']
      # puts "GH_ACTIONS_DEBUG_PLUGIN: After potential force: site.config['environment'] = #{site.config['environment'].inspect}"
    end
  end
end
