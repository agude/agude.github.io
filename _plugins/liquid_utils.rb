# _plugins/liquid_utils.rb
require 'cgi'
require 'jekyll' # Needed for site config access in logger

# Utility methods for custom Liquid tags
module LiquidUtils

  # Resolves a Liquid markup string that might be a quoted literal or a variable name.
  # Handles single or double quotes for literals.
  # Falls back to the markup itself if it's not quoted and not found in the context.
  #
  # @param markup [String] The markup string from the Liquid tag.
  # @param context [Liquid::Context] The current Liquid context.
  # @return [String, Object, nil] The resolved value (String for literals, Object for variables), or nil.
  def self.resolve_value(markup, context)
    return nil if markup.nil? || markup.empty?
    stripped_markup = markup.strip
    # Check if it's a quoted string (single or double)
    if (stripped_markup.start_with?('"') && stripped_markup.end_with?('"')) || \
       (stripped_markup.start_with?("'") && stripped_markup.end_with?("'"))
      # Return the content inside the quotes
      stripped_markup[1..-2]
    else
      # Assume it's a variable name, look it up in the context.
      context[stripped_markup] || stripped_markup
    end
  end

  # Logs a failure message as an HTML comment in non-production environments.
  # Mimics the user's preferred logging format.
  #
  # @param context [Liquid::Context] The current Liquid context.
  # @param tag_type [String] The type of tag reporting the failure (e.g., "BOOK_LINK", "AUTHOR_LINK").
  # @param reason [String] The reason for the failure.
  # @param identifiers [Hash] A hash of key-value pairs identifying the item (e.g., { Title: "Some Title" }).
  # @return [void]
  def self.log_failure(context:, tag_type:, reason:, identifiers: {})
    site = context.registers[:site]
    # Determine environment (prefer jekyll.environment, fallback to ENV)
    jekyll_env = site.config['jekyll_environment'] || ENV['JEKYLL_ENV'] || 'development'

    # Only log in non-production environments
    return unless jekyll_env != "production"

    # Get the source page path if available
    page_path = context.registers[:page] ? context.registers[:page]['path'] : 'unknown'

    # Build the identifier string for the log message, escaping values
    identifier_string = identifiers.map { |key, value| "#{key}='#{CGI.escapeHTML(value.to_s)}'" }.join(' ')

    # Output the HTML comment log message to the console during build
    puts "#{tag_type}_FAILURE: Reason='#{reason}' #{identifier_string} SourcePage='#{page_path}'"
  end
end
