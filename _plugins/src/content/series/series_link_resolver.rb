# frozen_string_literal: true

# _plugins/src/content/series/series_link_resolver.rb
require_relative '../../infrastructure/links/link_resolver_support'

module Jekyll
  module Series
    # Helper class to handle series link resolution logic.
    class SeriesLinkResolver
      include Jekyll::Infrastructure::Links::LinkResolverSupport

      def resolve(title_raw, override_raw, link: true)
        data = resolve_data(title_raw, override_raw, link: link)
        render_html_from_data(data)
      end

      def resolve_data(title_raw, override_raw, link: true)
        @link = link
        return { status: :no_site, url: nil, display_text: title_raw.to_s }.freeze unless @site

        @title_input = title_raw.to_s
        @override = override_raw.to_s.strip if override_raw && !override_raw.to_s.empty?

        norm_title = Text.normalize_title(@title_input)
        if norm_title.empty?
          @log_output = log_failure(
            tag_type: 'RENDER_SERIES_LINK',
            reason: 'Input title resolved to empty after normalization.',
            identifiers: { TitleInput: title_raw || 'nil' },
            level: :warn,
          )
          return { status: :empty_title, url: nil, display_text: nil }.freeze
        end

        series_data = find_series(norm_title)
        display_text = determine_display_text(series_data)

        if series_data
          { status: :found, url: @link ? series_data['url'] : nil, display_text: display_text }.freeze
        else
          { status: :not_found, url: nil, display_text: display_text }.freeze
        end
      end

      private

      def render_html_from_data(data)
        case data[:status]
        when :no_site
          build_series_span_element(data[:display_text].to_s)
        when :empty_title
          @log_output
        when :found, :not_found
          generate_html(data)
        end
      end

      def find_series(norm_title)
        series_data = find_in_cache('series', norm_title)
        unless series_data
          @log_output = log_failure(
            tag_type: 'RENDER_SERIES_LINK',
            reason: 'Could not find series page in cache.',
            identifiers: { Series: @title_input.strip },
            level: :info,
          )
        end
        series_data
      end

      def determine_display_text(series_data)
        if @override
          @override
        elsif series_data
          series_data['title']
        else
          @title_input.strip
        end
      end

      def generate_html(data)
        span = build_series_span_element(data[:display_text])

        html = if @link
                 wrap_with_link(span, data[:url])
               else
                 span
               end
        @log_output + html
      end

      def build_series_span_element(display_text)
        escaped_display_text = CGI.escapeHTML(display_text)
        "<span class=\"book-series\">#{escaped_display_text}</span>"
      end
    end
  end
end
