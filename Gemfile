# frozen_string_literal: true

# Gemfile
source 'https://rubygems.org'

# Specify Jekyll version 4.x
gem 'jekyll', '~> 4.3'

# Add plugins explicitly since we are not using the github-pages gem
gem 'jekyll-feed', '~> 0.17.0'
# NOTE: jekyll-paginate is deprecated in Jekyll 4. Consider migrating to jekyll-paginate-v2.
gem 'jekyll-paginate', '~> 1.1.0'
gem 'jekyll-redirect-from', '~> 0.16.0'
gem 'jekyll-seo-tag', '~> 2.8.0'
gem 'jekyll-sitemap', '~> 1.4.0'

# Required for `jekyll serve` in Ruby 3+
gem 'webrick', '~> 1.9'

# Required by Jekyll/deps, will be default gem later
gem 'logger', '~> 1.7'

# For parsing HTML in custom plugins
gem 'nokogiri', '~> 1.18'

# Tests
group :development, :test do
  gem "html-proofer", "~> 5.0"
  gem 'minitest', '~> 5.25'
  gem 'rake', '~> 13.0'      # For creating command-line tasks
  gem 'rubocop', '~> 1.81'   # For Ruby linting
  gem 'simplecov', '~> 0.22' # For code coverage
  gem 'simplecov-json', '~> 0.2.3' # For generating JSON coverage reports
end
