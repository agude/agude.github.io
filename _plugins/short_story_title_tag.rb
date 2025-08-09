# _plugins/short_story_title_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi' # For HTML escaping
require_relative 'utils/tag_argument_utils'
require_relative 'utils/typography_utils'

module Jekyll
  # Liquid Tag to format a short story title.
  #
  # This tag's primary purpose is to provide a consistent, machine-readable
  # format for short story titles within markdown headings, which the
  # LinkCacheGenerator can then easily parse.
  #
  # It takes a single string argument (the title) and wraps it in a
  # <cite> tag with a specific class. It also applies standard
  # typographic processing to the title.
  #
  # Usage: {% short_story_title "The Story's Name" %}
  #
  class ShortStoryTitleTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup.strip

      # This tag expects a single argument, which can be a quoted string or a variable.
      # We will use the existing utility to resolve it during the render phase.
      if @raw_markup.empty?
        raise Liquid::SyntaxError, "Syntax Error in 'short_story_title': A title (string literal or variable) is required."
      end
    end

    def render(context)
      # Resolve the title using the utility, which handles both "literals" and variables.
      story_title = TagArgumentUtils.resolve_value(@raw_markup, context)

      # Return empty if the title resolves to nil or an empty string.
      return "" if story_title.nil? || story_title.to_s.strip.empty?

      # Use the existing typography utility to apply smart quotes, etc.
      # This ensures display consistency with book titles.
      prepared_title = TypographyUtils.prepare_display_title(story_title)

      # Output the consistently formatted HTML.
      "<cite class=\"short-story-title\">#{prepared_title}</cite>"
    end
  end
end

Liquid::Template.register_tag('short_story_title', Jekyll::ShortStoryTitleTag)
