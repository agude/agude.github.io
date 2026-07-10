# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative 'text_processing_utils'

module Jekyll
  module Infrastructure
    # A filter to remove hidden book-link hover-preview markup (see
    # BookPreviewRenderer) from rendered HTML before it is reused as
    # plain/feed text (e.g. feed.xml), so the hidden preview content
    # never leaks into readers as visible inline text.
    # Usage: {{ post.content | strip_link_previews }}
    module StripLinkPreviewsFilter
      def strip_link_previews(input)
        Jekyll::Infrastructure::TextProcessingUtils.strip_link_previews(input.to_s)
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::Infrastructure::StripLinkPreviewsFilter)
