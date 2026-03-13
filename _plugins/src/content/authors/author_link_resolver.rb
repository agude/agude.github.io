# frozen_string_literal: true

# _plugins/src/content/authors/author_link_resolver.rb
require_relative '../../infrastructure/links/link_resolver_support'

module Jekyll
  module Authors
    # Helper class to handle author link resolution logic
    class AuthorLinkResolver
      include Jekyll::Infrastructure::Links::LinkResolverSupport

      def resolve(name_raw, override, possessive, link: true)
        data = resolve_data(name_raw, override, possessive, link: link)
        render_html_from_data(data)
      end

      def resolve_data(name_raw, override, possessive, link: true)
        @link = link
        return { status: :no_site, url: nil, display_text: name_raw.to_s, possessive: nil }.freeze unless @site

        @name_input = name_raw.to_s
        @override = override.to_s.strip if override && !override.to_s.empty?
        @possessive = possessive

        norm_name = Text.normalize_title(@name_input)
        if norm_name.empty?
          @log_output = log_failure(
            tag_type: 'RENDER_AUTHOR_LINK',
            reason: 'Input author name resolved to empty after normalization.',
            identifiers: { NameInput: name_raw || 'nil' },
            level: :warn,
          )
          return { status: :empty_name, url: nil, display_text: nil, possessive: nil }.freeze
        end

        author_data = find_author(norm_name)
        display_text = determine_display_text(author_data, norm_name)
        build_result(author_data, display_text)
      end

      private

      def render_html_from_data(data)
        case data[:status]
        when :no_site
          CGI.escapeHTML(data[:display_text])
        when :empty_name
          @log_output
        when :found, :not_found
          generate_html(data)
        end
      end

      def build_result(author_data, display_text)
        {
          status: author_data ? :found : :not_found,
          url: author_data && @link ? author_data['url'] : nil,
          display_text: display_text,
          possessive: @possessive ? true : false,
        }.freeze
      end

      def find_author(norm_name)
        author_data = find_in_cache('authors', norm_name)
        unless author_data
          @log_output = log_failure(
            tag_type: 'RENDER_AUTHOR_LINK',
            reason: 'Could not find author page in cache.',
            identifiers: { Name: @name_input.strip },
            level: :info,
          )
        end
        author_data
      end

      def determine_display_text(author_data, norm_name)
        return @override if @override
        return @name_input.strip unless author_data

        canonical = author_data['title']
        norm_canonical = Text.normalize_title(canonical)

        norm_name == norm_canonical ? canonical : @name_input.strip
      end

      def generate_html(data)
        span = build_author_span_element(data[:display_text])
        suffix = data[:possessive] ? "\u2019s" : ''
        content = "#{span}#{suffix}"

        html = if @link
                 wrap_with_link(content, data[:url])
               else
                 content
               end

        @log_output + html
      end

      def build_author_span_element(display_text)
        escaped_display_text = CGI.escapeHTML(display_text)
        "<span class=\"author-name\">#{escaped_display_text}</span>"
      end
    end
  end
end
