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

      parse_arguments(markup)
    end

    def render(context)
      ShortStoryTitleRenderer.new(context, @title_markup, @no_id_flag).render
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

    # Helper class to handle rendering logic
    class ShortStoryTitleRenderer
      def initialize(context, title_markup, no_id_flag)
        @context = context
        @title_markup = title_markup
        @no_id_flag = no_id_flag
      end

      def render
        initialize_title_counts
        story_title = resolve_title
        return '' if story_title.nil? || story_title.to_s.strip.empty?

        cite_element = create_cite_element(story_title)
        @no_id_flag ? cite_element : "#{cite_element} #{create_kramdown_id(story_title)}"
      end

      private

      def initialize_title_counts
        @context.registers[:story_title_counts] ||= Hash.new(0)
      end

      def resolve_title
        TagArgumentUtils.resolve_value(@title_markup, @context)
      end

      def create_cite_element(story_title)
        prepared_title = TypographyUtils.prepare_display_title(story_title)
        "<cite class=\"short-story-title\">#{prepared_title}</cite>"
      end

      def create_kramdown_id(story_title)
        base_slug = TextProcessingUtils.slugify(story_title)
        final_slug = generate_unique_slug(base_slug)
        "{##{final_slug}}"
      end

      def generate_unique_slug(base_slug)
        @context.registers[:story_title_counts][base_slug] += 1
        count = @context.registers[:story_title_counts][base_slug]
        count > 1 ? "#{base_slug}-#{count}" : base_slug
      end
    end
  end
end

Liquid::Template.register_tag('short_story_title', Jekyll::ShortStoryTitleTag)
