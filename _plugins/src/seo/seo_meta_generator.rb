# frozen_string_literal: true

require 'nokogiri'

module Jekyll
  module SEO
    # Generates SEO meta tag values for Jekyll documents and pages.
    # Replaces jekyll-seo-tag functionality with custom control over output.
    class SeoMetaGenerator
      ARTICLE_LAYOUTS = %w[book post].freeze

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

      MAX_TITLE_LENGTH = 70

      # --- Title ---

      def build_title
        return @data['seo_title'] if @data['seo_title']

        case @data['layout']
        when 'book'
          book_title
        when 'author_page'
          "#{raw_title} - Book Reviews"
        when 'series_page'
          "#{raw_title} - Book Reviews"
        when 'category'
          "#{raw_title} - Articles"
        else
          homepage? ? "#{site_title} - #{site_tagline}" : raw_title
        end
      end

      def book_title
        author = first_book_author
        title = raw_title

        candidates = [
          "#{title} by #{author} - Book Review",
          "#{title} by #{author} - Review",
          "#{title} - Book Review",
          "#{title} - Review",
        ]

        candidates.find { |c| c.length <= MAX_TITLE_LENGTH } || candidates.last
      end

      def first_book_author
        authors = @data['book_authors']
        authors.is_a?(Array) ? authors.first : authors.to_s
      end

      def raw_title
        title = @data['title']
        return title if title && !title.to_s.strip.empty?

        raise Jekyll::Errors::FatalException,
              "SEO: Page '#{@document.relative_path || @document.url}' is missing a title"
      end

      def homepage?
        @document.url == '/'
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
        page_description || excerpt_text || site_description
      end

      def page_description
        desc = @data['description']
        desc&.strip&.empty? ? nil : desc
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
