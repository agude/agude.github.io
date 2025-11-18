# frozen_string_literal: true
# _plugins/display_category_posts_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative 'utils/post_list_utils'
require_relative 'utils/article_card_utils'
require_relative 'utils/tag_argument_utils'
require_relative 'utils/plugin_logger_utils'

module Jekyll
  class DisplayCategoryPostsTag < Liquid::Tag
    SYNTAX_NAMED_ARG = /([\w-]+)\s*=\s*(#{Liquid::QuotedFragment}|\S+)/o
    ALLOWED_KEYS = %w[topic exclude_current_page].freeze
    REQUIRED_KEYS = ['topic'].freeze

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup.strip
      @attributes_markup = {} # Store the raw markup for each attribute's value

      scanner = StringScanner.new(@raw_markup)
      parsed_keys = []

      loop do
        scanner.skip(/\s*/) # Skip leading whitespace before the next argument
        break if scanner.eos?

        unless scanner.scan(SYNTAX_NAMED_ARG)
          # If we find something that's not a named argument, it's a syntax error
          # as this tag now only accepts named arguments.
          raise Liquid::SyntaxError,
                "Syntax Error in '#{tag_name}': Expected named arguments (e.g., key='value'). Found unexpected token near '#{scanner.rest.strip.split.first || ''}' in '#{@raw_markup}'"
        end

        key = scanner[1].to_s.strip
        value_markup = scanner[2].to_s.strip

        unless ALLOWED_KEYS.include?(key)
          raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': Unknown argument '#{key}' in '#{@raw_markup}'"
        end
        if @attributes_markup.key?(key)
          raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': Duplicate argument '#{key}' in '#{@raw_markup}'"
        end

        @attributes_markup[key] = value_markup
        parsed_keys << key
      end

      # Check for required arguments
      REQUIRED_KEYS.each do |req_key|
        unless @attributes_markup.key?(req_key)
          raise Liquid::SyntaxError,
                "Syntax Error in '#{tag_name}': Required argument '#{req_key}' is missing in '#{@raw_markup}'"
        end
      end
    end

    def render(context)
      site = context.registers[:site]
      page = context.registers[:page]

      # Resolve 'topic' (guaranteed to exist due to initialize check)
      topic_name_input = TagArgumentUtils.resolve_value(@attributes_markup['topic'], context)
      topic_name = topic_name_input.to_s.strip # Convert to string and strip

      if topic_name.empty?
        # This log happens if the resolved value of 'topic' is empty,
        # e.g., topic=empty_variable or topic="   "
        return PluginLoggerUtils.log_liquid_failure(
          context: context, tag_type: 'DISPLAY_CATEGORY_POSTS',
          reason: "Argument 'topic' resolved to an empty string.",
          identifiers: { topic_markup: @attributes_markup['topic'] },
          level: :error
        )
      end

      # Resolve 'exclude_current_page' (optional)
      exclude_current = false
      if @attributes_markup.key?('exclude_current_page')
        resolved_exclude_flag = TagArgumentUtils.resolve_value(@attributes_markup['exclude_current_page'], context)
        # True if the resolved value is boolean true or string "true" (case-insensitive)
        exclude_current = resolved_exclude_flag == true || resolved_exclude_flag.to_s.downcase == 'true'
      end

      url_to_exclude = exclude_current && page ? page['url'] : nil

      result = PostListUtils.get_posts_by_category(
        site: site,
        category_name: topic_name,
        context: context,
        exclude_url: url_to_exclude
      )

      output = result[:log_messages] || ''
      posts_to_render = result[:posts]

      # If no posts found (e.g., category doesn't exist, or all posts filtered out),
      # result[:posts] will be empty. The log message from PostListUtils will be in output.
      # So, we can just return output if posts_to_render is empty.
      return output if posts_to_render.empty?

      output << "<div class=\"card-grid\">\n"
      posts_to_render.each do |post|
        output << ArticleCardUtils.render(post, context) << "\n"
      end
      output << "</div>\n"

      output
    end
  end
end

Liquid::Template.register_tag('display_category_posts', Jekyll::DisplayCategoryPostsTag)
