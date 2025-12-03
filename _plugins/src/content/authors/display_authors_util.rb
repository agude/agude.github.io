# frozen_string_literal: true

# _plugins/utils/display_authors_util.rb
require 'cgi'
require_relative 'author_link_util'
require_relative '../../infrastructure/text_processing_utils'
require_relative '../../infrastructure/front_matter_utils'

# Utility module for rendering author lists as formatted HTML sentences.
#
# Handles author name processing, optional linking to author pages,
# and "et al." truncation.
module DisplayAuthorsUtil
  def self.render_author_list(author_input:, context:, linked: true, etal_after: nil)
    # Process author input into array of names
    author_names = FrontMatterUtils.get_list_from_string_or_array(author_input)
    return '' if author_names.empty?

    # Map over author names to create processed elements
    processed_authors = author_names.map do |name|
      if linked
        AuthorLinkUtils.render_author_link(name, context)
      else
        "<span class=\"author-name\">#{CGI.escapeHTML(name)}</span>"
      end
    end

    # Format as sentence with optional et al.
    TextProcessingUtils.format_list_as_sentence(processed_authors, etal_after: etal_after)
  end
end
