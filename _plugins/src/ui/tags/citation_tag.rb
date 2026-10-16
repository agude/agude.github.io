# frozen_string_literal: true

#   -----------------------------------------------------------------------------
#   BLANK CITATION TAG TEMPLATE
#   -----------------------------------------------------------------------------
#   Fill in the appropriate values for each parameter.
#   Omit any parameters that are not applicable to the citation.
#   The 'url' parameter links the 'work_title'. Without a 'work_title', 'url' is ignored.
#   Styling of 'work_title' (quotes vs. italics) is inferred based on the
#   presence or absence of 'container_title'.
#
# {% citation
#   author_first=""       First name(s) or initials of the author(s). For multiple authors, list them as they should
#                         appear, e.g., "John A. and Jane B." or "J. Doe, F. Bar".
#   author_last=""        Last name of the primary author, or "Group Name et al." or "Collaboration Name".
#   author_handle=""      Optional: A social media handle or similar identifier, e.g., "@username". Often displayed in
#                         parentheses after the name.
#   work_title=""         The title of the specific work being cited (e.g., article title, chapter title, book title if
#                         cited as a whole, webpage title). This is the primary cited entity.
#   container_title=""    The title of the larger publication or source that contains the work_title (e.g., journal
#                         name, book title if work_title is a chapter, website name).
#   editor=""             Name(s) of the editor(s), if applicable (e.g., for an edited collection).
#   edition=""            Edition information, if not the first (e.g., "2nd", "Revised"). The "ed" part is handled by
#                         the citation utility.
#   volume=""             Volume number (e.g., for a journal or multi-volume book).
#   number=""             Issue number (e.g., for a journal). Sometimes referred to as "issue".
#   publisher=""          Name of the publisher (e.g., "Academic Press", "University of California Press").
#   date=""               Publication date. Can be a year (YYYY), full date (Month DD, YYYY or YYYY-MM-DD), or
#                         season/year (Spring YYYY).
#   first_page=""         Starting page number or article identifier (e.g., "101", "A27").
#   last_page=""          Ending page number, if it's a range (e.g., "115").
#   page=""               A single page number if not a range and first_page/last_page are not suitable (e.g., "5").
#                         The "p." prefix is added by the citation utility.
#   doi=""                Digital Object Identifier (e.g., "10.1234/xyz.567"). Can also be used for arXiv IDs like
#                         "arXiv:2301.00001".
#   url=""                The primary URL for the citation. It links the work_title, and is ignored when work_title
#                         is absent.
#   access_date=""        Date when an online resource was last accessed or verified (e.g., "January 15, 2023").
# %}

require 'jekyll'
require 'liquid'
require_relative '../citations/citation_utils'
require_relative '../../infrastructure/tag_argument_utils'

module Jekyll
  module UI
    module Tags
      # Liquid tag for generating formatted citations from bibliographic data.
      # Accepts the named parameters in CitationUtils::PARAMETER_NAMES, all
      # optional. Each value is a quoted literal or a Liquid variable. An
      # unknown or repeated key raises Liquid::SyntaxError at parse time.
      class CitationTag < Liquid::Tag
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        CitationUtil = Jekyll::UI::Citations::CitationUtils
        private_constant :TagArgs, :CitationUtil

        def initialize(tag_name, markup, tokens)
          super
          @attributes_markup = TagArgs.parse_named_arguments(
            markup.strip, tag_name: 'citation', allowed: CitationUtil::PARAMETER_NAMES,
          ).transform_keys(&:to_sym)
        end

        def render(context)
          site = context.registers[:site]
          resolved_params = {}
          @attributes_markup.each do |key, value_markup|
            resolved_params[key] = TagArgs.resolve_value(value_markup, context)
          end

          if context.registers[:render_mode] == :markdown
            CitationUtil.format_citation_text(resolved_params, site)
          else
            CitationUtil.format_citation_html(resolved_params, site)
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('citation', Jekyll::UI::Tags::CitationTag)
