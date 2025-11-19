# frozen_string_literal: true

# _plugins/utils/citation_utils.rb
require 'cgi'

module CitationUtils
  NBSP = "\u00A0" # Non-breaking space

  # --- Public API ---
  def self.format_citation_html(params, _site = nil)
    # Generate all parts
    generated_parts = _build_generators(params).map(&:call)

    # Sanitize: Remove nils, then remove trailing periods from each part, then reject empty strings
    active_parts = generated_parts.compact.map do |part_str|
      part_str.is_a?(String) ? part_str.chomp('.') : part_str
    end.select { |p| _present?(p) } # Use _present? to also catch strings that are just whitespace after chomp

    return '' if active_parts.empty?

    # Join active parts with ". " and add a single trailing period for the entire citation.
    final_citation_string = "#{active_parts.join('. ')}."

    "<span class=\"citation\">#{final_citation_string}</span>"
  end

  def self._build_generators(params)
    [
      -> { _generate_author_part(last: params[:author_last], first: params[:author_first], handle: params[:author_handle]) },
      lambda {
        _generate_work_and_container_part(work: params[:work_title], container: params[:container_title],
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
  end

  def self._present?(obj)
    !obj.nil? && !obj.to_s.strip.empty?
  end

  def self._escape_html(str)
    return nil unless _present?(str)

    CGI.escapeHTML(str.to_s)
  end

  # --- Independent Part Generators ---

  def self._generate_author_part(last:, first:, handle:)
    parts = []
    if _present?(last)
      parts << _escape_html(last)
      parts << _escape_html(first) if _present?(first)
      main = parts.join(', ')
      main += " (#{_escape_html(handle)})" if _present?(handle)
      return main if _present?(main)
    elsif _present?(handle)
      return _escape_html(handle)
    end
    nil
  end

  def self._generate_work_and_container_part(work:, container:, url:)
    elements = []
    if _present?(work)
      fmt = _present?(container) ? "\"#{_escape_html(work)}\"" : "<cite>#{_escape_html(work)}</cite>"
      fmt = "<a href=\"#{url}\">#{fmt}</a>" if _present?(url)
      elements << fmt
    end
    elements << "<cite>#{_escape_html(container)}</cite>" if _present?(container)
    return nil if elements.empty?

    elements.join(' ')
  end

  def self._generate_editor_part(editor:)
    return nil unless _present?(editor)

    "Edited by #{_escape_html(editor)}"
  end

  def self._generate_edition_part(edition:)
    return nil unless _present?(edition)

    "#{_escape_html(edition)} ed."
  end

  def self._generate_volume_and_number_part(volume:, number:)
    elements = []
    elements << "vol.#{NBSP}#{_escape_html(volume)}" if _present?(volume)
    elements << "no.#{NBSP}#{_escape_html(number)}" if _present?(number)
    return nil if elements.empty?

    elements.join(', ')
  end

  def self._generate_publisher_part(publisher:)
    return nil unless _present?(publisher)

    _escape_html(publisher)
  end

  def self._generate_date_part(date:)
    return nil unless _present?(date)

    _escape_html(date)
  end

  def self._generate_pages_part(first_page:, last_page:, page:)
    if _present?(first_page)
      pg_str = "pp.#{NBSP}#{_escape_html(first_page)}"
      pg_str += "--#{_escape_html(last_page)}" if _present?(last_page)
      return pg_str
    elsif _present?(page)
      return "p.#{NBSP}#{_escape_html(page)}"
    end
    nil
  end

  def self._generate_doi_part(doi:)
    return nil unless _present?(doi)

    input = doi.to_s.strip
    slug = _extract_doi_slug(input)

    return "doi:#{NBSP}#{_escape_html(input)}" unless _present?(slug)

    display = _escape_html(slug)
    url = "https://doi.org/#{slug}"
    "doi:#{NBSP}<a href=\"#{url}\">#{display}</a>"
  end

  def self._extract_doi_slug(input)
    if input.start_with?('10.') && input.include?('/')
      input
    elsif input.downcase.include?('doi.org/')
      match = input.match(%r{doi\.org/(10\.[^\s]+)$}i)
      match && _present?(match[1]) ? match[1] : nil
    end
  end

  def self._generate_access_date_part(access_date:)
    return nil unless _present?(access_date)

    "Retrieved #{_escape_html(access_date)}"
  end
end
