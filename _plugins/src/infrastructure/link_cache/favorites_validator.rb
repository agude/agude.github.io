# frozen_string_literal: true

module Jekyll
  module Infrastructure
    module LinkCache
      # Validates book_card_lookup tags in favorites posts.
      #
      # Checks that:
      # 1. Tags include the date parameter
      # 2. The date matches an existing review
      #
      # This is a lightweight error collector used by FavoritesManager during its scan.
      # Accumulates all violations and raises a single comprehensive error at the end.
      class FavoritesValidator
        DATE_PARAM_REGEX = /date\s*=/

        def initialize
          @missing_date_errors = []
          @date_mismatch_errors = []
        end

        def check_tag(post, tag_content)
          return if tag_content.match?(DATE_PARAM_REGEX)

          @missing_date_errors << { post: post, tag_content: tag_content.strip }
        end

        def check_date_match(post, title, date)
          @date_mismatch_errors << { post: post, title: title, date: date }
        end

        def raise_if_errors!
          return if @missing_date_errors.empty? && @date_mismatch_errors.empty?

          raise build_error_message
        end

        private

        def build_error_message
          lines = []
          lines.concat(build_missing_date_message) if @missing_date_errors.any?
          lines.concat(build_date_mismatch_message) if @date_mismatch_errors.any?
          lines.join("\n")
        end

        def build_missing_date_message
          grouped = @missing_date_errors.group_by { |e| e[:post].url }

          lines = ["FavoritesValidator: Missing date parameter on book_card_lookup tags\n"]
          grouped.each do |post_url, errors|
            lines << "  #{post_url}:"
            errors.each do |error|
              lines << "    - {% book_card_lookup #{error[:tag_content]} %}"
            end
          end
          lines << ''
          lines
        end

        def build_date_mismatch_message
          grouped = @date_mismatch_errors.group_by { |e| e[:post].url }

          lines = ["FavoritesValidator: No matching review found for date\n"]
          grouped.each do |post_url, errors|
            lines << "  #{post_url}:"
            errors.each do |error|
              lines << "    - title=\"#{error[:title]}\" date=\"#{error[:date]}\""
            end
          end
          lines
        end
      end
    end
  end
end
