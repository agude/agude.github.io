# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/seo/generators/generic_review_generator'

# Tests delegation from GenericReviewLdGenerator module to GenericReviewGenerator class.
class TestGenericReviewLdGenerator < Minitest::Test
  def setup
    @site = create_site
    @doc = create_doc
  end

  def test_generate_hash_delegates_to_class
    mock_hash = { '@type' => 'Review' }

    # Create a mock generator instance
    mock_generator = Minitest::Mock.new
    mock_generator.expect :generate, mock_hash

    # Stub .new to return the mock
    Jekyll::SEO::Generators::GenericReviewGenerator.stub :new, mock_generator do
      result = Jekyll::SEO::Generators::GenericReviewLdGenerator.generate_hash(@doc, @site)
      assert_equal mock_hash, result
    end

    mock_generator.verify
  end
end
