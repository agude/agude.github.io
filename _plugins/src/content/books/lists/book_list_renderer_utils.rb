# frozen_string_literal: true

# _plugins/utils/book_list_renderer_utils.rb
require 'cgi'
require_relative '../../series/series_link_util'
require_relative '../core/book_card_utils'
require_relative '../../../infrastructure/text_processing_utils'

# Utility module for rendering HTML for lists of books.
#
# Provides methods to render book groups (standalone and series) with
# optional A-Z navigation.
module BookListRendererUtils
  # --- Public HTML Rendering Helper ---

  # Renders HTML for book groups (standalone and series).
  # @param data [Hash] Expected to have :standalone_books, :series_groups, and optionally :log_messages.
  # @param context [Liquid::Context] The Liquid context.
  # @param series_heading_level [Integer] The HTML heading level for series titles. Defaults to 2.
  # @param generate_nav [Boolean] If true, generates and prepends an A-Z jump-link navigation.
  # @return [String] The rendered HTML.
  def self.render_book_groups_html(data, context, series_heading_level: 2, generate_nav: false)
    output = (data[:log_messages] || '').dup
    standalone_books = data[:standalone_books] || []
    series_groups = data[:series_groups] || []

    return output if standalone_books.empty? && series_groups.empty?

    renderer = BookGroupsRenderer.new(standalone_books, series_groups, context, series_heading_level, generate_nav)
    output + renderer.render
  end

  # --- Private Rendering Helpers ---

  def self._render_content_buffer(standalone, series_groups, context, options)
    buffer = String.new
    buffer << _render_standalone_section(standalone, context, options) if standalone.any?

    series_groups.each do |group|
      buffer << _render_series_section(group, context, options)
    end
    buffer
  end

  def self._render_standalone_section(books, context, options)
    slug = 'standalone-books'
    options[:anchors]['#'] = slug if options[:generate_nav]
    html = String.new("<h2 class=\"book-list-headline\" id=\"#{slug}\">Standalone Books</h2>\n")
    html << "<div class=\"card-grid\">\n"
    books.each { |b| html << BookCardUtils.render(b, context) << "\n" }
    html << "</div>\n"
    html
  end

  def self._render_series_section(group, context, options)
    name = group[:name]
    slug = TextProcessingUtils.slugify(name)
    _register_series_anchor(name, slug, options) if options[:generate_nav]

    heading_level = options[:series_hl]
    link = SeriesLinkUtils.render_series_link(name, context)
    html = String.new("<h#{heading_level} class=\"series-title\" id=\"#{slug}\">#{link}</h#{heading_level}>\n")
    html << "<div class=\"card-grid\">\n"
    group[:books].each { |b| html << BookCardUtils.render(b, context) << "\n" }
    html << "</div>\n"
    html
  end

  def self._register_series_anchor(name, slug, options)
    sort_key = TextProcessingUtils.normalize_title(name, strip_articles: true).sub(/^series\s+/, '').strip
    letter = sort_key.empty? ? '#' : sort_key[0].upcase
    options[:anchors][letter] ||= slug
  end

  def self._render_alpha_nav(anchors)
    chars = ['#'] + ('A'..'Z').to_a
    links = chars.map do |char|
      if anchors.key?(char)
        "<a href=\"##{anchors[char]}\">#{CGI.escapeHTML(char)}</a>"
      else
        "<span>#{CGI.escapeHTML(char)}</span>"
      end
    end
    "<nav class=\"alpha-jump-links\">\n  #{links.join(' ')}\n</nav>\n"
  end

  # Helper class to render book groups HTML
  class BookGroupsRenderer
    def initialize(standalone_books, series_groups, context, series_heading_level, generate_nav)
      @standalone_books = standalone_books
      @series_groups = series_groups
      @context = context
      @series_hl = (1..6).include?(series_heading_level.to_i) ? series_heading_level.to_i : 2
      @generate_nav = generate_nav
      @anchors = {}
    end

    def render
      options = { series_hl: @series_hl, generate_nav: @generate_nav, anchors: @anchors }
      content = BookListRendererUtils._render_content_buffer(@standalone_books, @series_groups, @context, options)

      return content unless @generate_nav

      nav_html = BookListRendererUtils._render_alpha_nav(@anchors)
      nav_html + content
    end
  end
  private_constant :BookGroupsRenderer
end
