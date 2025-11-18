# _plugins/display_ranked_by_backlinks_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/book_link_util'

module Jekyll
  class DisplayRankedByBacklinksTag < Liquid::Tag
    

    def render(context)
      site = context.registers[:site]
      unless site&.data&.dig('link_cache', 'backlinks') && site.data.dig('link_cache', 'books')
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'RANKED_BY_BACKLINKS',
          reason: 'Prerequisites missing: link_cache, backlinks, or books cache.',
          level: :error
        )
      end

      backlinks_cache = site.data['link_cache']['backlinks']
      books_cache = site.data['link_cache']['books']

      # Build a reverse map from URL to the first book data object found for that URL.
      # This is needed to get the title from a URL.
      url_to_book_map = {}
      books_cache.values.flatten.each do |book_data|
        url_to_book_map[book_data['url']] ||= book_data
      end

      # Process the backlinks cache to get a sortable list.
      ranked_list = backlinks_cache.map do |url, sources|
        book_data = url_to_book_map[url]
        next unless book_data # Skip if this URL doesn't correspond to a known book.

        {
          title: book_data['title'],
          url: url,
          count: sources.length
        }
      end.compact.sort_by { |item| -item[:count] } # Sort by count descending.

      return '<p>No books have been mentioned yet.</p>' if ranked_list.empty?

      # Render the final HTML as an ordered list.
      output = "<ol class=\"ranked-list\">\n"
      ranked_list.each do |item|
        # Use BookLinkUtils to create a consistent link to the book review.
        book_link_html = BookLinkUtils.render_book_link_from_data(item[:title], item[:url], context)
        mention_text = item[:count] == 1 ? '1 mention' : "#{item[:count]} mentions"
        output << "  <li>#{book_link_html} <span class=\"mention-count\">(#{mention_text})</span></li>\n"
      end
      output << '</ol>'

      output
    end
  end
end

Liquid::Template.register_tag('display_ranked_by_backlinks', Jekyll::DisplayRankedByBacklinksTag)
