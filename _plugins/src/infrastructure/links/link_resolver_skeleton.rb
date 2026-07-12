# frozen_string_literal: true

require_relative 'link_resolver_support'

module Jekyll
  module Infrastructure
    module Links
      # Template-method skeleton for simple link resolvers (authors, series)
      # on top of LinkResolverSupport.
      #
      # The shared flow, run by `resolve_link_data`:
      # no-site guard -> normalize input -> empty-input log + result ->
      # cache lookup (with not-found log) -> display-text precedence
      # (override > canonical > input) -> frozen result hash. `resolve`
      # renders that hash as HTML via `render_html_from_data`.
      #
      # Skeleton-owned per-resolve state (@log_output, @override, @link,
      # @input) is reset at the start of every `resolve_link_data` call.
      # Subclass per-resolve state (e.g. @possessive) is NOT reset here:
      # it must be assigned unconditionally in `resolve_data` before
      # delegating, or a reused instance leaks the previous resolve's value.
      #
      # Subclasses keep their public `resolve_data` signature and call
      # `resolve_link_data(input, override, link:)` after storing any
      # tag-specific state.
      #
      # Configuration is declared with class-level attributes, mirroring
      # LinkTagBase:
      #
      #   class SeriesLinkResolver
      #     include Jekyll::Infrastructure::Links::LinkResolverSkeleton
      #
      #     self.cache_section = 'series'
      #     self.tag_type = 'RENDER_SERIES_LINK'
      #     ...
      #   end
      #
      # Required method hook:
      # - wrap_element(text)  -> the escaped inner HTML element (a <span>)
      #
      # Optional method hooks:
      # - blank_extra_fields  -> extra result fields for no-site/empty results
      # - found_extra_fields  -> extra result fields for found/not-found results
      # - determine_display_text(entry, norm_input) -> display-text precedence
      # - link_content(data)  -> inner HTML placed inside the link
      # - no_site_html(data)  -> HTML for the no-site fallback
      module LinkResolverSkeleton
        include LinkResolverSupport

        # Declarative per-class configuration.
        module ClassMethods
          # Link-cache section name ('authors').
          attr_accessor :cache_section
          # Logger tag ('RENDER_AUTHOR_LINK').
          attr_accessor :tag_type
          # Noun for the not-found log ('author').
          attr_accessor :entity_name
          # Status symbol for empty input (:empty_name).
          attr_accessor :empty_input_status
          # Log reason for empty input.
          attr_accessor :empty_input_reason
          # Log identifier key for empty input (:NameInput).
          attr_accessor :empty_input_key
          # Log identifier key for cache misses (:Name).
          attr_accessor :not_found_key
        end

        def self.included(base)
          base.extend(ClassMethods)
        end

        def resolve(...)
          render_html_from_data(resolve_data(...))
        end

        private

        # --- Shared resolve_data flow ---

        def resolve_link_data(input_raw, override_raw, link:)
          reset_resolve_state(link)
          return blank_result(:no_site, display_text: input_raw.to_s) unless @site

          @input = input_raw.to_s
          @override = override_raw.to_s.strip if override_raw && !override_raw.to_s.empty?

          norm_input = Text.normalize_title(@input)
          return empty_input_result(input_raw) if norm_input.empty?

          entry = find_entry(norm_input)
          build_result(entry, determine_display_text(entry, norm_input))
        end

        def reset_resolve_state(link)
          @log_output = ''
          @link = link
          @input = nil
          @override = nil
        end

        def empty_input_result(input_raw)
          @log_output = log_failure(
            tag_type: self.class.tag_type,
            reason: self.class.empty_input_reason,
            identifiers: { self.class.empty_input_key => input_raw || 'nil' },
            level: :warn,
          )
          blank_result(self.class.empty_input_status)
        end

        def find_entry(norm_input)
          entry = find_in_cache(self.class.cache_section, norm_input)
          unless entry
            @log_output = log_failure(
              tag_type: self.class.tag_type,
              reason: "Could not find #{self.class.entity_name} page in cache.",
              identifiers: { self.class.not_found_key => @input.strip },
              level: :info,
            )
          end
          entry
        end

        def determine_display_text(entry, _norm_input)
          return @override if @override

          entry ? entry['title'] : @input.strip
        end

        def blank_result(status, display_text: nil)
          { status: status, url: nil, display_text: display_text, **blank_extra_fields }.freeze
        end

        def build_result(entry, display_text)
          {
            status: entry ? :found : :not_found,
            url: entry && @link ? entry['url'] : nil,
            display_text: display_text,
            **found_extra_fields,
          }.freeze
        end

        def blank_extra_fields
          {}
        end

        def found_extra_fields
          {}
        end

        # --- Shared HTML rendering ---

        def render_html_from_data(data)
          case data[:status]
          when :no_site
            no_site_html(data)
          when self.class.empty_input_status
            @log_output
          when :found, :not_found
            generate_html(data)
          else
            raise Jekyll::Errors::FatalException,
                  "#{self.class.name}#render_html_from_data: unrecognized status #{data[:status].inspect}"
          end
        end

        def generate_html(data)
          content = link_content(data)
          html = @link ? wrap_with_link(content, data[:url]) : content
          @log_output + html
        end

        def link_content(data)
          wrap_element(data[:display_text])
        end

        def no_site_html(data)
          wrap_element(data[:display_text].to_s)
        end
      end
    end
  end
end
