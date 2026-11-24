# frozen_string_literal: true

require_relative 'link_resolver_support'

module Jekyll
  module Infrastructure
    module Links
      # @pattern Authors and series resolve a single normalized cache entry.
      #   Constants supply the cache section, diagnostics, and span class.
      #   Authors specialize display text to preserve the name used by the caller.
      module LinkResolverSkeleton
        include LinkResolverSupport

        private

        def resolve_link_data(input_raw, override_raw, link:, **extra_fields)
          @log_output = ''
          input = input_raw.to_s
          empty_fields = { url: nil, display_text: nil, **extra_fields.transform_values { nil } }
          return { **empty_fields, status: :no_site, display_text: input }.freeze unless @site

          normalized = Text.normalize_title(input)
          if normalized.empty?
            log_empty_input(input_raw)
            return { **empty_fields, status: self.class::EMPTY_INPUT_STATUS }.freeze
          end

          entry = find_entry(normalized, input)
          override = override_raw.to_s.strip if override_raw && !override_raw.to_s.empty?
          {
            status: entry ? :found : :not_found,
            url: entry && link ? entry['url'] : nil,
            display_text: override || determine_display_text(entry, input, normalized),
            **extra_fields,
          }.freeze
        end

        def render_html_from_data(data)
          super(data, strict: true)
        end

        def log_empty_input(input_raw)
          @log_output = log_failure(
            tag_type: self.class::TAG_TYPE,
            reason: self.class::EMPTY_INPUT_REASON,
            identifiers: { self.class::EMPTY_INPUT_KEY => input_raw || 'nil' },
            level: :warn,
          )
        end

        def find_entry(normalized, input)
          entry = find_in_cache(self.class::CACHE_SECTION, normalized)
          return entry if entry

          @log_output = log_failure(
            tag_type: self.class::TAG_TYPE,
            reason: "Could not find #{self.class::ENTITY_NAME} page in cache.",
            identifiers: { self.class::NOT_FOUND_KEY => input.strip },
            level: :info,
          )
          nil
        end

        def determine_display_text(entry, input, _normalized)
          entry ? entry['title'] : input.strip
        end

        def link_content(data)
          suffix = data[:possessive] ? '’s' : ''
          text = CGI.escapeHTML(data[:display_text])
          ["<span class=\"#{self.class::SPAN_CLASS}\">#{text}</span>#{suffix}", nil]
        end
      end
    end
  end
end
