# _plugins/archived_review_block_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative 'utils/rating_utils'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/tag_argument_utils'

module Jekyll
  # Defines a Liquid Block tag for rendering an archived review.
  #
  # This tag is used to wrap the markdown content of a previous review.
  # It uses a `date` parameter to look up corresponding metadata (like rating)
  # from an `archived_reviews` array in the page's front matter.
  # It renders the complete HTML for a single review instance directly.
  #
  # Syntax:
  # {% archived_review date="YYYY-MM-DD" %}
  #   ... markdown content of the old review ...
  # {% endarchived_review %}
  #
  class ArchivedReviewBlockTag < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup

      # Use a simple, direct regex to parse the 'date' argument.
      # This is more robust for a single, required argument.
      # It looks for `date=` followed by a quoted string, and nothing else.
      if match = markup.strip.match(/\Adate\s*=\s*(?<value>#{Liquid::QuotedFragment})\z/)
        @date_markup = match[:value]
      else
        # If the regex fails, the markup is invalid.
        raise Liquid::SyntaxError, "Syntax Error in 'archived_review' block: Invalid arguments '#{@raw_markup.strip}'. Expected `date=\"YYYY-MM-DD\"`."
      end
    end

    def render(context)
      # `super` contains the raw markdown content from inside the block.
      block_content_markdown = super.strip

      page = context.registers[:page]
      site = context.registers[:site]
      archived_reviews_fm = page['archived_reviews']

      target_date_str = TagArgumentUtils.resolve_value(@date_markup, context).to_s

      # Find the matching metadata in the page's front matter.
      review_data = nil
      if archived_reviews_fm.is_a?(Array)
        review_data = archived_reviews_fm.find { |r| r['date'].to_s == target_date_str }
      end

      unless review_data
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "ARCHIVED_REVIEW_BLOCK",
          reason: "Could not find metadata in `archived_reviews` for the specified date.",
          identifiers: { date: target_date_str, page: page['path'] },
          level: :error
        )
      end

      rating = review_data['rating']
      date_obj = review_data['date']

      # Use the site's configured markdown converter to process the block content.
      converter = site.find_converter_instance(Jekyll::Converters::Markdown)
      block_content_html = converter.convert(block_content_markdown)

      # Assemble the HTML for this archived review instance.
      output = "<div class=\"review-instance archived\">"
      output << "<hr>"
      output << "<h3>Review from #{date_obj.strftime('%B %d, %Y')}</h3>"
      output << RatingUtils.render_rating_stars(rating, 'div') if rating
      output << "<div class=\"review-content\">#{block_content_html}</div>"
      output << "</div>"

      output
    end
  end
end

Liquid::Template.register_tag('archived_review', Jekyll::ArchivedReviewBlockTag)