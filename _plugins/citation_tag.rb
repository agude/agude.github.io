#   -----------------------------------------------------------------------------
#   BLANK CITATION TAG TEMPLATE
#   -----------------------------------------------------------------------------
#   Fill in the appropriate values for each parameter.
#   Omit any parameters that are not applicable to the citation.
#   The 'url' parameter will link the 'work_title'.
#   If 'work_title' is absent but 'container_title' is present, and 'url' is given,
#   the 'container_title' might be linked (depending on your CitationUtils logic).
#   Styling of 'work_title' (quotes vs. italics) is inferred based on the
#   presence or absence of 'container_title'.
#
# {% citation
#   author_first=""       First name(s) or initials of the author(s). For multiple authors, list them as they should appear, e.g., "John A. and Jane B." or "J. Doe, F. Bar".
#   author_last=""        Last name of the primary author, or "Group Name et al." or "Collaboration Name".
#   author_handle=""      Optional: A social media handle or similar identifier, e.g., "@username". Often displayed in parentheses after the name.
#   work_title=""         The title of the specific work being cited (e.g., article title, chapter title, book title if cited as a whole, webpage title). This is the primary cited entity.
#   container_title=""    The title of the larger publication or source that contains the work_title (e.g., journal name, book title if work_title is a chapter, website name).
#   editor=""             Name(s) of the editor(s), if applicable (e.g., for an edited collection).
#   edition=""            Edition information, if not the first (e.g., "2nd", "Revised"). The "ed" part is handled by the citation utility.
#   volume=""             Volume number (e.g., for a journal or multi-volume book).
#   number=""             Issue number (e.g., for a journal). Sometimes referred to as "issue".
#   publisher=""          Name of the publisher (e.g., "Academic Press", "University of California Press").
#   date=""               Publication date. Can be a year (YYYY), full date (Month DD, YYYY or YYYY-MM-DD), or season/year (Spring YYYY).
#   first_page=""         Starting page number or article identifier (e.g., "101", "A27").
#   last_page=""          Ending page number, if it's a range (e.g., "115").
#   page=""               A single page number if not a range and first_page/last_page are not suitable (e.g., "p. 5").
#   doi=""                Digital Object Identifier (e.g., "10.1234/xyz.567"). Can also be used for arXiv IDs like "arXiv:2301.00001".
#   url=""                The primary URL for the citation. This URL will be used to link the work_title. If work_title is absent, it might link container_title.
#   access_date=""        Date when an online resource was last accessed or verified (e.g., "January 15, 2023").
# %}

# _plugins/citation_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan' # StringScanner is appropriate for this parsing task
require_relative 'utils/citation_utils'
require_relative 'utils/tag_argument_utils'

# Module for Jekyll specific plugins
module Jekyll
  # Defines a Liquid tag for generating citations.
  #
  # Syntax:
  # {% citation author_last="Doe" author_first="John" work_title="My Article" ... %}
  #
  # All parameters are optional and correspond to the keys expected by
  # CitationUtils.format_citation_html. Values can be string literals
  # (in single or double quotes) or Liquid variables.
  class CitationTag < Liquid::Tag
    # Regex for parsing "key='value'" or "key=variable" arguments.
    # - [\w-]+ : Matches the key (alphanumeric, underscore, hyphen).
    # - \s*=\s* : Matches the equals sign with optional surrounding whitespace.
    # - (value_pattern) : Captures the value.
    #   - (['"])(?:(?!\3).)*\3 : Matches a quoted string. \3 backreferences the opening quote.
    #   - | : OR
    #   - \S+ : Matches one or more non-whitespace characters (for variables).
    ARG_SYNTAX = /([\w-]+)\s*=\s*((['"])(?:(?!\3).)*\3|\S+)/o

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup.strip # Store the raw markup, stripped of leading/trailing whitespace
      @attributes_markup = {}   # Hash to store the raw markup for each attribute's value

      # Use StringScanner to parse the arguments
      scanner = StringScanner.new(@raw_markup)

      # Loop through the markup, matching key=value pairs
      while scanner.scan(ARG_SYNTAX)
        key = scanner[1]          # The captured key (e.g., "author_last")
        value_markup = scanner[2] # The captured raw value markup (e.g., "'Doe'" or "page.author")

        # Store the raw value markup, to be resolved later in the render context
        @attributes_markup[key.to_sym] = value_markup

        scanner.skip(/\s*/) # Skip any whitespace before the next argument
      end

      # After the loop, if the scanner is not at the end of the string,
      # it means there was some unparseable text, indicating a syntax error.
      unless scanner.eos?
        raise Liquid::SyntaxError, "Syntax Error in 'citation' tag: Invalid arguments near '#{scanner.rest}' in '#{@raw_markup}'"
      end
    end

    def render(context)
      # Get the site object from the Liquid context registers
      site = context.registers[:site]

      # Hash to hold the resolved values of the parameters
      resolved_params = {}

      # Iterate over the stored attribute markups and resolve their actual values
      @attributes_markup.each do |key, value_markup|
        resolved_params[key] = TagArgumentUtils.resolve_value(value_markup, context)
      end

      # Delegate the HTML formatting to the CitationUtils module
      # This utility is responsible for handling nil/empty values gracefully.
      CitationUtils.format_citation_html(resolved_params, site)
    end
  end
end

# Register the tag with Liquid
Liquid::Template.register_tag('citation', Jekyll::CitationTag)
