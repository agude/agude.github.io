# frozen_string_literal: true

# _plugins/display_ranked_books_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'utils/rating_utils'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/book_card_utils'
require_relative 'utils/text_processing_utils'

module Jekyll
  # Liquid Tag to validate (in non-prod) and render a list of books
  # grouped by rating, based on a monotonically sorted list of titles.
  # (e.g., page.ranked_list).
  #
  # Combines the logic previously in check_monotonic_rating and render_ranked_books.
  #
  # Validation (Non-Production Only):
  # 1. Each title in the ranked list exists in the site.books collection
  #    and has a valid integer rating.
  # 2. The rating associated with each title is less than or equal to the
  #    rating of the preceding title in the list.
  # Validation failures raise an error, halting the build.
  #
  # Rendering:
  # - Outputs books grouped by rating using H2 tags and book cards.
  # - Uses LiquidUtils helpers for stars and cards.
  #
  # Syntax: {% display_ranked_books list_variable %}
  # Example: {% display_ranked_books page.ranked_list %}
  #
  class DisplayRankedBooksTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @list_variable_markup = markup.strip
      return if @list_variable_markup && !@list_variable_markup.empty?

      raise Liquid::SyntaxError,
        "Syntax Error in 'display_ranked_books': A variable name holding the list must be provided."
    end

    def render(context)
      site = context.registers[:site]
      is_production = (site.config['environment'] || 'development') == 'production'

      ranked_list = resolve_list(context)
      return '' if ranked_list.empty?

      book_map = build_book_map(site)
      state = initialize_state

      ranked_list.each_with_index do |title_raw, index|
        process_item(title_raw, index, book_map, state, context, is_production)
      end

      finalize_output(state)
    rescue StandardError => e
      raise "DisplayRankedBooks Error processing '#{@list_variable_markup}': #{e.message} \n #{e.backtrace.join("\n  ")}"
    end

    private

    def resolve_list(context)
      list = context[@list_variable_markup]
      unless list.is_a?(Array)
        raise "DisplayRankedBooks Error: Input '#{@list_variable_markup}' is not a valid list (Array). Found: #{list.class}"
      end
      list
    end

    def build_book_map(site)
      unless site.collections.key?('books')
        raise "DisplayRankedBooks Error: Collection 'books' not found in site configuration."
      end

      site.collections['books'].docs.each_with_object({}) do |book, map|
        next if book.data['published'] == false

        title = book.data['title']
        next unless title && !title.to_s.strip.empty?

        normalized = TextProcessingUtils.normalize_title(title, strip_articles: false)
        map[normalized] = book
      end
    end

    def initialize_state
      {
        output_buffer: String.new,
        current_rating_group: nil,
        is_div_open: false,
        found_ratings: [],
        prev_rating: Float::INFINITY,
        prev_title: nil
      }
    end

    def process_item(title_raw, index, book_map, state, context, is_production)
      normalized = TextProcessingUtils.normalize_title(title_raw, strip_articles: false)
      book = book_map[normalized]

      validate_item(title_raw, index, book, state) unless is_production

      return unless valid_for_rendering?(book, title_raw, context, state, is_production)

      rating = get_rating(book, title_raw, context, is_production)
      return unless rating

      handle_group_change(rating, state)
      state[:output_buffer] << BookCardUtils.render(book, context) << "\n"
    end

    def validate_item(title_raw, index, book, state)
      unless book
        raise "DisplayRankedBooks Validation Error: Title '#{title_raw}' (position #{index + 1} in '#{@list_variable_markup}') not found in the 'books' collection."
      end

      rating = parse_rating(book.data['rating'], title_raw, index)

      if rating > state[:prev_rating]
        raise "DisplayRankedBooks Validation Error: Monotonicity violation in '#{@list_variable_markup}'. \n  " \
          "Title '#{title_raw}' (Rating: #{rating}) at position #{index + 1} \n  " \
          "cannot appear after \n  " \
          "Title '#{state[:prev_title]}' (Rating: #{state[:prev_rating]}) at position #{index}."
      end

      state[:prev_rating] = rating
      state[:prev_title] = title_raw
    end

    def parse_rating(raw, title, index)
      Integer(raw)
    rescue ArgumentError, TypeError
      raise "DisplayRankedBooks Validation Error: Title '#{title}' (position #{index + 1} in '#{@list_variable_markup}') has invalid non-integer rating: '#{raw.inspect}'."
    end

    def valid_for_rendering?(book, title_raw, context, state, is_production)
      return true if book

      if is_production
        state[:output_buffer] << PluginLoggerUtils.log_liquid_failure(
          context: context, tag_type: 'DISPLAY_RANKED_BOOKS',
          reason: 'Book title from ranked list not found in lookup map (Production Mode).',
          identifiers: { Title: title_raw, ListVariable: @list_variable_markup },
          level: :error
        )
      end
      false
    end

    def get_rating(book, title_raw, context, is_production)
      return Integer(book.data['rating']) unless is_production

      begin
        Integer(book.data['rating'])
      rescue ArgumentError, TypeError
        PluginLoggerUtils.log_liquid_failure(
          context: context, tag_type: 'DISPLAY_RANKED_BOOKS',
          reason: 'Book has invalid non-integer rating (Production Mode).',
          identifiers: { Title: title_raw, Rating: book.data['rating'].inspect,
                         ListVariable: @list_variable_markup },
                         level: :error
        )
        nil
      end
    end

    def handle_group_change(rating, state)
      return if rating == state[:current_rating_group]

      if state[:is_div_open]
        state[:output_buffer] << "</div>\n"
        state[:is_div_open] = false
      end

      state[:found_ratings] << rating
      state[:output_buffer] << render_group_header(rating)
      state[:output_buffer] << "<div class=\"card-grid\">\n"
      state[:is_div_open] = true
      state[:current_rating_group] = rating
    end

    def render_group_header(rating)
      h2_id = "rating-#{rating}"
      "<h2 class=\"book-list-headline\" id=\"#{h2_id}\">" \
        "#{RatingUtils.render_rating_stars(rating, 'span')}" \
        "</h2>\n"
    end

    def finalize_output(state)
      state[:output_buffer] << "</div>\n" if state[:is_div_open]
      generate_nav(state[:found_ratings]) + state[:output_buffer]
    end

    def generate_nav(ratings)
      return '' if ratings.empty?

      links = ratings.map do |r|
        text = r == 1 ? "#{r}&nbsp;Star" : "#{r}&nbsp;Stars"
        "<a href=\"#rating-#{r}\">#{text}</a>"
      end

      "<nav class=\"alpha-jump-links\">\n  #{links.join(' &middot; ')}\n</nav>\n"
    end
  end
end

Liquid::Template.register_tag('display_ranked_books', Jekyll::DisplayRankedBooksTag)
