#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require_relative 'prepare_build'

# Compares production builds on a loaded host. Wall time on a shared machine
# varies by more than most optimizations save, so each run reports the CPU
# time of the Jekyll process (user + system), which other processes inflate
# far less, next to Jekyll's own compile time. Variants are environment
# assignments; runs alternate between variants so drift in host load affects
# each one equally. Every run prepares a fresh _site, as `make build` does.
# Run only through `make bench`.
module BuildBench
  COMMAND = %w[bundle exec jekyll build --config _config.yml,.jekyll-cache/production.yml].freeze
  COMPILE_TIME = /done in ([\d.]+) seconds/
  ASSIGNMENT = /\A[A-Z_][A-Z0-9_]*=/

  Sample = Struct.new(:cpu, :compile)

  # "A=1 B=2;A=0" => [{"A"=>"1", "B"=>"2"}, {"A"=>"0"}]. An empty list is
  # one variant with the inherited environment.
  def self.parse_variants(text)
    variants = text.to_s.split(';').map(&:strip).reject(&:empty?)
    return [{}] if variants.empty?

    variants.map do |variant|
      variant.split.to_h do |pair|
        raise ArgumentError, "Not an environment assignment: #{pair.inspect}" unless pair.match?(ASSIGNMENT)

        pair.split('=', 2)
      end
    end
  end

  def self.compile_seconds(output)
    match = output.match(COMPILE_TIME)
    raise "Build output has no compile time:\n#{output}" unless match

    match[1].to_f
  end

  def self.run_once(root, env, command)
    BuildCache.prepare(root, 'production')
    before = Process.times
    output, status = Open3.capture2e(env, *command, chdir: root)
    after = Process.times
    raise "Build failed (#{status}):\n#{output}" unless status.success?

    cpu = (after.cutime - before.cutime) + (after.cstime - before.cstime)
    Sample.new(cpu, compile_seconds(output))
  end

  def self.median(values)
    sorted = values.sort
    middle = sorted.length / 2
    sorted.length.odd? ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2.0
  end

  # Runs `warmup` unrecorded rounds, then `runs` recorded rounds. Each round
  # builds every variant once, rotating the starting variant.
  def self.measure(root, variants, runs:, warmup:, command: COMMAND, out: $stdout)
    samples = Array.new(variants.length) { [] }
    (warmup + runs).times do |round|
      variants.each_index.to_a.rotate(round).each do |index|
        sample = run_once(root, variants[index], command)
        recorded = round >= warmup
        samples[index] << sample if recorded
        name = recorded ? "run #{round - warmup + 1}" : 'warmup'
        out.puts "#{name.ljust(6)} #{label(variants[index]).ljust(30)} " \
                 "cpu #{seconds(sample.cpu)}  compile #{seconds(sample.compile)}"
      end
    end
    samples
  end

  def self.seconds(value)
    format('%<value>7.3f s', value: value)
  end

  def self.label(variant)
    variant.empty? ? '(inherited env)' : variant.map { |key, value| "#{key}=#{value}" }.join(' ')
  end

  # Medians per variant, plus each variant's median change against the
  # first variant in the same round. Runs in one round are adjacent, so the
  # paired change cancels drift that unpaired medians keep.
  def self.report(variants, samples, out: $stdout)
    out.puts "\nMedians over #{samples.first.length} runs:"
    base = samples.first.map(&:cpu)
    variants.zip(samples).each do |variant, runs|
      cpus = runs.map(&:cpu)
      paired = median(cpus.zip(base).map { |cpu, reference| ((cpu / reference) - 1) * 100 })
      out.puts "  #{label(variant).ljust(30)} cpu #{seconds(median(cpus))}  " \
               "compile #{seconds(median(runs.map(&:compile)))}  " \
               "paired cpu change #{format('%<pct>+6.1f%%', pct: paired)}"
    end
  end
end

if $PROGRAM_NAME == __FILE__
  variants = BuildBench.parse_variants(ENV.fetch('BENCH_VARIANTS', ''))
  runs = Integer(ENV.fetch('RUNS', '5'))
  warmup = Integer(ENV.fetch('WARMUP', '1'))
  samples = BuildBench.measure(Dir.pwd, variants, runs: runs, warmup: warmup)
  BuildBench.report(variants, samples)
end
