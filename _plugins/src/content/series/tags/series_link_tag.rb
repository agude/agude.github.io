# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../series_link_resolver'
require_relative '../../../infrastructure/links/link_tag_base'

module Jekyll
  module Series
    module Tags
      # Liquid tag for rendering a link to a book series page.
      # Creates an HTML link if the series page exists, otherwise renders
      # plain text.
      #
      # Usage: {% series_link "The Lord of the Rings" %}
      #        {% series_link page.series link_text="the series" %}
      class SeriesLinkTag < Jekyll::Infrastructure::Links::LinkTagBase
        self.subject = 'series title'
        self.resolver_class = Jekyll::Series::SeriesLinkResolver
        self.option_spec = { link_text: :value }

        private

        def resolver_arguments(context)
          [[subject_value(context), option_value(:link_text, context)], {}]
        end

        def markdown_italic?(_data)
          true
        end
      end
    end
  end
end

Liquid::Template.register_tag('series_link', Jekyll::Series::Tags::SeriesLinkTag)
