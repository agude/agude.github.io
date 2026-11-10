# frozen_string_literal: true

require 'liquid'

module Jekyll
  module Infrastructure
    # Accelerates the compress layout's whitespace-only configuration.
    # Returning nil delegates advanced options to the original Liquid layout.
    module HtmlCompressionFilter
      def compress_html_whitespace(input, settings, environment)
        return nil unless whitespace_only_compression?(settings)

        ignored = settings.dig('ignore', 'envs')
        return input.to_s if ignored == 'all' || ignored&.include?(environment)

        # Match the original layout's literal splits, including its handling
        # of preformatted text and malformed or unmatched pre tags.
        input.to_s.split('<pre').map do |before|
          sections = before.split('</pre>')
          has_closing_tag = before.include?('</pre>')
          preserved = has_closing_tag ? "<pre#{sections.first}</pre>" : ''
          next preserved if has_closing_tag && sections.size == 1

          preserved + sections.last.to_s.split.join(' ')
        end.join
      end

      private

      def whitespace_only_compression?(settings)
        settings.is_a?(Hash) && !settings['blanklines'] && !settings['profile'] &&
          %w[endings startings comments clippings].all? { |key| settings[key] == [] }
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::Infrastructure::HtmlCompressionFilter)
