# _plugins/utils/citation_utils.rb
require 'cgi'

module CitationUtils
  NBSP = "\u00A0" # Non-breaking space

  # --- Public API ---
  def self.format_citation_html(params, _site = nil)
    part_generators = [
      lambda { _generate_author_part(last_name: params[:author_last], first_name: params[:author_first], handle: params[:author_handle]) },
      lambda { _generate_work_and_container_part(work_title: params[:work_title], container_title: params[:container_title], url: params[:url]) },
      lambda { _generate_editor_part(editor: params[:editor]) },
      lambda { _generate_edition_part(edition: params[:edition]) },
      lambda { _generate_volume_and_number_part(volume: params[:volume], number: params[:number]) },
      lambda { _generate_publisher_part(publisher: params[:publisher]) },
      lambda { _generate_date_part(date: params[:date]) },
      lambda { _generate_pages_part(first_page: params[:first_page], last_page: params[:last_page], page: params[:page]) },
      lambda { _generate_doi_part(doi: params[:doi]) },
      lambda { _generate_access_date_part(access_date: params[:access_date]) }
    ]

    # Generate all parts
    generated_parts = part_generators.map(&:call)

    # Sanitize: Remove nils, then remove trailing periods from each part, then reject empty strings
    active_parts = generated_parts.compact.map do |part_str|
      part_str.is_a?(String) ? part_str.chomp(".") : part_str
    end.reject { |p| !_present?(p) } # Use _present? to also catch strings that are just whitespace after chomp

    return "" if active_parts.empty?

    # Join active parts with ". " and add a single trailing period for the entire citation.
    final_citation_string = active_parts.join(". ") + "."

    "<span class=\"citation\">#{final_citation_string}</span>"
  end

  private

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
      if _present?(first_name)
        author_str_parts << _escapeHTML(first_name)
      end
      main_author_info = author_str_parts.join(", ")
      if _present?(handle)
        main_author_info += " (#{_escapeHTML(handle)})"
      end
      return main_author_info if _present?(main_author_info)
    elsif _present?(handle)
      return _escapeHTML(handle)
    end
    nil
  end

  def self._generate_work_and_container_part(work_title:, container_title:, url:)
    output_elements = []
    if _present?(work_title)
      work_formatted = ""
      if _present?(container_title)
        work_formatted = "\"#{_escapeHTML(work_title)}\""
      else
        work_formatted = "<cite>#{_escapeHTML(work_title)}</cite>"
      end
      if _present?(url)
        work_formatted = "<a href=\"#{url}\">#{work_formatted}</a>"
      end
      output_elements << work_formatted
    end
    if _present?(container_title)
      output_elements << "<cite>#{_escapeHTML(container_title)}</cite>"
    end
    return nil if output_elements.empty?
    output_elements.join(" ")
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
    vol_num_elements.join(", ")
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

  def self._generate_doi_part(doi:)
    return nil unless _present?(doi)
    "doi:#{NBSP}#{_escapeHTML(doi)}"
  end

  def self._generate_access_date_part(access_date:)
    return nil unless _present?(access_date)
    "Retrieved #{_escapeHTML(access_date)}"
  end
end
