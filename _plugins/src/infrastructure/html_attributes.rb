# frozen_string_literal: true

require 'cgi'

module Jekyll
  module Infrastructure
    # Reads the attributes of one HTML start tag found by a string scan.
    #
    # Post-render injectors (ImageDimensionsInjector,
    # CodeBlockRegionInjector) rewrite start tags in place instead of
    # parsing and reserializing the page. They share this reader so that a
    # check for an attribute matches attribute names, never text inside a
    # quoted value.
    module HtmlAttributes
      # One attribute: name, then an optional double-, single-, or unquoted
      # value.
      ATTRIBUTE = %r{([^\s"'>/=]+)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>`]+)))?}
      # An attribute with the whitespace before it, for removal.
      SPACED_ATTRIBUTE = /\s+#{ATTRIBUTE.source}/
      private_constant :ATTRIBUTE, :SPACED_ATTRIBUTE

      # @param tag [String] A whole start tag, such as `<pre class="x">`.
      # @return [Hash{String => String, nil}] Lowercased attribute names to
      #   entity-decoded values; nil for a valueless attribute. The first
      #   occurrence of a name wins, as in an HTML parser.
      def self.parse(tag)
        body = tag.sub(/\A<[^\s>]+/, '').sub(%r{/?>\z}, '')
        body.scan(ATTRIBUTE).each_with_object({}) do |(name, *values), attributes|
          key = name.downcase
          next if attributes.key?(key)

          value = values.compact.first
          attributes[key] = value && CGI.unescapeHTML(value)
        end
      end

      # @param tag [String] A whole start tag.
      # @param name [String] The attribute to remove, in any letter case.
      # @return [String] The tag without every occurrence of the attribute.
      #   Quoted values are consumed whole, so text inside another
      #   attribute's value (`alt="sizes=large"`) is never removed.
      def self.remove(tag, name)
        head = tag[/\A<[^\s>]+/]
        head + tag[head.length..].gsub(SPACED_ATTRIBUTE) do |attribute|
          Regexp.last_match(1).casecmp?(name) ? '' : attribute
        end
      end
    end
  end
end
