# _plugins/display_books_for_series_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'liquid_utils'
require_relative 'utils/book_list_utils'

module Jekyll
  class DisplayBooksForSeriesTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @series_name_markup = markup.strip
      if @series_name_markup.empty?
        raise Liquid::SyntaxError, "Syntax Error in 'display_books_for_series': Series name (string literal or variable) is required."
      end
    end

    def render(context)
      site = context.registers[:site]
      # Resolve the series name from the markup
      series_name_input = LiquidUtils.resolve_value(@series_name_markup, context)

      # Validate resolved series name
      unless series_name_input && !series_name_input.to_s.strip.empty?
        # If series name resolves to nil or empty, log it via BookListUtils by passing it as is.
        # BookListUtils.get_data_for_series_display will handle logging this specific case.
        # Or, we can log directly here if preferred for tag-level input validation.
        # For consistency with how BookListUtils handles it:
        data = BookListUtils.get_data_for_series_display(
          site: site,
          series_name_filter: series_name_input, # Pass potentially nil/empty to let util log
          context: context
        )
        return data[:log_messages] || "" # Return only the log message (HTML comment or empty)
      end

      data = BookListUtils.get_data_for_series_display(
        site: site,
        series_name_filter: series_name_input.to_s, # Ensure string
        context: context
      )

      # data[:log_messages] will contain any HTML comment from log_failure if no books were found.
      # If books are found, data[:log_messages] should be empty or nil.
      output = data[:log_messages] || ""

      if data[:books].empty?
        return output # Return only log message if no books (util already logged)
      end

      # If books are present, render them
      output << "<div class=\"card-grid\">\n"
      data[:books].each do |book|
        output << LiquidUtils.render_book_card(book, context) << "\n"
      end
      output << "</div>\n"
      output
    end
  end
  Liquid::Template.register_tag('display_books_for_series', DisplayBooksForSeriesTag)
end
