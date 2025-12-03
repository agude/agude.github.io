# frozen_string_literal: true

# _plugins/short_story_link_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative '../short_story_link_util'
require_relative '../../../infrastructure/tag_argument_utils'

module Jekyll
  # Liquid Tag for creating a link to a short story.
  # Handles disambiguation for stories that appear in multiple books.
  #
  # Usage:
  #   {% short_story_link "Story Title" %}
  #   {% short_story_link "Duplicate Story" from_book="Anthology Name" %}
  #
  class ShortStoryLinkTag < Liquid::Tag
    QuotedFragment = Liquid::QuotedFragment

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup
      @title_markup = nil
      @from_book_markup = nil

      parse_markup(markup)
    end

    def render(context)
      # Resolve arguments from markup
      story_title = TagArgumentUtils.resolve_value(@title_markup, context)
      from_book_title = @from_book_markup ? TagArgumentUtils.resolve_value(@from_book_markup, context) : nil

      # Delegate all logic to the utility module
      ShortStoryLinkUtils.render_short_story_link(story_title, context, from_book_title)
    end

    private

    def parse_markup(markup)
      scanner = StringScanner.new(markup.strip)
      scan_title(scanner)
      scan_optional_arguments(scanner)
      validate_title
    end

    def scan_title(scanner)
      # 1. Extract the Title (first argument)
      unless scanner.scan(QuotedFragment) || scanner.scan(/\S+/)
        raise Liquid::SyntaxError, "Syntax Error in 'short_story_link': Could not find story title in '#{@raw_markup}'"
      end

      @title_markup = scanner.matched
    end

    def scan_optional_arguments(scanner)
      # 2. Scan for optional `from_book` argument
      scanner.skip(/\s*/)
      return if scanner.eos?

      if scanner.scan(/from_book\s*=\s*(#{QuotedFragment})/)
        @from_book_markup = scanner[1]
      else
        unknown_arg = scanner.scan(/\S+/)
        raise Liquid::SyntaxError,
              "Syntax Error in 'short_story_link': Unknown argument '#{unknown_arg}' in '#{@raw_markup}'"
      end
    end

    def validate_title
      return if @title_markup && !@title_markup.strip.empty?

      raise Liquid::SyntaxError,
            "Syntax Error in 'short_story_link': Title value is missing or empty in '#{@raw_markup}'"
    end
  end
end

Liquid::Template.register_tag('short_story_link', Jekyll::ShortStoryLinkTag)
