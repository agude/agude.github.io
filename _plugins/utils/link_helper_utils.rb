# _plugins/utils/link_helper_utils.rb
require 'jekyll'
# Note: Does not require liquid_utils directly unless log_failure etc. were moved here

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
      display_text = override_text.strip # <-- Strip the override text here
    elsif found_doc && found_doc.data['title'] # Assumes canonical name is in 'title'
      canonical_title = found_doc.data['title'].strip
      # Use canonical title only if it's not empty after stripping
      display_text = canonical_title unless canonical_title.empty?
    end
    # Fallback is the stripped input_text if override is missing/empty
    # AND (doc not found OR doc title is missing/empty)
    display_text
  end

  # Generates the final HTML (<a> or just the inner element) based on whether the doc was found.
  # @param context [Liquid::Context] The current Liquid context.
  # @param found_doc [MockDocument, Jekyll::Document, Jekyll::Page, nil] The document if found.
  # @param inner_html_element [String] The pre-built inner HTML (e.g., <cite>...</cite>, <span>...</span>).
  # @return [String] The final HTML string (linked or unlinked).
  def self._generate_link_html(context, found_doc, inner_html_element)
    if found_doc
      target_url = found_doc.url
      page = context.registers[:page]
      site = context.registers[:site]
      current_page_url = page ? page['url'] : nil
      target_url_str = target_url.to_s # Ensure string

      # Link if target URL exists AND is not empty AND it's not the current page
      if target_url && !target_url_str.empty? && current_page_url && target_url != current_page_url
        baseurl = site.config['baseurl'] || ''
        # Ensure target_url starts with a slash if baseurl is present and url doesn't already have it
        target_url_str = "/#{target_url_str}" if !baseurl.empty? && !target_url_str.start_with?('/') && !target_url_str.start_with?(baseurl)
        "<a href=\"#{baseurl}#{target_url_str}\">#{inner_html_element}</a>"
      else
        inner_html_element # It's the current page, context/URL is missing, or URL is empty/nil
      end
    else
      inner_html_element # Doc not found, return unlinked inner element
    end
  end

end # End Module LinkHelperUtils
