# frozen_string_literal: true

# _plugins/display_category_posts_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative '../post_list_utils'
require_relative '../../../infrastructure/tag_argument_utils'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../category/renderer'
require_relative '../../markdown_output/markdown_card_utils'

# Displays article cards for posts in a specific category/topic.
#
# Supports optionally excluding the current page from the results.
#
# Usage in Liquid templates:
#   {% display_category_posts topic="data-science" %}
module Jekyll
  #   {% display_category_posts topic="data-science" exclude_current_page=true %}
  module Posts
    module Tags
      # Liquid tag for displaying article cards for posts in a specific category.
      # Supports optionally excluding the current page from results.
      class DisplayCategoryPostsTag < Liquid::Tag
        # Aliases for readability
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        Logger = Jekyll::Infrastructure::PluginLoggerUtils
        ListUtils = Jekyll::Posts::PostListUtils
        Renderer = Jekyll::Posts::Category::Renderer
        private_constant :TagArgs, :Logger, :ListUtils, :Renderer

        SYNTAX_NAMED_ARG = /([\w-]+)\s*=\s*(#{Liquid::QuotedFragment}|\S+)/o
        ALLOWED_KEYS = %w[topic exclude_current_page].freeze
        REQUIRED_KEYS = ['topic'].freeze

        def initialize(tag_name, markup, tokens)
          super
          @tag_name = tag_name
          @raw_markup = markup.strip
          @attributes_markup = {}

          parse_attributes
          validate_required_keys
        end

        MdCards = Jekyll::MarkdownOutput::MarkdownCardUtils
        private_constant :MdCards

        def render(context)
          topic_name, error_log = resolve_topic(context)
          return error_log if error_log

          url_to_exclude = resolve_exclude_url(context)

          result = ListUtils.get_posts_by_category(
            site: context.registers[:site],
            category_name: topic_name,
            context: context,
            exclude_url: url_to_exclude,
          )

          if context.registers[:render_mode] == :markdown
            render_markdown(result)
          else
            renderer = Renderer.new(context, result[:posts])
            (result[:log_messages] || '') + renderer.render
          end
        end

        private

        def render_markdown(result)
          posts = result[:posts] || []
          return '' if posts.empty?

          posts.map { |p| MdCards.render_article_card_md({ title: p.data['title'], url: p.url }) }.join("\n")
        end

        def parse_attributes
          scanner = StringScanner.new(@raw_markup)

          loop do
            scanner.skip(/\s*/)
            break if scanner.eos?

            parse_single_attribute(scanner)
          end
        end

        def parse_single_attribute(scanner)
          raise Liquid::SyntaxError, syntax_error_message(scanner) unless scanner.scan(SYNTAX_NAMED_ARG)

          key = scanner[1].to_s.strip
          value = scanner[2].to_s.strip

          validate_key(key)
          @attributes_markup[key] = value
        end

        def syntax_error_message(scanner)
          token = scanner.rest.strip.split.first || ''
          "Syntax Error in '#{@tag_name}': Expected named arguments (e.g., key='value'). " \
            "Found unexpected token near '#{token}' in '#{@raw_markup}'"
        end

        def validate_key(key)
          unless ALLOWED_KEYS.include?(key)
            raise Liquid::SyntaxError, "Syntax Error in '#{@tag_name}': Unknown argument '#{key}' in '#{@raw_markup}'"
          end

          return unless @attributes_markup.key?(key)

          raise Liquid::SyntaxError, "Syntax Error in '#{@tag_name}': Duplicate argument '#{key}' in '#{@raw_markup}'"
        end

        def validate_required_keys
          REQUIRED_KEYS.each do |req_key|
            next if @attributes_markup.key?(req_key)

            raise Liquid::SyntaxError,
                  "Syntax Error in '#{@tag_name}': Required argument '#{req_key}' is missing in '#{@raw_markup}'"
          end
        end

        def resolve_topic(context)
          input = TagArgs.resolve_value(@attributes_markup['topic'], context)
          name = input.to_s.strip

          return [name, nil] unless name.empty?

          log = log_empty_topic_error(context)
          [nil, log]
        end

        def log_empty_topic_error(context)
          Logger.log_liquid_failure(
            context: context,
            tag_type: 'DISPLAY_CATEGORY_POSTS',
            reason: "Argument 'topic' resolved to an empty string.",
            identifiers: { topic_markup: @attributes_markup['topic'] },
            level: :error,
          )
        end

        def resolve_exclude_url(context)
          return nil unless @attributes_markup.key?('exclude_current_page')

          val = TagArgs.resolve_value(
            @attributes_markup['exclude_current_page'],
            context,
          )
          exclude = val == true || val.to_s.casecmp('true').zero?

          page = context.registers[:page]
          exclude && page ? page['url'] : nil
        end
      end
    end
  end
end

Liquid::Template.register_tag('display_category_posts', Jekyll::Posts::Tags::DisplayCategoryPostsTag)
