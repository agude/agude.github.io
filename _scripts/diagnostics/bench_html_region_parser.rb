# frozen_string_literal: true

# Benchmark for Jekyll::Infrastructure::MarkdownHtmlRegionParser.protected_ranges.
#
# This is a benchmark, not a test. It builds Markdown with N repeated
# `<div class="note">` regions for N in SIZES, times protected_ranges on each
# input, and prints the median time per N and the ratio to the previous N.
# A returned range count other than N means the timing does not cover the
# expected work, and the script exits with status 1.
#
# Method: one warm-up call per N (its time is discarded), then REPETITIONS
# timed calls. The median of the timed calls is reported. This file loads only
# the parser; it does not load SimpleCov or _tests/test_helper.rb.
#
# Run from the repository root with the Jekyll image (run `make image-build`
# first if the image is missing):
#   docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -v "$PWD":/workspace \
#     -w /workspace jekyll-image-agude ruby _scripts/diagnostics/bench_html_region_parser.rb
#
# Timings depend on host load. Compare ratios across runs rather than absolute
# values.

require_relative '../../_plugins/src/infrastructure/markdown_html_region_parser'

# Times MarkdownHtmlRegionParser.protected_ranges on synthetic Markdown.
module BenchHtmlRegionParser
  # Number of repeated regions per input.
  SIZES = [25, 50, 100, 200].freeze
  # Timed calls per size, after one discarded warm-up call.
  REPETITIONS = 5
  HEADER_FORMAT = '%<count>-6s %<median>-14s %<ratio>-14s %<ranges>-16s %<check>s'
  ROW_FORMAT = '%<count>-6d %<median>-14.6f %<ratio>-14s %<ranges>-16s %<check>s'

  module_function

  def build_markdown(count)
    (0...count).map do |i|
      "Paragraph #{i} with *emphasis*.\n\n<div class=\"note\">\nInner text #{i}.\n</div>\n\n"
    end.join
  end

  # Returns [elapsed_seconds, number_of_ranges].
  def time_once(markdown)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    ranges = Jekyll::Infrastructure::MarkdownHtmlRegionParser.protected_ranges(markdown)
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    [elapsed, ranges.length]
  end

  def median(values)
    sorted = values.sort
    sorted[sorted.length / 2]
  end

  def measure(count)
    markdown = build_markdown(count)
    all = Array.new(REPETITIONS + 1) { time_once(markdown) }
    timed = all.drop(1) # The first call is the warm-up and is not timed.
    {
      count: count,
      median: median(timed.map(&:first)),
      ranges: all.map(&:last).uniq,
      ok: all.all? { |_elapsed, found| found == count },
    }
  end

  def print_table(rows)
    header = {
      count: 'N',
      median: 'median_s',
      ratio: 'ratio_to_prev',
      ranges: 'ranges_returned',
      check: 'ranges_eq_N',
    }
    puts format(HEADER_FORMAT, header)
    rows.each do |row|
      line = {
        count: row[:count],
        median: row[:median],
        ratio: row[:ratio] ? format('%.2f', row[:ratio]) : '-',
        ranges: row[:ranges].join(','),
        check: row[:ok] ? 'yes' : 'NO',
      }
      puts format(ROW_FORMAT, line)
    end
  end

  def run
    rows = []
    SIZES.each do |count|
      row = measure(count)
      previous = rows.last
      row[:ratio] = previous ? row[:median] / previous[:median] : nil
      rows << row
    end
    print_table(rows)
    rows.all? { |row| row[:ok] }
  end
end

exit(BenchHtmlRegionParser.run ? 0 : 1)
