# frozen_string_literal: true

require 'nokogiri'

module Jekyll
  module Infrastructure
    module Text
      # Utilities for extracting plain text from HTML.
      module HtmlTextUtils
        # Strip all HTML tags and decode entities, returning plain text.
        def self.strip_tags(html)
          Nokogiri::HTML.fragment(html.to_s).text
        end
      end
    end
  end
end
