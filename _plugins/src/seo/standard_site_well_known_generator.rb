# frozen_string_literal: true

require 'jekyll'
require_relative '../infrastructure/generated_static_file'

module Jekyll
  module SEO
    # Generates .well-known/site.standard.publication from the site's
    # standard.site publication URI. The file content is the bare AT-URI
    # with no trailing newline (verifiers compare the string exactly).
    #
    # A missing, empty, or malformed publication_uri is a fatal error: the
    # URI is committed in _config.yml, so a blank value means a broken
    # config, and skipping would silently un-verify the whole site while
    # CI stays green (repo rule 5: break, don't fail silently).
    class StandardSiteWellKnownGenerator < Generator
      priority :normal

      # The method segment allows dots etc. so a future did:web
      # (e.g. did:web:alexgude.com) is not rejected as malformed.
      PUBLICATION_URI_PATTERN =
        %r{\Aat://did:[a-z0-9]+:[a-zA-Z0-9._:%-]+/site\.standard\.publication/[a-zA-Z0-9._:~-]+\z}

      def generate(site)
        uri = site.config.dig('standard_site', 'publication_uri')

        if uri.nil? || uri.empty?
          raise Jekyll::Errors::FatalException,
                'standard_site.publication_uri is missing or empty in _config.yml — ' \
                'refusing to build an unverifiable site'
        end

        unless PUBLICATION_URI_PATTERN.match?(uri)
          raise Jekyll::Errors::FatalException,
                "standard_site.publication_uri is malformed: #{uri.inspect}"
        end

        site.static_files << Jekyll::Infrastructure::GeneratedStaticFile.new(
          site, '.well-known', 'site.standard.publication', uri,
        )
      end
    end
  end
end
