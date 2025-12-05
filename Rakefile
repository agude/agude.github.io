# frozen_string_literal: true

# Rakefile

require 'json'
require 'pathname'

# --- Helper Methods for Coverage Summary ---

# Groups an array of numbers into strings representing consecutive ranges.
# Example: [2, 3, 4, 8, 10, 11] -> ["2-4", "8", "10-11"]
def group_consecutive_numbers(numbers)
  return [] if numbers.empty?

  ranges = []
  current_range = [numbers.first]
  sorted_numbers = numbers.uniq.sort

  sorted_numbers.each_cons(2) do |a, b|
    if b == a + 1
      current_range << b
    else
      ranges << format_range(current_range)
      current_range = [b]
    end
  end
  ranges << format_range(current_range)
  ranges
end

# Formats an array representing a range into a string.
# Example: [2, 3, 4] -> "2-4"; [8] -> "8"
def format_range(range)
  range.length > 2 ? "#{range.first}-#{range.last}" : range.uniq.join(', ')
end

# Parses the 'branches' hash from SimpleCov's JSON output to find untested code paths.
def find_uncovered_branches(branches_data)
  uncovered = []
  return uncovered if branches_data.nil? || branches_data.empty?

  branches_data.each do |branch_key, paths|
    # Parse the branch key to extract type and line number
    # Format: '[:if, 0, 36, 6, 36, 79]' where the 4th element is the line number
    branch_parts = branch_key.scan(/:\w+|\d+/)
    branch_type = branch_parts[0]&.sub(':', '') || 'unknown'
    line = branch_parts[2] || 'unknown'

    paths.each do |path_key, count|
      next unless count.zero?

      path_parts = path_key.scan(/:\w+/)
      path_type = path_parts[0]&.sub(':', '') || 'unknown'
      uncovered << "#{branch_type} on line #{line}: '#{path_type}' path not taken."
    end
  end
  uncovered
end

# --- Rake Tasks ---

namespace :coverage do
  desc 'Generate a summary of files with less than 100% test coverage.'
  task :summary do
    json_path = Pathname.new('coverage/coverage.json')
    output_path = Pathname.new('coverage/coverage_summary.txt')

    abort "Error: Coverage report not found at #{json_path}. Run 'make coverage' first." unless json_path.exist?

    report = JSON.parse(File.read(json_path))
    files_data = report['files']
    # Use the 'pwd' from metadata to correctly calculate relative paths.
    # If metadata.pwd is not available, fall back to the current directory.
    pwd_from_report = report.dig('metadata', 'pwd')
    project_root = Pathname.new(pwd_from_report || Dir.pwd)

    summary_lines = []

    # Filter for files that are under 100% coverage and are part of our source code.
    under_covered_files = files_data.select do |file|
      file['covered_percent'] < 100 && file['filename'].start_with?(project_root.join('_plugins').to_s)
    end

    if under_covered_files.empty?
      summary_lines << 'All tracked files have 100% test coverage.'
    else
      summary_lines << 'Coverage Summary:'
      # Sort files alphabetically for a consistent report.
      sorted_files = under_covered_files.sort_by { |file| file['filename'] }

      sorted_files.each do |file_data|
        relative_path = Pathname.new(file_data['filename']).relative_path_from(project_root).to_s
        coverage_percent = file_data['covered_percent'].round(2)
        summary_lines << "\nFile: #{relative_path} (Coverage: #{coverage_percent}%)"

        # Find and list uncovered lines.
        uncovered_lines = []
        coverage_lines = file_data.dig('coverage', 'lines') || file_data['coverage']
        coverage_lines.each_with_index do |coverage_count, index|
          uncovered_lines << (index + 1) if coverage_count&.zero?
        end

        unless uncovered_lines.empty?
          summary_lines << '  Uncovered Lines:'
          group_consecutive_numbers(uncovered_lines).each do |range_str|
            summary_lines << "  - #{range_str}"
          end
        end

        # Find and list uncovered branches.
        branches_data = file_data.dig('coverage', 'branches') || file_data['branches']
        uncovered_branches = find_uncovered_branches(branches_data)
        next if uncovered_branches.empty?

        summary_lines << '  Uncovered Branches:'
        uncovered_branches.each do |branch_info|
          summary_lines << "  - #{branch_info}"
        end
      end
    end

    # Write the summary to the output file.
    output_path.dirname.mkpath
    File.write(output_path, "#{summary_lines.join("\n")}\n")
    puts "Coverage summary written to #{output_path}"
  end
end
