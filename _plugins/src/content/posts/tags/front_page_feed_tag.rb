# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../feed_utils'
require_relative '../../../infrastructure/tag_argument_utils'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../feed/renderer'
require_relative '../../../ui/cards/markdown_card_utils'

# Renders a feed combining recent posts and book reviews.
#
# Displays a card grid of the most recent content from both the posts
# and books collections, sorted by date.
#
# Usage in Liquid templates:
#   {% front_page_feed %}
module Jekyll
  #   {% front_page_feed limit=10 %}
  module Posts
    module Tags
      # Liquid tag for rendering a feed combining recent posts and book reviews.
      # Displays the most recent content from both collections, sorted by date.
      class FrontPageFeedTag < Liquid::Tag
        # Aliases for readability
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        Logger = Jekyll::Infrastructure::PluginLoggerUtils
        FeedUtils = Jekyll::Posts::FeedUtils
        Renderer = Jekyll::Posts::Feed::Renderer
        private_constant :TagArgs, :Logger, :FeedUtils, :Renderer

        def initialize(tag_name, markup, tokens)
          super
          @tag_name = tag_name
          @raw_markup = markup.strip
          @limit_markup = nil

          parse_arguments
        end

        MdCards = Jekyll::UI::Cards::MarkdownCardUtils
        private_constant :MdCards

        def render(context)
          limit = resolve_limit(context)
          feed_items = FeedUtils.get_combined_feed_items(site: context.registers[:site], limit: limit)

          if context.registers[:render_mode] == :markdown
            render_markdown(feed_items)
          else
            log_output = log_empty_feed(context, limit) if feed_items.empty?
            renderer = Renderer.new(context, feed_items)
            (log_output || '') + renderer.render
          end
        end

        private

        def render_markdown(items)
          return '' if items.empty?

          items.map do |item|
            card = {
              title: item.data['title'],
              url: item.url,
              description: MdCards.extract_plain_description(item.data, type: :article),
            }
            MdCards.render_article_card_md(card)
          end.join("\n")
        end

        def parse_arguments
          arguments = TagArgs.parse_named_arguments(@raw_markup, tag_name: @tag_name, allowed: ['limit'])
          @limit_markup = arguments['limit']
        end

        def resolve_limit(context)
          return nil unless @limit_markup

          resolved = TagArgs.resolve_value(@limit_markup, context)
          begin
            val = Integer(resolved.to_s)
            val.positive? ? val : nil
          rescue ArgumentError, TypeError
            nil
          end
        end

        def log_empty_feed(context, limit)
          Logger.log_liquid_failure(
            context: context,
            tag_type: 'FRONT_PAGE_FEED',
            reason: 'No items found for the front page feed.',
            identifiers: { limit: limit },
            level: :info,
          )
        end
      end
    end
  end
end

Liquid::Template.register_tag('front_page_feed', Jekyll::Posts::Tags::FrontPageFeedTag)
