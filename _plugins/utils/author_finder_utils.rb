# _plugins/utils/author_finder_utils.rb
require_relative 'text_processing_utils'
require_relative 'front_matter_utils'

module AuthorFinderUtils
  # Finds an author's canonical page document by searching for a name that matches
  # either the page's title or one of its listed pen_names.
  #
  # @param name [String] The name to search for (canonical or pen name).
  # @param site [Jekyll::Site] The Jekyll site object.
  # @return [Jekyll::Document, Jekyll::Page, nil] The found author page document, or nil if not found.
  def self.find_author_page_by_name(name, site)
    normalized_name = TextProcessingUtils.normalize_title(name)
    return nil if normalized_name.empty?

    # Find the first page that matches the criteria.
    site.pages.find do |p|
      next unless p.data['layout'] == 'author_page'

      # Check 1: Match against the page's canonical title.
      page_title_normalized = TextProcessingUtils.normalize_title(p.data['title'])
      return p if page_title_normalized == normalized_name

      # Check 2: Match against the page's pen_names.
      pen_names_list = FrontMatterUtils.get_list_from_string_or_array(p.data['pen_names'])
      normalized_pen_names = pen_names_list.map { |pn| TextProcessingUtils.normalize_title(pn) }
      return p if normalized_pen_names.include?(normalized_name)

      # If neither matches, this page is not the one we're looking for.
      nil
    end
  end
end
