# frozen_string_literal: true

# _plugins/short_story_title_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative '../../../infrastructure/tag_argument_utils'
require_relative '../short_story_title_util'

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

      parse_arguments(markup)
    end

    def render(context)
      story_title = TagArgumentUtils.resolve_value(@title_markup, context)

      ShortStoryTitleUtil.render_title(
        context: context,
        title: story_title,
        no_id: @no_id_flag
      )
    end

    private

    def parse_arguments(markup)
      scanner = StringScanner.new(markup.strip)
      parse_title(scanner)
      parse_no_id_flag(scanner)
      validate_title
    end

    def parse_title(scanner)
      if scanner.scan(QuotedFragment) || scanner.scan(/\S+/)
        @title_markup = scanner.matched
      else
        raise Liquid::SyntaxError,
              "Syntax Error in 'short_story_title': " \
              "Could not find title in '#{@raw_markup}'"
      end
    end

    def parse_no_id_flag(scanner)
      scanner.skip(/\s*/)
      return if scanner.eos?

      if scanner.scan(/no_id(?!\S)/)
        @no_id_flag = true
      else
        unknown_arg = scanner.scan(/\S+/)
        raise Liquid::SyntaxError,
              "Syntax Error in 'short_story_title': " \
              "Unknown argument '#{unknown_arg}' in '#{@raw_markup}'"
      end
    end

    def validate_title
      return if @title_markup && !@title_markup.strip.empty?

      raise Liquid::SyntaxError,
            "Syntax Error in 'short_story_title': " \
            "Title value is missing or empty in '#{@raw_markup}'"
    end
  end
end

Liquid::Template.register_tag('short_story_title', Jekyll::ShortStoryTitleTag)
