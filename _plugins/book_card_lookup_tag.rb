# _plugins/book_card_lookup_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'       # For HTML escaping
require 'strscan'   # For flexible argument parsing
require_relative 'liquid_utils'
require_relative 'utils/plugin_logger_utils'

module Jekyll
  class BookCardLookupTag < Liquid::Tag
    QuotedFragment = Liquid::QuotedFragment

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup
      @include_template_path = '_includes/book_card.html'

      @title_markup = nil
      scanner = StringScanner.new(markup.strip)
      if scanner.scan(/title\s*=\s*(#{QuotedFragment}|\S+)/)
        @title_markup = scanner[1]
      else
        if scanner.scan(QuotedFragment) || scanner.scan(/\S+/)
           @title_markup = scanner.matched
        end
      end
      scanner.skip(/\s+/)
      unless scanner.eos?
        raise Liquid::SyntaxError, "Syntax Error in 'book_card_lookup': Unknown argument(s) '#{scanner.rest}' in '#{@raw_markup}'"
      end
      unless @title_markup && !@title_markup.strip.empty?
         raise Liquid::SyntaxError, "Syntax Error in 'book_card_lookup': Could not find title value in '#{@raw_markup}'"
      end
    end

    # Helper to safely get data from book, providing defaults
    def get_book_data(book)
      return {} unless book && book.respond_to?(:url) && book.respond_to?(:data)

      # --- Fix for Excerpt Deprecation ---
      # Use book.data['excerpt'] instead of book.excerpt
      description = book.data['excerpt'] || ''
      # --- End Fix ---

      {
        'url' => book.url || '',
        'image' => book.data['image'] || '',
        'title' => book.data['title'] || 'Untitled Book',
        'author' => book.data['book_author'] || nil,
        'rating' => book.data['rating'] || nil,
        'description' => description
      }
    end

    # Renders the book card by looking up the book and including the template
    def render(context)
      site = context.registers[:site]
      target_title = LiquidUtils.resolve_value(@title_markup, context).to_s.gsub(/\s+/, ' ').strip
      unless target_title && !target_title.empty?
        PluginLoggerUtils.log_liquid_failure(context: context, tag_type: "BOOK_CARD_LOOKUP", reason: "Title markup resolved to empty", identifiers: { Markup: @title_markup || @raw_markup })
        return ""
      end
      target_title_downcased = target_title.downcase

      found_book = nil
      if site.collections.key?('books')
        found_book = site.collections['books'].docs.find do |book|
          next if book.data['published'] == false
          book.data['title']&.gsub(/\s+/, ' ')&.strip&.downcase == target_title_downcased
        end
      end

      unless found_book
        PluginLoggerUtils.log_liquid_failure(context: context, tag_type: "BOOK_CARD_LOOKUP", reason: "Could not find book", identifiers: { Title: target_title })
        return ""
      end

      # --- Render the Include (Context Fix) ---
      begin
        include_path = site.in_source_dir(@include_template_path)
        raise IOError, "Include file '#{@include_template_path}' not found" unless File.exist?(include_path)
        source = site.liquid_renderer.file("(include)").parse(File.read(include_path))

        # Use context.stack to create a new scope for the include variables
        # This preserves registers like :site and :page better than Liquid::Context.new
        context.stack do
          # Assign the extracted book data to the 'include' variable within the new scope
          context['include'] = get_book_data(found_book)
          # Render the include content within this stacked context
          source.render!(context)
        end # context.stack automatically pops the scope

      rescue => e
        PluginLoggerUtils.log_liquid_failure(
            context: context,
            tag_type: "BOOK_CARD_LOOKUP",
            reason: "Error loading or rendering include '#{@include_template_path}'",
            identifiers: { Title: target_title, Error: e.message }
        )
        "" # Return empty on error
      end
      # --- End Render Include ---
    end # End render
  end # End class
end # End module

Liquid::Template.register_tag('book_card_lookup', Jekyll::BookCardLookupTag)
