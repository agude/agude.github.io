# frozen_string_literal: true

require_relative '../test_helper'
require_relative 'related_book_fixture'

# Shared setup for related-book finder scenarios.
class RelatedBookFinderTestCase < Minitest::Test
  DEFAULT_MAX_BOOKS = Jekyll::Books::Related::Finder::DEFAULT_MAX_BOOKS
  CONFIG_KEY = 'display_limits'

  def setup
    @site_config_base = {
      'url' => 'http://example.com',
      'plugin_logging' => { 'RELATED_BOOKS' => true, 'RELATED_BOOKS_SERIES' => true },
      'plugin_log_level' => 'debug',
    }
    @test_time_now = Time.parse('2024-03-15 10:00:00 EST')
    @helper = RelatedBookFixture.new(@test_time_now, @site_config_base)
    @helper.setup_generic_books
    @context = create_context({}, { site: create_site, page: create_doc })
  end
end
