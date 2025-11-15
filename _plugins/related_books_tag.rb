# _plugins/related_books_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'

require_relative 'utils/plugin_logger_utils'
require_relative 'utils/book_card_utils'
require_relative 'utils/front_matter_utils'
require_relative 'utils/book_list_utils'
require_relative 'utils/text_processing_utils'

module Jekyll
  class RelatedBooksTag < Liquid::Tag
    DEFAULT_MAX_BOOKS = 3

    def initialize(tag_name, markup, tokens)
      super
      @max_books = DEFAULT_MAX_BOOKS
    end

    def render(context)
      site = context.registers[:site]
      page = context.registers[:page]
      log_messages_html = '' # Initialize for collecting log messages

      unless site && page && site.collections.key?('books') && page['url']
        missing_parts = []
        missing_parts << 'site object' unless site
        missing_parts << 'page object' unless page
        missing_parts << "site.collections['books']" unless site&.collections&.key?('books')
        missing_parts << "page['url']" unless page && page['url']

        # This log message is returned directly, halting further processing.
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'RELATED_BOOKS',
          reason: "Missing prerequisites: #{missing_parts.join(', ')}.",
          identifiers: { PageURL: page ? page['url'] : 'N/A' },
          level: :error
        )
      end

      link_cache = site.data['link_cache']
      unless link_cache && link_cache['series_map']
        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'RELATED_BOOKS',
          reason: 'Link cache is missing. Ensure LinkCacheGenerator is running.',
          identifiers: { PageURL: page['url'] },
          level: :error
        )
      end

      current_url = page['url']
      urls_to_exclude = Set.new([current_url])
      # Exclude the canonical URL if the current page is an archive
      urls_to_exclude.add(page['canonical_url']) if page['canonical_url']&.start_with?('/')

      current_series = page['series']
      current_page_authors = FrontMatterUtils.get_list_from_string_or_array(page['book_authors'])
                                             .map(&:strip).map(&:downcase).reject(&:empty?)
      now_unix = Time.now.to_i

      all_potential_books = site.collections['books'].docs.select do |book|
        book && book.data && # Ensure book and book.data are not nil
          book.data['published'] != false &&
          !book.data['canonical_url']&.start_with?('/') && # Exclude archived reviews
          !urls_to_exclude.include?(book.url) && # Exclude current page and its canonical version
          book.date && book.date.to_time.to_i <= now_unix
      end.compact # Ensure no nils from a faulty collection.docs

      books_by_date_desc = all_potential_books.sort_by { |book| book.date }.reverse
      candidate_books_accumulator = []
      current_book_num_parsed = BookListUtils.__send__(:_parse_book_number, page['book_number'])

      if current_series && !current_series.to_s.strip.empty?
        normalized_series_name = TextProcessingUtils.normalize_title(current_series)
        series_books_from_cache = link_cache['series_map'][normalized_series_name] || []

        # Use the cache to get series book URLs, then select from our already-filtered list
        cached_series_urls = Set.new(series_books_from_cache.map(&:url))
        series_books_all_others = all_potential_books.select do |book|
          cached_series_urls.include?(book.url)
        end

        if current_book_num_parsed == Float::INFINITY
          log_messages_html << PluginLoggerUtils.log_liquid_failure(
            context: context,
            tag_type: 'RELATED_BOOKS_SERIES',
            reason: "Current page has unparseable book_number ('#{page['book_number']}'). Using all series books sorted by number.",
            identifiers: { PageURL: page['url'], Series: current_series },
            level: :info
          )
          series_books_fallback = series_books_all_others
                                  .sort_by do |book|
            BookListUtils.__send__(:_parse_book_number,
                                   book.data['book_number'])
          end
          candidate_books_accumulator.concat(series_books_fallback)
        elsif series_books_all_others.any?
          books_with_parsed_numbers = series_books_all_others.map do |book|
            { doc: book, num: BookListUtils.__send__(:_parse_book_number, book.data['book_number']) }
          end.reject { |b_info| b_info[:num] == Float::INFINITY }

          preceding_books_raw = books_with_parsed_numbers
                                .select { |b_info| b_info[:num] < current_book_num_parsed }
                                .sort_by { |b_info| -b_info[:num] }
                                .map { |b_info| b_info[:doc] }

          succeeding_books_raw = books_with_parsed_numbers
                                 .select { |b_info| b_info[:num] > current_book_num_parsed }
                                 .sort_by { |b_info| b_info[:num] }
                                 .map { |b_info| b_info[:doc] }

          selected_series_candidates = []
          temp_selection_tracker = []
          slots_to_fill_from_series = @max_books
          idx_pre = 0
          idx_succ = 0

          while temp_selection_tracker.length < slots_to_fill_from_series &&
                (idx_pre < preceding_books_raw.length || idx_succ < succeeding_books_raw.length)
            if idx_pre < preceding_books_raw.length && temp_selection_tracker.length < slots_to_fill_from_series
              book_to_add = preceding_books_raw[idx_pre]
              unless selected_series_candidates.map(&:url).include?(book_to_add.url)
                selected_series_candidates << book_to_add
              end
              temp_selection_tracker << book_to_add
              idx_pre += 1
            end
            unless idx_succ < succeeding_books_raw.length && temp_selection_tracker.length < slots_to_fill_from_series
              next
            end

            book_to_add = succeeding_books_raw[idx_succ]
            unless selected_series_candidates.map(&:url).include?(book_to_add.url)
              selected_series_candidates << book_to_add
            end
            temp_selection_tracker << book_to_add
            idx_succ += 1
          end

          final_series_books_to_add = selected_series_candidates.sort_by do |book|
            BookListUtils.__send__(:_parse_book_number, book.data['book_number'])
          end
          candidate_books_accumulator.concat(final_series_books_to_add)
        end
      end

      current_unique_urls = Set.new(candidate_books_accumulator.map(&:url))
      if current_unique_urls.length < @max_books && current_page_authors.any?
        author_books = books_by_date_desc.select do |book|
          next if current_unique_urls.include?(book.url)

          book_author_list = FrontMatterUtils.get_list_from_string_or_array(book.data['book_authors'])
                                             .map(&:strip).map(&:downcase).reject(&:empty?)
          (current_page_authors & book_author_list).any?
        end
        candidate_books_accumulator.concat(author_books)
      end

      current_unique_urls = Set.new(candidate_books_accumulator.map(&:url))
      if current_unique_urls.length < @max_books
        books_by_date_desc.each do |book|
          break if Set.new(candidate_books_accumulator.map(&:url)).length >= @max_books

          candidate_books_accumulator << book unless candidate_books_accumulator.map(&:url).include?(book.url)
        end
      end

      final_books = candidate_books_accumulator.uniq { |book| book.url }.slice(0, @max_books)

      return log_messages_html if final_books.empty? # Prepend logs if no books found

      output = "<aside class=\"related\">\n"
      output << "  <h2>Related Books</h2>\n"
      output << "  <div class=\"card-grid\">\n"
      final_books.each do |book|
        output << BookCardUtils.render(book, context) << "\n"
      end
      output << "  </div>\n"
      output << '</aside>'

      log_messages_html + output # Prepend any collected log messages
    end
  end
end

Liquid::Template.register_tag('related_books', Jekyll::RelatedBooksTag)
