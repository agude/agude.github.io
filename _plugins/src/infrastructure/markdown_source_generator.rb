# frozen_string_literal: true

# _plugins/src/infrastructure/markdown_source_generator.rb
require 'jekyll'

module Jekyll
  module Infrastructure
    # Generator that creates .md source files for posts, books, and pages.
    #
    # These markdown files are intended for LLM/agent consumption,
    # rendering Liquid tags in markdown mode (outputting markdown links
    # instead of HTML links).
    #
    # Uses .mdsrc extension during generation (which Jekyll won't convert),
    # then renames to .md after all files are written.
    #
    # Output URLs:
    # - Post at /blog/2024/01/01/title/ -> /blog/2024/01/01/title.md
    # - Book at /books/title-author/ -> /books/title-author.md
    # - Page at /resume/ -> /resume.md
    #
    # Pages can opt-out with `markdown_source: false` in frontmatter.
    # Utility pages (404, etc.) are excluded by default.
    class MarkdownSourceGenerator < Generator
      safe true
      # Run after LinkCacheGenerator and other generators
      priority :lowest

      # Page names to exclude by default (can be overridden with markdown_source: true)
      EXCLUDED_PAGE_NAMES = %w[404.md 404.html].freeze

      def generate(site)
        Jekyll.logger.info 'MarkdownSourceGenerator:', 'Generating markdown source files...'

        generate_for_collection(site, site.posts.docs, :post)
        generate_for_collection(site, site.collections['books']&.docs || [], :book)
        generate_for_pages(site)

        Jekyll.logger.info 'MarkdownSourceGenerator:', 'Markdown source generation complete.'
      end

      private

      def generate_for_collection(site, docs, type)
        docs.each do |doc|
          next if doc.data['published'] == false

          create_markdown_page(site, doc, type)
        end
      end

      def generate_for_pages(site)
        site.pages.each do |page|
          next unless include_page?(page)

          create_markdown_page(site, page, :page)
        end
      end

      def include_page?(page)
        # Explicit opt-out
        return false if page.data['markdown_source'] == false

        # Explicit opt-in overrides all other checks
        return true if page.data['markdown_source'] == true

        # Must have a layout (real content page, not static file)
        return false unless page.data['layout']

        # Skip utility pages
        return false if EXCLUDED_PAGE_NAMES.include?(page.name)

        # Skip non-markdown/html source files
        return false unless %w[.md .markdown .html].include?(page.extname)

        true
      end

      def create_markdown_page(site, doc, type)
        # Get the URL path without trailing slash
        url_base = doc.url.chomp('/')

        # Handle root index page (URL is "/" which becomes "")
        if url_base.empty?
          dir = '/'
          basename = 'index'
          permalink = '/index.mdsrc'
        else
          dir = File.dirname(url_base)
          basename = File.basename(url_base)
          permalink = "#{url_base}.mdsrc"
        end

        # Use .mdsrc extension (Jekyll won't convert it)
        # Will be renamed to .md in post_write hook
        page = PageWithoutAFile.new(site, site.source, dir, "#{basename}.mdsrc")

        # Generate content
        content = render_markdown_content(site, doc, type)

        page.content = content
        page.data['layout'] = nil
        page.data['sitemap'] = false
        page.data['permalink'] = permalink

        site.pages << page
      end

      def render_markdown_content(site, doc, type)
        # Build frontmatter
        frontmatter = build_frontmatter(doc, type)

        # Get source content (after frontmatter)
        source_content = extract_source_content(doc)

        # Render through Liquid with markdown_mode enabled
        rendered_content = render_with_markdown_mode(site, doc, source_content)

        # Normalize whitespace (Liquid tags leave excess blank lines)
        normalized_content = normalize_whitespace(rendered_content)

        "#{frontmatter}#{normalized_content}"
      end

      def normalize_whitespace(content)
        content
          .gsub(/^[ \t]+$/, '')         # Convert whitespace-only lines to empty lines
          .gsub(/\n{3,}/, "\n\n")       # Collapse 3+ newlines into 2
      end

      def build_frontmatter(doc, type)
        lines = ['---']

        case type
        when :post
          lines.concat(build_post_frontmatter(doc))
        when :book
          lines.concat(build_book_frontmatter(doc))
        when :page
          lines.concat(build_page_frontmatter(doc))
        end

        lines << '---'
        lines << ''

        lines.join("\n")
      end

      def build_post_frontmatter(doc)
        lines = []
        lines << "title: #{yaml_quote(doc.data['title'])}" if doc.data['title']
        lines << "date: #{format_date(doc.date)}" if doc.date
        lines << "description: #{yaml_quote(doc.data['description'])}" if doc.data['description']

        if doc.data['categories']&.any?
          cats = doc.data['categories'].map { |c| yaml_quote(c) }.join(', ')
          lines << "categories: [#{cats}]"
        end

        lines << "url: #{doc.url}"
        lines
      end

      def build_book_frontmatter(doc)
        lines = []
        lines << "title: #{yaml_quote(doc.data['title'])}" if doc.data['title']

        # Handle single author or multiple authors
        authors = doc.data['book_authors']
        if authors.is_a?(Array)
          lines << "authors: [#{authors.map { |a| yaml_quote(a) }.join(', ')}]"
        elsif authors
          lines << "author: #{yaml_quote(authors)}"
        end

        if doc.data['series']
          series_text = doc.data['series']
          series_text += " (Book #{doc.data['book_number']})" if doc.data['book_number']
          lines << "series: #{yaml_quote(series_text)}"
        end

        lines << "rating: #{doc.data['rating']}/5" if doc.data['rating']
        lines << "review_date: #{format_date(doc.date)}" if doc.date
        lines << "url: #{doc.url}"
        lines
      end

      def build_page_frontmatter(page)
        lines = []
        lines << "title: #{yaml_quote(page.data['title'])}" if page.data['title']
        lines << "description: #{yaml_quote(page.data['description'])}" if page.data['description']
        lines << "url: #{page.url}"
        lines
      end

      def yaml_quote(value)
        return '""' if value.nil?

        str = value.to_s
        # Quote if contains special characters
        if str.match?(/[:#\[\]{}|>!&*?'"]/) || str.match?(/^\s/) || str.match?(/\s$/)
          "\"#{str.gsub('"', '\\"')}\""
        else
          str
        end
      end

      def format_date(date)
        return nil unless date

        date.strftime('%Y-%m-%d')
      end

      def extract_source_content(doc)
        # Read the raw file content
        return '' unless doc.path && File.exist?(doc.path)

        raw_content = File.read(doc.path, encoding: 'UTF-8')

        # Remove frontmatter (content between --- markers at the start)
        if raw_content =~ /\A---\s*\n(.*?\n?)^---\s*$\n?(.*)/m
          Regexp.last_match(2).lstrip
        else
          raw_content
        end
      end

      def render_with_markdown_mode(site, doc, content)
        # Create payload for Liquid rendering
        payload = site.site_payload.merge('page' => doc.data)

        # Create info hash with markdown_mode enabled
        # page register needs to be hash-like for Jekyll's include tag
        page_hash = doc.data.merge('path' => doc.path, 'url' => doc.url)
        info = {
          registers: {
            site: site,
            page: page_hash,
            markdown_mode: true
          }
        }

        # Render using Jekyll's liquid renderer
        site.liquid_renderer.file(doc.path).parse(content).render!(payload, info)
      rescue Liquid::Error => e
        Jekyll.logger.warn 'MarkdownSourceGenerator:',
                           "Liquid error rendering #{doc.path}: #{e.message}"
        content
      end
    end
  end
end

# Hook to rename .mdsrc files to .md after all files are written
Jekyll::Hooks.register :site, :post_write do |site|
  Dir.glob(File.join(site.dest, '**', '*.mdsrc')).each do |file|
    new_path = file.sub(/\.mdsrc$/, '.md')
    File.rename(file, new_path)
  end
end
