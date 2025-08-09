# _plugins/short_story_link_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative 'utils/short_story_link_util'
require_relative 'utils/tag_argument_utils'

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

      scanner = StringScanner.new(markup.strip)

      # 1. Extract the Title (first argument)
      if scanner.scan(QuotedFragment)
        @title_markup = scanner.matched
      elsif scanner.scan(/\S+/)
        @title_markup = scanner.matched
      else
        raise Liquid::SyntaxError, "Syntax Error in 'short_story_link': Could not find story title in '#{@raw_markup}'"
      end

      # 2. Scan for optional `from_book` argument
      scanner.skip(/\s*/)
      unless scanner.eos?
        if scanner.scan(/from_book\s*=\s*(#{QuotedFragment})/)
            @from_book_markup = scanner[1]
        else
          unknown_arg = scanner.scan(/\S+/)
          raise Liquid::SyntaxError, "Syntax Error in 'short_story_link': Unknown argument '#{unknown_arg}' in '#{@raw_markup}'"
        end
      end

      unless @title_markup && !@title_markup.strip.empty?
        raise Liquid::SyntaxError, "Syntax Error in 'short_story_link': Title value is missing or empty in '#{@raw_markup}'"
      end
    end

    def render(context)
      # Resolve arguments from markup
      story_title = TagArgumentUtils.resolve_value(@title_markup, context)
      from_book_title = @from_book_markup ? TagArgumentUtils.resolve_value(@from_book_markup, context) : nil

      # Delegate all logic to the utility module
      ShortStoryLinkUtils.render_short_story_link(story_title, context, from_book_title)
    end
  end
end

Liquid::Template.register_tag('short_story_link', Jekyll::ShortStoryLinkTag)
