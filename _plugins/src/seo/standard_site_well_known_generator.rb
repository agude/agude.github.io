# frozen_string_literal: true

require 'jekyll'
require_relative '../infrastructure/generated_static_file'

module Jekyll
  module SEO
    # Generates .well-known/site.standard.publication when the site has a valid
    # standard.site publication URI configured. The file content is the bare
    # AT-URI with no trailing newline (verifiers compare the string exactly).
    #
    # If publication_uri is missing or empty the generator logs a warning and
    # skips — the feature simply isn't configured yet. A malformed URI is a
    # fatal error so the build breaks loudly rather than shipping a bad file.
    class StandardSiteWellKnownGenerator < Generator
      priority :normal

      PUBLICATION_URI_PATTERN =
        %r{\Aat://did:[a-z0-9:]+/site\.standard\.publication/[a-zA-Z0-9._:~-]+\z}

      def generate(site)
        uri = site.config.dig('standard_site', 'publication_uri')

        if uri.nil? || uri.empty?
          Jekyll.logger.warn 'StandardSite:',
                             'publication_uri not configured; skipping .well-known generation'
          return
        end

        unless PUBLICATION_URI_PATTERN.match?(uri)
          raise Jekyll::Errors::FatalException,
                "standard_site.publication_uri is malformed: #{uri.inspect}"
        end

        site.static_files << Jekyll::Infrastructure::GeneratedStaticFile.new(
          site, '.well-known', 'site.standard.publication', uri
        )
      end
    end
  end
end
