# _plugins/utils/link_helper_utils.rb
require 'jekyll'

module LinkHelperUtils

  # Determines the correct text to display for a link/span.
  # Prioritizes override_text, then canonical_title from found_doc, then input_text.
  # @param input_text [String] The original text passed to the tag.
  # @param override_text [String, nil] The optional link_text override.
  # @param found_doc [MockDocument, Jekyll::Document, Jekyll::Page, nil] The document if found.
  # @return [String] The text to display.
  def self._get_link_display_text(input_text, override_text, found_doc)
    display_text = input_text.to_s.strip # Default to stripped input
    if override_text && !override_text.empty?
      display_text = override_text.strip
    elsif found_doc && found_doc.data['title'] # Assumes canonical name is in 'title'
      canonical_title = found_doc.data['title'].strip
      # Use canonical title only if it's not empty after stripping
      display_text = canonical_title unless canonical_title.empty?
    end
    # Fallback is the stripped input_text if override is missing/empty
    # AND (doc not found OR doc title is missing/empty)
    display_text
  end

  # Generates the final HTML (<a> or just the inner element) based on the target URL and context.
  # @param context [Liquid::Context] The current Liquid context.
  # @param target_url [String, nil] The URL to link to.
  # @param inner_html_element [String] The pre-built inner HTML (e.g., <cite>...</cite>, <span>...</span>).
  # @return [String] The final HTML string (linked or unlinked).
  def self._generate_link_html(context, target_url, inner_html_element)
    # Ensure context and site are available for baseurl and current page check
    unless context && (site = context.registers[:site]) && (page = context.registers[:page])
      return inner_html_element # Cannot determine link validity without context
    end

    current_page_url = page['url']
    target_url_str = target_url.to_s # Ensure string

    # Strip the fragment from the target URL before comparing.
    target_base_url = target_url_str.split('#').first

    # Link if target URL exists AND is not empty AND its base path is not the current page
    if !target_url_str.empty? && target_base_url != current_page_url
      baseurl = site.config['baseurl'] || ''
      # Ensure target_url starts with a slash if baseurl is present and url doesn't already have it
      # Check against baseurl itself too, in case the URL already includes it somehow
      if !baseurl.empty? && !target_url_str.start_with?('/') && !target_url_str.start_with?(baseurl)
        target_url_str = "/#{target_url_str}"
      end
      # Prepend baseurl if it's not already part of the target_url_str
      href = target_url_str.start_with?(baseurl) ? target_url_str : "#{baseurl}#{target_url_str}"

      "<a href=\"#{href}\">#{inner_html_element}</a>"
    else
      inner_html_element # It's the current page, context/URL is missing, or URL is empty/nil
    end
  end

end # End Module LinkHelperUtils
