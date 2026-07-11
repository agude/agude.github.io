# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../short_story_resolver'
require_relative '../../../infrastructure/links/link_tag_base'

module Jekyll
  module ShortStories
    module Tags
      # Liquid tag for creating links to short stories.
      # Handles disambiguation for stories that appear in multiple books.
      #
      # Usage: {% short_story_link "Story Title" %}
      #        {% short_story_link "Duplicate Story" from_book="Anthology Name" %}
      class ShortStoryLinkTag < Jekyll::Infrastructure::Links::LinkTagBase
        self.subject = 'story title'
        self.resolver_class = Jekyll::ShortStories::ShortStoryResolver
        self.option_spec = { from_book: :value }

        private

        def resolver_arguments(context)
          [[subject_value(context), option_value(:from_book, context)], {}]
        end

        def markdown_italic?(_data)
          true
        end
      end
    end
  end
end

Liquid::Template.register_tag('short_story_link', Jekyll::ShortStories::Tags::ShortStoryLinkTag)
