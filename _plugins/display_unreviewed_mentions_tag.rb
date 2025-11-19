# _plugins/display_unreviewed_mentions_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/text_processing_utils'

module Jekyll
  class DisplayUnreviewedMentionsTag < Liquid::Tag
    def render(context)
      site = context.registers[:site]
      unless site && site.data['mention_tracker'] && site.data.dig('link_cache', 'books')
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'UNREVIEWED_MENTIONS',
          reason: "Prerequisites missing: mention_tracker or link_cache['books'] not found.",
          level: :error
        )
      end

      tracker = site.data['mention_tracker']
      books_cache = site.data['link_cache']['books']

      # Create a set of all normalized titles of books that DO exist for efficient filtering.
      existing_book_titles = Set.new(books_cache.keys)

      ranked_list = tracker.map do |normalized_title, data|
        # CRITICAL: Skip this entry if a book with this normalized title actually exists.
        next if existing_book_titles.include?(normalized_title)

        # Find the most frequently used original casing for the title to display it nicely.
        display_title = data[:original_titles].max_by { |_, count| count }&.first || normalized_title

        {
          title: display_title,
          count: data[:sources].size
        }
      end.compact.sort_by { |item| -item[:count] } # Sort by count descending.

      return '<p>No unreviewed works have been mentioned yet.</p>' if ranked_list.empty?

      # Render the final HTML as an ordered list.
      output = "<ol class=\"ranked-list\">\n"
      ranked_list.each do |item|
        # These are unlinked, so we just wrap them in <cite> and escape them.
        mention_text = item[:count] == 1 ? '1 mention' : "#{item[:count]} mentions"
        output << "  <li><cite>#{CGI.escapeHTML(item[:title])}</cite> <span class=\"mention-count\">(#{mention_text})</span></li>\n"
      end
      output << '</ol>'

      output
    end
  end
end

Liquid::Template.register_tag('display_unreviewed_mentions', Jekyll::DisplayUnreviewedMentionsTag)
