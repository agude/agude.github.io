# frozen_string_literal: true

# _plugins/utils/json_ld_generators/generic_review_generator.rb
require 'jekyll'
require_relative 'generic_review_generator_class'

# Generates JSON-LD Review schema for generic reviews.
module GenericReviewLdGenerator
  def self.generate_hash(document, site)
    GenericReviewGenerator.new(document, site).generate
  end
end
