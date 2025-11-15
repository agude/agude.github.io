# _plugins/display_previous_reviews_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/book_card_utils'

module Jekyll
  class DisplayPreviousReviewsTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      return if markup.strip.empty?

      raise Liquid::SyntaxError, "Syntax Error in 'display_previous_reviews': This tag does not accept any arguments."
    end

    def render(context)
      site = context.registers[:site]
      page = context.registers[:page]

      unless site && page && page['url']
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'PREVIOUS_REVIEWS',
          reason: 'Prerequisites missing: site, page, or page.url.',
          level: :error
        )
      end

      # Find all books that are archived versions of the current page
      archived_docs = site.collections['books'].docs.select do |book|
        book.data['canonical_url'] == page['url']
      end

      return '' if archived_docs.empty?

      # Sort by date, most recent first
      sorted_docs = archived_docs.sort_by { |doc| doc.date }.reverse

      output = "<aside class=\"previous-reviews\">\n"
      output << "  <h2 class=\"book-review-headline\">Previous Reviews</h2>\n"
      output << "  <div class=\"card-grid\">\n"

      sorted_docs.each do |doc|
        subtitle = "Review from #{doc.date.strftime('%B %d, %Y')}"
        # Call the utility directly, which is more efficient than rendering a tag
        output << BookCardUtils.render(doc, context, subtitle: subtitle)
      end

      output << "  </div>\n"
      output << '</aside>'

      output
    end
  end
end

Liquid::Template.register_tag('display_previous_reviews', Jekyll::DisplayPreviousReviewsTag)
