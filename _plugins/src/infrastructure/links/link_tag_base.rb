# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require 'strscan'
require_relative '../tag_argument_utils'
require_relative 'markdown_link_formatter'
require_relative 'link_helper_utils'

module Jekyll
  module Infrastructure
    module Links
      # Base class for link tags ({% book_link %}, {% author_link %}, ...).
      #
      # Subclasses declare their grammar instead of hand-rolling a parser:
      #
      #   class BookLinkTag < LinkTagBase
      #     self.subject = 'book title'
      #     self.resolver_class = Jekyll::Books::Core::BookLinkResolver
      #     self.option_spec = { link_text: :value, author: :value, cite: :value }
      #   end
      #
      # Grammar: a positional subject (quoted string or variable) followed by
      # keyword options in any order. `:value` options take `name=<quoted or
      # variable>`; `:flag` options are bare words. Unknown arguments and
      # missing or empty subjects (including empty-quoted, e.g. '') raise
      # Liquid::SyntaxError at parse time.
      #
      # Render flow: build the resolver, gather its arguments via the
      # `resolver_arguments` hook, then branch on render_mode —
      # `resolver.resolve` for HTML, `resolver.resolve_data` +
      # MarkdownLinkFormatter for Markdown.
      #
      # Subclass hooks:
      # - resolver_arguments(context) -> [positional_args, keyword_args] (required)
      # - markdown_italic?(data)      -> italicize Markdown text (default: false)
      # - markdown_result(data, context) -> override the whole Markdown branch
      class LinkTagBase < Liquid::Tag
        QuotedFragment = Liquid::QuotedFragment
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        MdLink = Jekyll::Infrastructure::Links::MarkdownLinkFormatter
        LinkHelper = Jekyll::Infrastructure::Links::LinkHelperUtils

        class << self
          # Human-readable name of the positional argument, used in error
          # messages (e.g. 'book title', 'author name').
          attr_accessor :subject
          # The resolver class; must respond to resolve / resolve_data.
          attr_accessor :resolver_class
          # Ordered table of keyword options: { name => :value | :flag }.
          attr_accessor :option_spec
        end

        def initialize(tag_name, markup, tokens)
          super
          @raw_markup = markup
          @subject_markup = nil
          @option_markup = {}
          @flags = {}
          parse_markup(markup)
        end

        def render(context)
          resolver = self.class.resolver_class.new(context)
          args, kwargs = resolver_arguments(context)

          if context.registers[:render_mode] == :markdown
            markdown_result(resolver.resolve_data(*args, **kwargs), context)
          else
            resolver.resolve(*args, **kwargs)
          end
        end

        private

        # --- Subclass hooks ---

        # Positional and keyword arguments for the resolver's
        # resolve / resolve_data pair.
        def resolver_arguments(_context)
          raise NotImplementedError, "#{self.class} must implement resolver_arguments"
        end

        def markdown_result(data, context)
          MdLink.format_link(
            data,
            italic: markdown_italic?(data),
            self_link: LinkHelper.self_link?(context, data[:url]),
          )
        end

        def markdown_italic?(_data)
          false
        end

        # --- Argument access ---

        def subject_value(context)
          TagArgs.resolve_value(@subject_markup, context)
        end

        def option_value(name, context)
          markup = @option_markup[name]
          TagArgs.resolve_value(markup, context) if markup
        end

        def flag?(name)
          @flags.fetch(name, false)
        end

        # Returns true unless the option resolves to the string 'false'
        # (case-insensitive) or the boolean false. Absent options are true.
        def option_enabled?(name, context)
          markup = @option_markup[name]
          return true unless markup

          TagArgs.resolve_value(markup, context).to_s.downcase != 'false'
        end

        # --- Parsing ---

        def parse_markup(markup)
          scanner = StringScanner.new(markup.strip)
          parse_subject(scanner)
          parse_options(scanner)
          validate_subject
        end

        def parse_subject(scanner)
          unless scanner.scan(QuotedFragment) || scanner.scan(/\S+/)
            raise Liquid::SyntaxError,
                  "Syntax Error in '#{@tag_name}': Could not find #{self.class.subject} in '#{@raw_markup}'"
          end

          @subject_markup = scanner.matched
        end

        def parse_options(scanner)
          until scanner.eos?
            scanner.skip(/\s+/)
            break if scanner.eos?

            scan_option(scanner) || handle_unknown_argument(scanner)
          end
        end

        def scan_option(scanner)
          self.class.option_spec.any? do |name, type|
            case type
            when :value then scan_value_option?(scanner, name)
            when :flag then scan_flag_option?(scanner, name)
            end
          end
        end

        def scan_value_option?(scanner, name)
          return false unless scanner.scan(/#{name}\s*=\s*(#{QuotedFragment})/)

          # Take the first occurrence if the option is repeated.
          @option_markup[name] ||= scanner[1]
          true
        end

        def scan_flag_option?(scanner, name)
          return false unless scanner.scan(/#{name}(?!\S)/)

          @flags[name] = true
          true
        end

        def handle_unknown_argument(scanner)
          unknown_arg = scanner.scan(/\S+/)
          raise Liquid::SyntaxError,
                "Syntax Error in '#{@tag_name}': Unknown argument '#{unknown_arg}' in '#{@raw_markup}'"
        end

        def validate_subject
          raise_empty_subject if @subject_markup.nil? || @subject_markup.strip.empty?

          quoted = @subject_markup.match(/\A(['"])(.*)\1\z/m)
          raise_empty_subject if quoted && quoted[2].strip.empty?
        end

        def raise_empty_subject
          raise Liquid::SyntaxError,
                "Syntax Error in '#{@tag_name}': #{self.class.subject.capitalize} value is missing " \
                "or empty in '#{@raw_markup}'"
        end
      end
    end
  end
end
