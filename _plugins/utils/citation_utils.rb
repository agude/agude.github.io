# frozen_string_literal: true

# _plugins/utils/citation_utils.rb
require 'cgi'

module CitationUtils
  NBSP = "\u00A0" # Non-breaking space

  # --- Public API ---
  def self.format_citation_html(params, _site = nil)
    part_generators = [
      lambda {
        _generate_author_part(last_name: params[:author_last], first_name: params[:author_first],
                              handle: params[:author_handle])
      },
      lambda {
        _generate_work_and_container_part(work_title: params[:work_title], container_title: params[:container_title],
                                          url: params[:url])
      },
      -> { _generate_editor_part(editor: params[:editor]) },
      -> { _generate_edition_part(edition: params[:edition]) },
      -> { _generate_volume_and_number_part(volume: params[:volume], number: params[:number]) },
      -> { _generate_publisher_part(publisher: params[:publisher]) },
      -> { _generate_date_part(date: params[:date]) },
      lambda {
        _generate_pages_part(first_page: params[:first_page], last_page: params[:last_page], page: params[:page])
      },
      -> { _generate_doi_part(doi: params[:doi]) },
      -> { _generate_access_date_part(access_date: params[:access_date]) }
    ]

    # Generate all parts
    generated_parts = part_generators.map(&:call)

    # Sanitize: Remove nils, then remove trailing periods from each part, then reject empty strings
    active_parts = generated_parts.compact.map do |part_str|
      part_str.is_a?(String) ? part_str.chomp('.') : part_str
    end.select { |p| _present?(p) } # Use _present? to also catch strings that are just whitespace after chomp

    return '' if active_parts.empty?

    # Join active parts with ". " and add a single trailing period for the entire citation.
    final_citation_string = "#{active_parts.join('. ')}."

    "<span class=\"citation\">#{final_citation_string}</span>"
  end

  def self._present?(obj)
    !obj.nil? && !obj.to_s.strip.empty?
  end

  def self._escapeHTML(str)
    return nil unless _present?(str)

    CGI.escapeHTML(str.to_s)
  end

  # --- Independent Part Generators ---
  # These can now be slightly less strict about their own trailing periods,
  # as the main function will chomp them. However, best practice is still
  # for them to return raw content. This chomp is a safety net.

  def self._generate_author_part(last_name:, first_name:, handle:)
    author_str_parts = []
    if _present?(last_name)
      author_str_parts << _escapeHTML(last_name)
      author_str_parts << _escapeHTML(first_name) if _present?(first_name)
      main_author_info = author_str_parts.join(', ')
      main_author_info += " (#{_escapeHTML(handle)})" if _present?(handle)
      return main_author_info if _present?(main_author_info)
    elsif _present?(handle)
      return _escapeHTML(handle)
    end
    nil
  end

  def self._generate_work_and_container_part(work_title:, container_title:, url:)
    output_elements = []
    if _present?(work_title)
      work_formatted = if _present?(container_title)
                         "\"#{_escapeHTML(work_title)}\""
                       else
                         "<cite>#{_escapeHTML(work_title)}</cite>"
                       end
      work_formatted = "<a href=\"#{url}\">#{work_formatted}</a>" if _present?(url)
      output_elements << work_formatted
    end
    output_elements << "<cite>#{_escapeHTML(container_title)}</cite>" if _present?(container_title)
    return nil if output_elements.empty?

    output_elements.join(' ')
  end

  def self._generate_editor_part(editor:)
    return nil unless _present?(editor)

    "Edited by #{_escapeHTML(editor)}"
  end

  # With chomp, this can safely be "ed." or "ed"
  def self._generate_edition_part(edition:)
    return nil unless _present?(edition)

    "#{_escapeHTML(edition)} ed." # Chomp will handle the period if it's problematic
  end

  def self._generate_volume_and_number_part(volume:, number:)
    vol_num_elements = []
    vol_num_elements << "vol.#{NBSP}#{_escapeHTML(volume)}" if _present?(volume)
    vol_num_elements << "no.#{NBSP}#{_escapeHTML(number)}" if _present?(number)
    return nil if vol_num_elements.empty?

    vol_num_elements.join(', ')
  end

  def self._generate_publisher_part(publisher:)
    return nil unless _present?(publisher)

    _escapeHTML(publisher)
  end

  def self._generate_date_part(date:)
    return nil unless _present?(date)

    _escapeHTML(date)
  end

  def self._generate_pages_part(first_page:, last_page:, page:)
    if _present?(first_page)
      pg_str = "pp.#{NBSP}#{_escapeHTML(first_page)}"
      pg_str += "--#{_escapeHTML(last_page)}" if _present?(last_page)
      return pg_str
    elsif _present?(page)
      return "p.#{NBSP}#{_escapeHTML(page)}"
    end
    nil
  end

  # Generates the DOI part of a citation, linking it if possible.
  # Handles three cases:
  # 1. Input is a DOI slug (e.g., "10.1234/abc.123").
  # 2. Input is a full DOI URL (e.g., "https://doi.org/10.1234/abc.123").
  # 3. Input is other text (fallback, not linked as a DOI).
  #
  # @param doi [String, nil] The raw DOI string or DOI URL from parameters.
  # @return [String, nil] The formatted DOI string (possibly linked), or nil if input is blank.
  def self._generate_doi_part(doi:)
    # Use _present? to check if the input 'doi' has meaningful content.
    return nil unless _present?(doi)

    # Convert to string and strip, as _present? already confirmed it's not just whitespace.
    doi_input_str = doi.to_s.strip

    doi_slug_to_link = nil
    doi_url_prefix = 'https://doi.org/'

    # Case 1: Input is likely a DOI slug (starts with "10.")
    # We also need to ensure it's not part of a common non-DOI string that happens to start with "10."
    # A simple check for a slash is a good heuristic for DOI slugs.
    if doi_input_str.start_with?('10.') && doi_input_str.include?('/')
      doi_slug_to_link = doi_input_str
      # Case 2: Input is likely a full DOI URL
    elsif doi_input_str.downcase.include?('doi.org/')
      # Regex: case insensitive, matches "doi.org/" followed by (capturing group for "10." followed by anything non-empty up to a space or end)
      match = doi_input_str.match(%r{doi\.org/(10\.[^\s]+)$}i)
      if match && _present?(match[1]) # Check if the captured group is present and not empty
        doi_slug_to_link = match[1] # This is the extracted slug, e.g., "10.1234/whatever"
      end
    end

    # If a valid-looking DOI slug was identified (either directly or extracted)
    return "doi:#{NBSP}#{_escapeHTML(doi_input_str)}" unless _present?(doi_slug_to_link)

    # Validate the slug further if needed (e.g., more complex regex for DOI structure)
    # For now, we assume if it starts with "10." and contains '/', it's a candidate.

    # Text to display for the link (the slug itself, HTML escaped)
    escaped_slug_for_display = _escapeHTML(doi_slug_to_link)

    # URL for the href attribute (raw, unescaped slug)
    # Ensure no double escaping if the slug itself had % encoding, though doi.org handles this well.
    full_doi_url_for_href = "#{doi_url_prefix}#{doi_slug_to_link}"

    "doi:#{NBSP}<a href=\"#{full_doi_url_for_href}\">#{escaped_slug_for_display}</a>"

    # Case 3: Fallback - input is not a recognized DOI slug or linkable DOI URL.
    # Output the original input (HTML escaped), prefixed with "doi: ".
  end

  def self._generate_access_date_part(access_date:)
    return nil unless _present?(access_date)

    "Retrieved #{_escapeHTML(access_date)}"
  end
end
