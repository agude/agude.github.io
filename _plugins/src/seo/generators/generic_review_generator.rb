# frozen_string_literal: true

# _plugins/utils/json_ld_generators/generic_review_generator.rb
require 'jekyll'
require_relative 'generic_review_generator_class'

module Jekyll
  # Generates JSON-LD Review schema for generic reviews.
  module SEO
    module Generators
      # Utility module for generating JSON-LD Review schema for generic reviews.
      # Delegates to GenericReviewGenerator class for implementation.
      module GenericReviewLdGenerator
        def self.generate_hash(document, site)
          Jekyll::SEO::Generators::GenericReviewGenerator.new(document, site).generate
        end
      end
    end
  end
end
