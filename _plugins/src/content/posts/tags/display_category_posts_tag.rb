# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../post_list_utils'
require_relative '../../../infrastructure/tag_argument_utils'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../category/renderer'
require_relative '../../../ui/cards/markdown_card_utils'
require_relative '../../../ui/tags/display_tag_renderable'

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
        include Jekyll::UI::DisplayTagRenderable

        # Aliases for readability
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        Logger = Jekyll::Infrastructure::PluginLoggerUtils
        ListUtils = Jekyll::Posts::PostListUtils
        Renderer = Jekyll::Posts::Category::Renderer
        private_constant :TagArgs, :Logger, :ListUtils, :Renderer

        ALLOWED_KEYS = %w[topic exclude_current_page].freeze
        REQUIRED_KEYS = ['topic'].freeze

        def initialize(tag_name, markup, tokens)
          super
          @tag_name = tag_name
          @raw_markup = markup.strip
          @attributes_markup = TagArgs.parse_named_arguments(
            @raw_markup, tag_name: @tag_name, allowed: ALLOWED_KEYS, required: REQUIRED_KEYS,
          )
        end

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

          render_display_tag(context, result) do |d|
            Renderer.new(context, d[:posts]).render
          end
        end

        private

        def render_markdown(result)
          posts = result[:posts] || []
          return '' if posts.empty?

          posts.map { |p| MdCards.render_article_card_md({ title: p.data['title'], url: p.url }) }.join("\n")
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
