# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../core/book_awards_formatter'

module Jekyll
  module Books
    module Tags
      # Renders book awards and favorites mentions as HTML or Markdown.
      class RenderBookAwardsTag < Liquid::Tag
        def initialize(tag_name, markup, tokens)
          super
          return if markup.strip.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
        end

        def render(context)
          if context.registers[:render_mode] == :markdown
            page = context.registers[:page]
            site = context.registers[:site]
            awards = page['awards']
            mentions = site.data.dig('link_cache', 'favorites_mentions', page['url'])
            Core::BookAwardsFormatter.new(awards, mentions).render.to_s
          else
            Renderer.new(context).render
          end
        end

        # HTML renderer — inner class (takes context only, matching established pattern)
        class Renderer
          def initialize(context)
            @site = context.registers[:site]
            @baseurl = @site.config['baseurl'] || ''
            page = context.registers[:page]
            @awards = page['awards']
            @mentions = @site.data.dig('link_cache', 'favorites_mentions', page['url'])
          end

          def render
            award_parts = format_awards
            mention_parts = format_mentions
            parts = award_parts + mention_parts
            return '' if parts.empty?

            "<div class=\"book-awards\">Awards: #{parts.join(', ')}</div>"
          end

          private

          def format_awards
            return [] unless @awards.is_a?(Array) && !@awards.empty?

            @awards.sort.map do |award|
              label = award.split.map(&:capitalize).join(' ')
              slug = Jekyll::Utils.slugify(award)
              "<a class=\"book-award\" href=\"/books/by-award/##{slug}-award\">#{label}</a>"
            end
          end

          def format_mentions
            return [] unless @mentions.is_a?(Array) && !@mentions.empty?

            @mentions.sort_by { |p| p.data['is_favorites_list'].to_s }.reverse.map do |post|
              year = post.data['is_favorites_list']
              url = "#{@baseurl}#{post.url}"
              "<a class=\"book-favorite-link\" href=\"#{url}\">#{year} Favorites</a>"
            end
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('render_book_awards', Jekyll::Books::Tags::RenderBookAwardsTag)
