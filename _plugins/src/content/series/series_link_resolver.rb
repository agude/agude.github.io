# frozen_string_literal: true

require_relative '../../infrastructure/links/link_resolver_skeleton'

module Jekyll
  module Series
    # Helper class to handle series link resolution logic.
    class SeriesLinkResolver
      include Jekyll::Infrastructure::Links::LinkResolverSkeleton

      CACHE_SECTION = 'series'
      TAG_TYPE = 'RENDER_SERIES_LINK'
      ENTITY_NAME = 'series'
      EMPTY_INPUT_STATUS = :empty_title
      EMPTY_INPUT_REASON = 'Input title resolved to empty after normalization.'
      EMPTY_INPUT_KEY = :TitleInput
      NOT_FOUND_KEY = :Series
      SPAN_CLASS = 'book-series'
    end
  end
end
