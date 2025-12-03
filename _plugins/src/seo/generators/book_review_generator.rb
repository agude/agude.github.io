# frozen_string_literal: true

# _plugins/utils/json_ld_generators/book_review_generator.rb
require 'jekyll'
require_relative 'book_review_generator_class'

# Generates JSON-LD Review schema for book reviews.
module BookReviewLdGenerator
  def self.generate_hash(document, site)
    BookReviewGenerator.new(document, site).generate
  end
end
