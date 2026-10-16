# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../../infrastructure/tag_argument_utils'

module Jekyll
  module UI
    module Tags
      # Liquid tag for rendering a resume experience or education entry.
      #
      # Usage:
      #   {% resume_experience company="Cash App" location="Remote"
      #      position="Staff ML Engineer" dates="2020--2023"
      #      position_2="Senior ML Engineer" dates_2="2023--Present" %}
      #
      # Required: company, location, position
      # Optional: dates, position_2, dates_2
      # An unknown, repeated, or missing key raises Liquid::SyntaxError at
      # parse time. A required value that resolves empty raises at render.
      class ResumeExperienceTag < Liquid::Tag
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        private_constant :TagArgs

        ALLOWED_KEYS = %w[company location position dates position_2 dates_2].freeze
        REQUIRED_KEYS = %w[company location position].freeze

        def initialize(tag_name, markup, tokens)
          super
          @raw_markup = markup.strip
          @attributes_markup = TagArgs.parse_named_arguments(
            @raw_markup, tag_name: 'resume_experience', allowed: ALLOWED_KEYS, required: REQUIRED_KEYS,
          ).transform_keys(&:to_sym)
        end

        def render(context)
          params = resolve_params(context)
          validate_required!(params)

          if context.registers[:render_mode] == :markdown
            render_markdown(params)
          else
            render_html(params, context)
          end
        end

        private

        def resolve_params(context)
          result = {}
          @attributes_markup.each do |key, value_markup|
            result[key] = TagArgs.resolve_value(value_markup, context)
          end
          result
        end

        # The parser guarantees each required key is present. This catches
        # a value that resolves empty, such as an unset variable.
        def validate_required!(params)
          REQUIRED_KEYS.each do |name|
            key = name.to_sym
            next if params[key] && !params[key].to_s.empty?

            raise Liquid::SyntaxError,
                  "Syntax Error in 'resume_experience': Missing required argument '#{key}' in '#{@raw_markup}'"
          end
        end

        def render_markdown(params)
          lines = []
          lines << "### #{params[:company]}"
          parts = ["**#{params[:position]}**"]
          parts << "_#{params[:dates]}_" if params[:dates]
          parts << params[:location]
          lines << parts.join(' | ')
          if params[:position_2]
            row2 = ["**#{params[:position_2]}**"]
            row2 << "_#{params[:dates_2]}_" if params[:dates_2]
            lines << row2.join(' | ')
          end
          lines.join("\n")
        end

        def render_html(params, context)
          site = context.registers[:site]
          lines = []
          lines << '<div class="resume-header-grid">'
          lines << "    <div class=\"resume-company\"><h3>#{params[:company]}</h3></div>"
          lines << "    <div class=\"resume-location\">#{params[:location]}</div>"
          lines << "    <div class=\"resume-position\">#{params[:position]}</div>"
          lines << "    <div class=\"resume-dates\">#{markdownify(params[:dates], site)}</div>"
          if params[:position_2]
            lines << "      <div class=\"resume-position\">#{params[:position_2]}</div>"
            lines << "      <div class=\"resume-dates\">#{markdownify(params[:dates_2], site)}</div>"
          end
          lines << '</div>'
          lines.join("\n")
        end

        def markdownify(text, site)
          return text.to_s unless site

          converter = site.find_converter_instance(Jekyll::Converters::Markdown)
          return text.to_s unless converter

          converter.convert(text.to_s).strip
        end
      end
    end
  end
end

Liquid::Template.register_tag('resume_experience', Jekyll::UI::Tags::ResumeExperienceTag)
