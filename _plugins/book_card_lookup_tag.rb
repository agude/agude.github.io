# _plugins/book_card_lookup_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'liquid_utils'

module Jekyll
  # Liquid Tag to look up a book by title and render its card.
  # Usage: {% book_card_lookup title="Book Title" %}
  #        {% book_card_lookup title=variable_with_title %}
  class BookCardLookupTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      # Simple parsing: expect 'title="..."' or 'title=variable'
      if markup.strip =~ /^title\s*=\s*(.*)$/i
        @title_markup = $1.strip
      else
        raise Liquid::SyntaxError, "Syntax Error in 'book_card_lookup': Expected {% book_card_lookup title=... %}"
      end
      @include_template_path = '_includes/book_card.html' # Path to the presentation include
    end

    # Helper to safely get data from book, providing defaults
    def get_book_data(book)
      {
        'url' => book.url,
        'image' => book.data['image'] || nil,
        'title' => book.data['title'] || nill,
        'author' => book.data['book_author'] || nil,
        'rating' => book.data['rating'] || nil,
        'description' => book.excerpt || nil
      }
    end

    def render(context)
      site = context.registers[:site]

      # Resolve the title value
      target_title = LiquidUtils.resolve_value(@title_markup, context).to_s.gsub(/\s+/, ' ').strip
      unless target_title && !target_title.empty?
        LiquidUtils.log_failure(context: context, tag_type: "BOOK_CARD_LOOKUP", reason: "Title markup resolved to empty", identifiers: { Markup: @title_markup })
        return ""
      end
      target_title_downcased = target_title.downcase

      # --- Book Lookup ---
      found_book = nil
      if site.collections.key?('books')
        found_book = site.collections['books'].docs.find do |book|
          # Skip unpublished
          next if book.data['published'] == false
          # Compare downcased, stripped titles
          book.data['title']&.gsub(/\s+/, ' ')&.strip&.downcase == target_title_downcased
        end
      end
      # --- End Book Lookup ---

      unless found_book
        LiquidUtils.log_failure(context: context, tag_type: "BOOK_CARD_LOOKUP", reason: "Could not find book", identifiers: { Title: target_title })
        return "" # Or render a placeholder?
      end

      # --- Render the Include ---
      begin
        source = site.liquid_renderer.file("(include)")
                       .parse(File.read(site.in_source_dir(@include_template_path)))
      rescue => e
        LiquidUtils.log_failure(context: context, tag_type: "BOOK_CARD_LOOKUP", reason: "Failed to load include file '#{@include_template_path}'", identifiers: { Error: e.message })
        return ""
      end

      # Prepare the context for the include
      include_context = Liquid::Context.new(context.environments, context.registers, context.scopes)
      include_context['include'] = get_book_data(found_book)

      # Render the include content
      begin
        source.render!(include_context)
      rescue => e
        LiquidUtils.log_failure(context: context, tag_type: "BOOK_CARD_LOOKUP", reason: "Error rendering include '#{@include_template_path}'", identifiers: { Title: target_title, Error: e.message })
        ""
      end
      # --- End Render Include ---
    end
  end
end

Liquid::Template.register_tag('book_card_lookup', Jekyll::BookCardLookupTag)
