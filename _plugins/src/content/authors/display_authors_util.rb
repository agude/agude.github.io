# frozen_string_literal: true

# _plugins/utils/display_authors_util.rb
require 'cgi'
require_relative 'author_link_util'
require_relative '../../infrastructure/text_processing_utils'
require_relative '../../infrastructure/front_matter_utils'

module Jekyll
  module Authors
    # Utility module for rendering author lists as formatted HTML sentences.
    #
    # Handles author name processing, optional linking to author pages,
    # and "et al." truncation.
    module DisplayAuthorsUtil
      # Aliases for readability
      FrontMatter = Jekyll::Infrastructure::FrontMatterUtils
      Text = Jekyll::Infrastructure::TextProcessingUtils
      AuthorLinker = Jekyll::Authors::AuthorLinkUtils
      private_constant :FrontMatter, :Text, :AuthorLinker

      def self.render_author_list(author_input:, context:, linked: true, etal_after: nil)
        # Process author input into array of names
        author_names = FrontMatter.get_list_from_string_or_array(author_input)
        return '' if author_names.empty?

        # Map over author names to create processed elements
        processed_authors = author_names.map do |name|
          if linked
            AuthorLinker.render_author_link(name, context)
          else
            "<span class=\"author-name\">#{CGI.escapeHTML(name)}</span>"
          end
        end

        # Format as sentence with optional et al.
        Text.format_list_as_sentence(processed_authors, etal_after: etal_after)
      end
    end
  end
end
