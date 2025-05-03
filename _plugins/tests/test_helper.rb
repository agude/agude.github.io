# _plugins/tests/test_helper.rb
require 'minitest/autorun'
require 'jekyll' # Still need Jekyll base classes

# Add the parent _plugins directory to the load path
# Since this file is IN _plugins/tests, '../' goes up to _plugins
$LOAD_PATH.unshift(File.expand_path('..', __dir__))

# Require the utility file we want to test
require 'liquid_utils'

# Minimal helper to create a context (can be expanded later)
def create_dummy_context(registers = {})
  Liquid::Context.new({}, {}, registers)
end

# Minimal mock site (expand as needed)
def create_dummy_site(config = {})
   Struct.new(:config).new(
     { 'environment' => 'test', 'baseurl' => '', 'plugin_logging' => {} }.merge(config)
   )
end

puts "Minimal test helper loaded."
