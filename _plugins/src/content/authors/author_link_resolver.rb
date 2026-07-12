# frozen_string_literal: true

require_relative '../../infrastructure/links/link_resolver_skeleton'

module Jekyll
  module Authors
    # Helper class to handle author link resolution logic.
    class AuthorLinkResolver
      include Jekyll::Infrastructure::Links::LinkResolverSkeleton

      self.cache_section = 'authors'
      self.tag_type = 'RENDER_AUTHOR_LINK'
      self.entity_name = 'author'
      self.empty_input_status = :empty_name
      self.empty_input_reason = 'Input author name resolved to empty after normalization.'
      self.empty_input_key = :NameInput
      self.not_found_key = :Name

      # @possessive is per-resolve state, so it must be assigned
      # unconditionally before delegating (see LinkResolverSkeleton).
      def resolve_data(name_raw, override, possessive, link: true)
        @possessive = possessive
        resolve_link_data(name_raw, override, link: link)
      end

      private

      # --- LinkResolverSkeleton hooks ---

      def blank_extra_fields
        { possessive: nil }
      end

      def found_extra_fields
        { possessive: @possessive ? true : false }
      end

      # Pen-name aliases resolve to the canonical page but keep the input
      # text as written; only a normalization-equal match displays the
      # canonical title.
      def determine_display_text(entry, norm_input)
        return @override if @override
        return @input.strip unless entry

        canonical = entry['title']
        norm_input == Text.normalize_title(canonical) ? canonical : @input.strip
      end

      def link_content(data)
        suffix = data[:possessive] ? '’s' : ''
        "#{wrap_element(data[:display_text])}#{suffix}"
      end

      def no_site_html(data)
        CGI.escapeHTML(data[:display_text])
      end

      def wrap_element(display_text)
        "<span class=\"author-name\">#{CGI.escapeHTML(display_text)}</span>"
      end
    end
  end
end
