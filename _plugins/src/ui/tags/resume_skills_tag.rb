# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../../infrastructure/tag_argument_utils'
require_relative '../../infrastructure/text_processing_utils'

module Jekyll
  module UI
    module Tags
      # Liquid tag for rendering a resume skills section.
      #
      # Usage:
      #   {% resume_skills languages="Python, Scala, SQL" tools="NumPy, Spark, git" %}
      #
      # Both parameters are required. An unknown, repeated, or missing key
      # raises Liquid::SyntaxError at parse time. Values may contain HTML
      # (stripped in markdown mode, rendered via markdownify in HTML mode).
      class ResumeSkillsTag < Liquid::Tag
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        private_constant :TagArgs

        KEYS = %w[languages tools].freeze

        def initialize(tag_name, markup, tokens)
          super
          @attributes_markup = TagArgs.parse_named_arguments(
            markup.strip, tag_name: 'resume_skills', allowed: KEYS, required: KEYS,
          ).transform_keys(&:to_sym)
        end

        def render(context)
          params = resolve_params(context)

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

        def render_markdown(params)
          languages = strip_html(params[:languages].to_s)
          tools = strip_html(params[:tools].to_s)
          "- **Languages**: #{languages}\n- **Tools**: #{tools}"
        end

        def render_html(params, context)
          site = context.registers[:site]
          lines = []
          lines << '<div class="resume-skills-grid">'
          lines << '    <div class="resume-languages-title"><strong>Languages</strong></div>'
          lines << "    <div class=\"resume-languages\">#{markdownify(params[:languages], site)}</div>"
          lines << '    <div class="resume-tools-title"><strong>Tools</strong></div>'
          lines << "    <div class=\"resume-tools\">#{markdownify(params[:tools], site)}</div>"
          lines << '</div>'
          lines.join("\n")
        end

        def markdownify(text, site)
          return text.to_s unless site

          converter = site.find_converter_instance(Jekyll::Converters::Markdown)
          return text.to_s unless converter

          converter.convert(text.to_s).strip
        end

        def strip_html(text)
          Jekyll::Infrastructure::TextProcessingUtils.strip_tags(text)
        end
      end
    end
  end
end

Liquid::Template.register_tag('resume_skills', Jekyll::UI::Tags::ResumeSkillsTag)
