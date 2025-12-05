# frozen_string_literal: true

# _plugins/utils/json_ld_generators/book_review_generator.rb
require 'jekyll'
require_relative 'book_review_generator_class'

module Jekyll
  # Generates JSON-LD Review schema for book reviews.
  module SEO
    module Generators
      # Utility module for generating JSON-LD Review schema for book reviews.
      # Delegates to BookReviewGenerator class for implementation.
      module BookReviewLdGenerator
        def self.generate_hash(document, site)
          Jekyll::SEO::Generators::BookReviewGenerator.new(document, site).generate
        end
      end
    end
  end
end
