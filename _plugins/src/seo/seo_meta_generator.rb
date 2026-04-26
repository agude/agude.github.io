# frozen_string_literal: true

require 'nokogiri'
require_relative '../infrastructure/typography_utils'

module Jekyll
  module SEO
    # Generates SEO meta tag values for Jekyll documents and pages.
    # Replaces jekyll-seo-tag functionality with custom control over output.
    class SeoMetaGenerator
      ARTICLE_LAYOUTS = %w[book post review-post].freeze

      # Layouts whose SEO title is "<page title> - <suffix>".
      # `book` and `homepage` use custom logic instead.
      LAYOUT_TITLE_SUFFIX = {
        'author_page' => 'Book Reviews',
        'series_page' => 'Book Reviews',
        'category' => 'Articles',
      }.freeze

      # Name suffixes stripped before computing surname / given names.
      NAME_SUFFIXES = %w[Jr. Jr Sr. Sr II III IV V].freeze

      def initialize(document, site)
        @document = document
        @site = site
        @data = document.data || {}
        @config = site.config || {}
      end

      def self.generate(document, site)
        new(document, site).generate
      end

      def generate
        {
          'title' => build_title,
          'og_title' => build_title,
          'og_type' => og_type,
          'image' => absolute_image_url,
          'og_site_name' => site_title,
          'og_locale' => locale,
          'description' => description,
          'canonical' => canonical_url,
          'twitter_card' => twitter_card_type,
          'article_published_time' => article_published_time,
          'author' => author_name,
          'google_site_verification' => google_verification,
          'bing_site_verification' => bing_verification,
        }
      end

      private

      # --- Title ---

      def build_title
        return @data['seo_title'] if @data['seo_title']

        layout = @data['layout']
        return book_title if layout == 'book'
        return "#{site_title} - #{site_tagline}" if layout == 'homepage'

        suffix = LAYOUT_TITLE_SUFFIX[layout]
        suffix ? "#{raw_title} - #{suffix}" : raw_title
      end

      def book_title
        authors = Array(@data['book_authors']).reject { |a| a.to_s.strip.empty? }
        by_clause = format_by_clause(authors)
        by_clause.empty? ? "#{raw_title} - Book Review" : "#{raw_title} by #{by_clause} - Book Review"
      end

      def format_by_clause(authors)
        case authors.length
        when 1 then authors.first.to_s
        when 2 then format_pair(authors[0].to_s, authors[1].to_s)
        else '' # 0 or 3+ authors: no by-clause
        end
      end

      def format_pair(first, second)
        first_surname = surname(first)
        if !first_surname.empty? && first_surname == surname(second)
          "#{given_names(first)} & #{given_names(second)} #{first_surname}"
        else
          "#{first} & #{second}"
        end
      end

      def surname(name)
        parts = strip_name_suffixes(name)
        parts.last.to_s
      end

      def given_names(name)
        parts = strip_name_suffixes(name)
        parts[0..-2].join(' ')
      end

      def strip_name_suffixes(name)
        parts = name.to_s.strip.tr(',', '').split
        parts.pop while !parts.empty? && NAME_SUFFIXES.include?(parts.last)
        parts
      end

      def raw_title
        title = @data['title']
        unless title && !title.to_s.strip.empty?
          raise Jekyll::Errors::FatalException,
                "SEO: Page '#{@document.relative_path || @document.url}' is missing a title"
        end

        decode_html_entities(title)
      end

      def decode_html_entities(text)
        Nokogiri::HTML.fragment(text.to_s).text
      end

      def site_title
        @config['title'] || ''
      end

      def site_tagline
        @config['tagline'] || ''
      end

      # --- Open Graph Type ---

      def og_type
        article_layout? ? 'article' : 'website'
      end

      def article_layout?
        layout = @data['layout']
        ARTICLE_LAYOUTS.include?(layout)
      end

      # --- Description ---

      def description
        raw = page_description || excerpt_text || site_description
        Infrastructure::TypographyUtils.apply_typography(raw)
      end

      def page_description
        desc = @data['description']&.strip
        desc&.empty? ? nil : desc
      end

      def excerpt_text
        excerpt = @data['excerpt']
        return nil unless excerpt

        output = excerpt.respond_to?(:output) ? excerpt.output : excerpt.to_s
        strip_html(output)
      end

      def site_description
        @config['description'] || ''
      end

      def strip_html(text)
        Nokogiri::HTML.fragment(text.to_s).text.gsub(/\s+/, ' ').strip
      end

      # --- Image ---

      def absolute_image_url
        image = page_image || default_image
        return nil unless image

        make_absolute(image)
      end

      def page_image
        image = @data['image']
        return nil unless image

        image.is_a?(Hash) ? image['path'] : image
      end

      def default_image
        @config['logo'] || @config.dig('defaults', 'image')
      end

      # --- URLs ---

      def canonical_url
        make_absolute(@document.url)
      end

      def make_absolute(path)
        return nil unless path

        base_url = @config['url'] || ''
        baseurl = @config['baseurl'] || ''
        "#{base_url}#{baseurl}#{path}"
      end

      # --- Twitter ---

      def twitter_card_type
        explicit_card = @data.dig('twitter', 'card')
        return explicit_card if explicit_card

        page_image ? 'summary_large_image' : 'summary'
      end

      # --- Article Published Time ---

      def article_published_time
        return nil unless article_layout?

        date = @data['date'] || @document.date
        return nil unless date

        format_date(date)
      end

      def format_date(date)
        if date.respond_to?(:iso8601)
          date.iso8601
        elsif date.respond_to?(:strftime)
          date.strftime('%Y-%m-%dT%H:%M:%S%:z')
        else
          date.to_s
        end
      end

      # --- Author ---

      def author_name
        author = @config['author']
        return author['name'] if author.is_a?(Hash) && author['name']
        return author if author.is_a?(String)

        nil
      end

      # --- Locale ---

      def locale
        @config['locale'] || 'en_US'
      end

      # --- Verification Tags ---

      def google_verification
        @config.dig('webmaster_verifications', 'google')
      end

      def bing_verification
        @config.dig('webmaster_verifications', 'bing')
      end
    end
  end
end
