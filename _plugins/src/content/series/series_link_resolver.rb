# frozen_string_literal: true

require_relative '../../infrastructure/links/link_resolver_skeleton'

module Jekyll
  module Series
    # Helper class to handle series link resolution logic.
    class SeriesLinkResolver
      include Jekyll::Infrastructure::Links::LinkResolverSkeleton

      self.cache_section = 'series'
      self.tag_type = 'RENDER_SERIES_LINK'
      self.entity_name = 'series'
      self.empty_input_status = :empty_title
      self.empty_input_reason = 'Input title resolved to empty after normalization.'
      self.empty_input_key = :TitleInput
      self.not_found_key = :Series

      def resolve_data(title_raw, override_raw, link: true)
        resolve_link_data(title_raw, override_raw, link: link)
      end

      private

      # --- LinkResolverSkeleton hooks ---

      def wrap_element(display_text)
        "<span class=\"book-series\">#{CGI.escapeHTML(display_text)}</span>"
      end
    end
  end
end
