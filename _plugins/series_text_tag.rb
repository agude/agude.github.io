# _plugins/series_text_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require 'strscan'
require_relative 'liquid_utils'

module Jekyll
  # Liquid Tag to generate grammatically correct text around a linked series name.
  # - Adds "the" before the series unless the series name starts with "The ".
  # - Adds " series" after the name unless it contains a common series-type noun.
  # - Links the series name using LiquidUtils.render_series_link.
  #
  # Usage: {% series_text "Series Name" %}
  #        {% series_text page.series_variable %}
  #
  class SeriesTextTag < Liquid::Tag
    # Keep QuotedFragment handy for parsing values
    QuotedFragment = Liquid::QuotedFragment

    # Define common words that imply a series type (sorted).
    # Check for whole words by padding with spaces during comparison.
    # Using standard array literal syntax.
    SERIES_TYPE_WORDS = [
      'anthology',
      'arc',
      'book',
      'cantos',
      'chronicle',
      'collection',
      'cycle',
      'mythos',
      'saga',
      'series',
      'sequence',
      'trilogy',
      'universe',
    ].sort.freeze

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup # Store original for potential error messages

      # --- Argument Parsing using StringScanner ---
      @series_name_markup = nil
      scanner = StringScanner.new(markup.strip)

      # Extract the Series Name (must be quoted or a variable)
      if scanner.scan(QuotedFragment)
        @series_name_markup = scanner.matched
      elsif scanner.scan(/\S+/) # Potential variable
        @series_name_markup = scanner.matched
      else
        raise Liquid::SyntaxError, "Syntax Error in 'series_text': Could not find series name in '#{@raw_markup}'"
      end

      # Ensure no other arguments are present
      scanner.skip(/\s+/)
      unless scanner.eos?
        raise Liquid::SyntaxError, "Syntax Error in 'series_text': Unexpected arguments '#{scanner.rest}' in '#{@raw_markup}'"
      end

      # Ensure series name markup was actually found
      unless @series_name_markup && !@series_name_markup.strip.empty?
         raise Liquid::SyntaxError, "Syntax Error in 'series_text': Series name value is missing or empty in '#{@raw_markup}'"
      end
      # --- End Argument Parsing ---
    end # End initialize

    # Renders the text with the linked series name
    def render(context)
      # --- Resolve Input ---
      raw_series_name = LiquidUtils.resolve_value(@series_name_markup, context)
      # Handle nil or empty resolved value gracefully
      return "" if raw_series_name.nil? || raw_series_name.to_s.strip.empty?

      stripped_series_name = raw_series_name.to_s.strip
      # Double check after stripping
      return "" if stripped_series_name.empty?

      normalized_series_name = stripped_series_name.downcase
      # --- End Resolve Input ---


      # --- Determine Prefix ---
      the_prefix = normalized_series_name.start_with?("the ") ? "" : "the "
      # --- End Determine Prefix ---


      # --- Determine Suffix ---
      contains_series_type_word = false
      padded_normalized_series = " #{normalized_series_name} "
      SERIES_TYPE_WORDS.each do |word|
        padded_word_to_check = " #{word} "
        if padded_normalized_series.include?(padded_word_to_check)
          contains_series_type_word = true
          break
        end
      end
      series_suffix = contains_series_type_word ? "" : " series"
      # --- End Determine Suffix ---


      # --- Generate Linked Series Name ---
      # Use the utility function, passing the original *stripped* name
      linked_series_html = LiquidUtils.render_series_link(stripped_series_name, context)
      # --- End Generate Linked Series Name ---


      # --- Combine and Output ---
      # Note: render_series_link might return an empty string or log comment + span
      # if the series isn't found. This logic handles that correctly.
      output = "#{the_prefix}#{linked_series_html}#{series_suffix}"

      # Strip potential leading/trailing whitespace from the final combined string
      output.strip

    end # End render

  end # End class SeriesTextTag
end # End module Jekyll

# Register the tag with Liquid
Liquid::Template.register_tag('series_text', Jekyll::SeriesTextTag)
