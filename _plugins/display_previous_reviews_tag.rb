# frozen_string_literal: true

# _plugins/display_previous_reviews_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/book_card_utils'

module Jekyll
  # Displays previous reviews of the same book sorted by date.
  #
  # Finds all book reviews that share the same canonical URL and displays
  # them chronologically.
  #
  # Usage in Liquid templates:
  #   {% display_previous_reviews %}
  class DisplayPreviousReviewsTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      return if markup.strip.empty?

      raise Liquid::SyntaxError, "Syntax Error in 'display_previous_reviews': This tag does not accept any arguments."
    end

    def render(context)
      PreviousReviewsRenderer.new(context).render
    end

    # Helper class to handle rendering logic
    class PreviousReviewsRenderer
      def initialize(context)
        @context = context
        @site = context.registers[:site]
        @page = context.registers[:page]
      end

      def render
        return handle_missing_prerequisites unless valid_prerequisites?

        archived_docs = find_archived_docs
        return '' if archived_docs.empty?

        render_reviews(archived_docs.sort_by(&:date).reverse)
      end

      private

      def valid_prerequisites?
        @site && @page && @page['url']
      end

      def handle_missing_prerequisites
        PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'PREVIOUS_REVIEWS',
          reason: 'Prerequisites missing: site, page, or page.url.',
          level: :error
        )
      end

      def find_archived_docs
        @site.collections['books'].docs.select do |book|
          book.data['canonical_url'] == @page['url']
        end
      end

      def render_reviews(sorted_docs)
        output = +"<aside class=\"previous-reviews\">\n"
        output << "  <h2 class=\"book-review-headline\">Previous Reviews</h2>\n"
        output << "  <div class=\"card-grid\">\n"

        sorted_docs.each do |doc|
          subtitle = "Review from #{doc.date.strftime('%B %d, %Y')}"
          output << BookCardUtils.render(doc, @context, subtitle: subtitle)
        end

        output << "  </div>\n"
        output << '</aside>'
        output
      end
    end
  end
end

Liquid::Template.register_tag('display_previous_reviews', Jekyll::DisplayPreviousReviewsTag)
