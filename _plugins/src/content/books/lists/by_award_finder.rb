# frozen_string_literal: true

# _plugins/logic/book_lists/by_award_finder.rb
require_relative 'shared'
require_relative '../../../infrastructure/text_processing_utils'

module Jekyll
  module Books
    module Lists
      module Renderers
        module BookLists
          # Finds and structures all books grouped by award.
          #
          # Handles validation, collecting unique awards, grouping books by award,
          # and formatting award names for display.
          class ByAwardFinder
            include Jekyll::Books::Lists::Renderers::BookLists::Shared

            def initialize(site:, context:)
              @site = site
              @context = context
            end

            # Finds and structures all books grouped by award.
            # @return [Hash] Contains :awards_data (Array of Hashes), :log_messages (String).
            def find
              error = validate_collection({ filter_type: 'all_books_by_award' }, key: :awards_data)
              return error if error

              all_books = all_published_books(include_archived: false)
              return { awards_data: [], log_messages: String.new } if all_books.empty?

              unique_awards = collect_unique_awards(all_books)
              awards_data_list = build_awards_data_list(unique_awards, all_books)
              log_msg = generate_awards_log(awards_data_list)

              { awards_data: awards_data_list, log_messages: log_msg }
            end

            private

            def collect_unique_awards(books)
              unique = {}
              books.each do |book|
                next unless book.data['awards'].is_a?(Array)

                book.data['awards'].each do |award|
                  next if award.nil? || award.to_s.strip.empty?

                  stripped = award.to_s.strip
                  unique[stripped.downcase] ||= stripped
                end
              end
              unique
            end

            def build_awards_data_list(unique_awards, all_books)
              sorted_awards = unique_awards.sort_by { |k, _v| k }.map { |_k, v| v }

              sorted_awards.filter_map do |raw_award|
                books = find_books_for_award(all_books, raw_award)
                next if books.empty?

                create_award_data_entry(raw_award, books)
              end
            end

            def create_award_data_entry(raw_award, books)
              display_name = format_award_display_name(raw_award)
              {
                award_name: display_name,
                award_slug: slugify_award(display_name),
                books: books
              }
            end

            def find_books_for_award(all_books, raw_award)
              books = all_books.select { |book| book_has_award?(book, raw_award) }
              books.sort_by { |b| Jekyll::Infrastructure::TextProcessingUtils.normalize_title(b.data['title'].to_s, strip_articles: true) }
            end

            def book_has_award?(book, raw_award)
              book.data['awards'].is_a?(Array) &&
                book.data['awards'].any? { |ba| ba.to_s.strip.casecmp(raw_award.strip).zero? }
            end

            def format_award_display_name(award_string_raw)
              return '' if award_string_raw.nil? || award_string_raw.to_s.strip.empty?

              words = award_string_raw.to_s.strip.split.map do |word|
                format_award_word(word)
              end
              "#{words.join(' ')} Award"
            end

            def format_award_word(word)
              if word.length == 2 && word[1] == '.' && word[0].match?(/[a-z]/i)
                "#{word[0].upcase}."
              else
                word.capitalize
              end
            end

            def slugify_award(name)
              Jekyll::Infrastructure::TextProcessingUtils.normalize_title(name, strip_articles: false)
                                                         .gsub(/\s+/, '-')
                                                         .gsub(/[^\w-]+/, '')
                                                         .gsub(/--+/, '-')
                                                         .gsub(/^-+|-+$/, '')
            end

            def generate_awards_log(data)
              return String.new unless data.empty?

              Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
                context: @context,
                tag_type: 'ALL_BOOKS_BY_AWARD_DISPLAY',
                reason: 'No books with awards found.',
                identifiers: {},
                level: :info
              ).dup
            end
          end
        end
      end
    end
  end
end
