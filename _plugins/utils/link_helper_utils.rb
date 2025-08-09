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

    # Handle invalid target URL
    return inner_html_element if target_url_str.empty?

    # --- Smarter link generation logic ---
    target_parts = target_url_str.split('#', 2)
    target_base_url = target_parts[0]
    target_fragment = target_parts[1] # This will be nil if no '#'

    # Case 1: The link is to a different page. Generate a full link.
    if target_base_url != current_page_url
      baseurl = site.config['baseurl'] || ''
      href = target_url_str
      if !baseurl.empty? && !href.start_with?('/') && !href.start_with?(baseurl)
        href = "/#{href}"
      end
      href = href.start_with?(baseurl) ? href : "#{baseurl}#{href}"
      "<a href=\"#{href}\">#{inner_html_element}</a>"

      # Case 2: The link is to an anchor on the *same* page. Generate a relative anchor link.
    elsif target_fragment
      "<a href=\"##{target_fragment}\">#{inner_html_element}</a>"

      # Case 3: The link is to the same page with no anchor (a true self-link). Suppress it.
    else
      inner_html_element
    end
  end

end # End Module LinkHelperUtils
