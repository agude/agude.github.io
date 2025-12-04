# frozen_string_literal: true

# _plugins/utils/short_story_title_util.rb
require_relative '../../infrastructure/typography_utils'
require_relative '../../infrastructure/text_processing_utils'

module Jekyll
  module ShortStories
    # Utility module for rendering short story titles with optional Kramdown IDs.
    #
    # Handles formatting story titles as <cite> elements and generating unique
    # Kramdown anchor IDs for section headers.
    module ShortStoryTitleUtil
      def self.render_title(context:, title:, no_id: false)
        # 1. Handle nil or empty title input
        return '' if title.nil? || title.to_s.strip.empty?

        # 2. Initialize the story title counter on the context if it doesn't exist
        context.registers[:story_title_counts] ||= Hash.new(0)

        # 3. Create the <cite> element using Jekyll::Infrastructure::TypographyUtils
        cite_element = create_cite_element(title)

        # 4. If `no_id` is true, return just the cite element
        return cite_element if no_id

        # 5. Otherwise, generate the unique Kramdown ID and return both
        kramdown_id = create_kramdown_id(context, title)
        "#{cite_element} #{kramdown_id}"
      end

      # Private helper methods
      class << self
        private

        def create_cite_element(story_title)
          prepared_title = Jekyll::Infrastructure::TypographyUtils.prepare_display_title(story_title)
          "<cite class=\"short-story-title\">#{prepared_title}</cite>"
        end

        def create_kramdown_id(context, story_title)
          base_slug = Jekyll::Infrastructure::TextProcessingUtils.slugify(story_title)
          final_slug = generate_unique_slug(context, base_slug)
          "{##{final_slug}}"
        end

        def generate_unique_slug(context, base_slug)
          context.registers[:story_title_counts][base_slug] += 1
          count = context.registers[:story_title_counts][base_slug]
          count > 1 ? "#{base_slug}-#{count}" : base_slug
        end
      end
    end
  end
end
