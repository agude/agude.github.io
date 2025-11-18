# frozen_string_literal: true
# _plugins/short_story_title_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require 'strscan'
require_relative 'utils/tag_argument_utils'
require_relative 'utils/typography_utils'
require_relative 'utils/text_processing_utils'

module Jekyll
  # Liquid Tag to format a short story title and optionally suppress the Kramdown anchor ID.
  #
  # Takes a title string and an optional `no_id` flag.
  # - Default: Outputs a formatted <cite> tag and a Kramdown ID block.
  # - With `no_id`: Outputs only the <cite> tag.
  #
  # Usage:
  #   ### {% short_story_title "The Story's Name" %}
  #   <p>A simple mention: {% short_story_title "Another Story" no_id %}</p>
  #
  class ShortStoryTitleTag < Liquid::Tag
    QuotedFragment = Liquid::QuotedFragment

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup
      @title_markup = nil
      @no_id_flag = false

      # --- Use StringScanner for flexible argument parsing ---
      scanner = StringScanner.new(markup.strip)

      # 1. Extract the Title (first argument, must be quoted or a variable)
      if scanner.scan(QuotedFragment)
        @title_markup = scanner.matched
      elsif scanner.scan(/\S+/) # Potential variable
        @title_markup = scanner.matched
      else
        raise Liquid::SyntaxError, "Syntax Error in 'short_story_title': Could not find title in '#{@raw_markup}'"
      end

      # 2. Scan for the optional `no_id` flag
      scanner.skip(/\s*/)
      unless scanner.eos?
        if scanner.scan(/no_id(?!\S)/) # Ensure 'no_id' is a whole word
          @no_id_flag = true
        else
          unknown_arg = scanner.scan(/\S+/)
          raise Liquid::SyntaxError,
                "Syntax Error in 'short_story_title': Unknown argument '#{unknown_arg}' in '#{@raw_markup}'"
        end
      end

      return if @title_markup && !@title_markup.strip.empty?

      raise Liquid::SyntaxError,
            "Syntax Error in 'short_story_title': Title value is missing or empty in '#{@raw_markup}'"
    end

    def render(context)
      # Initialize a counter hash in the context if it doesn't exist
      context.registers[:story_title_counts] ||= Hash.new(0)

      story_title = TagArgumentUtils.resolve_value(@title_markup, context)
      return '' if story_title.nil? || story_title.to_s.strip.empty?

      prepared_title = TypographyUtils.prepare_display_title(story_title)
      cite_element = "<cite class=\"short-story-title\">#{prepared_title}</cite>"

      if @no_id_flag
        cite_element
      else
        base_slug = TextProcessingUtils.slugify(story_title)

        # Increment the count for this specific slug
        context.registers[:story_title_counts][base_slug] += 1
        count = context.registers[:story_title_counts][base_slug]

        final_slug = base_slug
        # If this is the second or later time we've seen this slug, append the count
        final_slug = "#{base_slug}-#{count}" if count > 1

        kramdown_id = "{##{final_slug}}"
        "#{cite_element} #{kramdown_id}"
      end
    end
  end
end

Liquid::Template.register_tag('short_story_title', Jekyll::ShortStoryTitleTag)
