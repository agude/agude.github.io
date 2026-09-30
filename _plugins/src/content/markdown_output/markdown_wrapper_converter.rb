# frozen_string_literal: true

module Jekyll
  module MarkdownOutput
    # Converts the site's supported span and div wrappers with balanced tags.
    module MarkdownWrapperConverter
      SPAN_CLASSES = %w[author-name book-series written-by nowrap band-name].freeze
      WRITTEN_BY_DIV_CLASSES = %w[written-by].freeze
      CHATGPT_DIV_CLASSES = %w[
        chatgpt-edit-block
        chatgpt-prompt
        chatgpt-output
        chatgpt-prompt-only
        chatgpt-output-only
      ].freeze
      WRAPPER_TAG_RE = %r{</?(?:span|div)(?=[\s/>])[^>]*>}im

      def self.convert(text)
        output = +''
        wrappers = []
        position = 0

        text.to_enum(:scan, WRAPPER_TAG_RE).each do
          match = Regexp.last_match
          tag = match[0]
          append_text(output, wrappers, text[position...match.begin(0)])

          if tag.match?(%r{\A</})
            close_wrapper(output, wrappers, tag)
          elsif tag.match?(%r{/\s*>\z})
            append_text(output, wrappers, tag)
          else
            wrappers << wrapper_frame(tag)
          end

          position = match.end(0)
        end

        append_text(output, wrappers, text[position..])
        preserve_unclosed_wrappers(output, wrappers)
        output
      end

      def self.append_text(output, wrappers, text)
        target = wrappers.empty? ? output : wrappers.last[:content]
        target << text.to_s
      end
      private_class_method :append_text

      def self.close_wrapper(output, wrappers, closing_tag)
        tag_name = closing_tag[%r{\A</(span|div)\b}i, 1].downcase
        wrapper = wrappers.last
        unless wrapper && wrapper[:name] == tag_name
          append_text(output, wrappers, closing_tag)
          return
        end

        wrappers.pop
        append_text(output, wrappers, wrapper_output(wrapper, closing_tag))
      end
      private_class_method :close_wrapper

      def self.wrapper_frame(opening_tag)
        {
          name: opening_tag[/\A<(span|div)\b/i, 1].downcase,
          opening_tag: opening_tag,
          behavior: wrapper_behavior(opening_tag),
          content: +'',
        }
      end
      private_class_method :wrapper_frame

      def self.wrapper_behavior(tag)
        name = tag[/\A<(span|div)\b/i, 1].downcase
        classes = class_attribute_values(tag)
        return :written_by if name == 'div' && classes.intersect?(WRITTEN_BY_DIV_CLASSES)

        handled_classes = name == 'span' ? SPAN_CLASSES : CHATGPT_DIV_CLASSES
        classes.intersect?(handled_classes) ? :strip : :preserve
      end
      private_class_method :wrapper_behavior

      def self.class_attribute_values(tag)
        attribute = tag.match(/(?<![\w:-])class\s*=\s*["']([^"']*)["']/i)
        attribute ? attribute[1].split : []
      end
      private_class_method :class_attribute_values

      def self.wrapper_output(wrapper, closing_tag)
        case wrapper[:behavior]
        when :strip then wrapper[:content]
        when :written_by then "\n\n#{wrapper[:content]}\n\n"
        else "#{wrapper[:opening_tag]}#{wrapper[:content]}#{closing_tag}"
        end
      end
      private_class_method :wrapper_output

      def self.preserve_unclosed_wrappers(output, wrappers)
        until wrappers.empty?
          wrapper = wrappers.pop
          append_text(output, wrappers, "#{wrapper[:opening_tag]}#{wrapper[:content]}")
        end
      end
      private_class_method :preserve_unclosed_wrappers
    end
  end
end
