# frozen_string_literal: true

require_relative 'seo_meta_generator'

module Jekyll
  module SEO
    # Injects SEO meta tag data into Jekyll documents and pages.
    # Data is stored in site.data['seo_meta'][page.url] for use by includes.
    module SeoMetaInjector
      def self.initialize_storage(site)
        site.data['seo_meta'] ||= {}
      end

      HTML_EXTENSIONS = %w[.html .htm].freeze
      SKIP_LAYOUTS = %w[redirect].freeze

      def self.inject_meta(document, site)
        initialize_storage(site)

        doc_url = document.url
        return unless doc_url && !doc_url.empty?
        return unless html_output?(document)
        return unless processable_layout?(document)

        meta = SeoMetaGenerator.generate(document, site)
        site.data['seo_meta'][doc_url] = meta
      end

      def self.html_output?(document)
        ext = File.extname(document.url)
        ext.empty? || HTML_EXTENSIONS.include?(ext.downcase)
      end

      def self.processable_layout?(document)
        layout = document.data['layout']
        return false if layout.nil? || layout.to_s.strip.empty?

        !SKIP_LAYOUTS.include?(layout.to_s)
      end
    end
  end
end

# --- Register Hooks ---

Jekyll::Hooks.register :site, :after_reset, priority: :high do |site|
  Jekyll::SEO::SeoMetaInjector.initialize_storage(site)
end

Jekyll::Hooks.register :documents, :post_convert do |document|
  next if document.is_a?(Jekyll::StaticFile)
  next if document.respond_to?(:draft?) && document.draft? && !document.site.show_drafts

  site = document.site
  Jekyll::SEO::SeoMetaInjector.inject_meta(document, site) if site
end

Jekyll::Hooks.register :pages, :post_convert do |page|
  next if page.is_a?(Jekyll::StaticFile)

  site = page.site
  Jekyll::SEO::SeoMetaInjector.inject_meta(page, site) if site
end
