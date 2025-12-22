# frozen_string_literal: true

module Jekyll
  module Infrastructure
    module LinkCache
      # Validates that book_card_lookup tags in favorites posts include the date parameter.
      #
      # This is a lightweight error collector used by FavoritesManager during its scan.
      # Accumulates all violations and raises a single comprehensive error at the end.
      class FavoritesValidator
        DATE_PARAM_REGEX = /date\s*=/

        def initialize
          @errors = []
        end

        def check_tag(post, tag_content)
          return if tag_content.match?(DATE_PARAM_REGEX)

          @errors << { post: post, tag_content: tag_content.strip }
        end

        def raise_if_errors!
          return if @errors.empty?

          raise build_error_message
        end

        private

        def build_error_message
          grouped = @errors.group_by { |e| e[:post].url }

          lines = ["FavoritesValidator: Missing date parameter on book_card_lookup tags\n"]
          grouped.each do |post_url, errors|
            lines << "  #{post_url}:"
            errors.each do |error|
              lines << "    - {% book_card_lookup #{error[:tag_content]} %}"
            end
          end
          lines.join("\n")
        end
      end
    end
  end
end
