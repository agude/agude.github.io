# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../_bin/bench_build'
require 'stringio'
require 'tmpdir'

# The benchmark must alternate variants, record only post-warmup runs, and
# stop on a build it cannot measure.
class TestBenchBuild < Minitest::Test
  def setup
    @root = Dir.mktmpdir('bench-build')
    %w[Gemfile.lock Dockerfile .ruby-version _config.yml].each { |path| File.write(File.join(@root, path), 'x') }
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  # Prints a compile time and appends the variant's MARK to a log.
  def fake_build(log)
    ['ruby', '-e', "File.write(#{log.inspect}, ENV.fetch('MARK', '-'), mode: 'a'); puts 'done in 1.5 seconds.'"]
  end

  def test_parse_variants
    assert_equal [{}], BuildBench.parse_variants('')
    assert_equal [{ 'A' => '1', 'B' => 'x=y' }, { 'A' => '0' }], BuildBench.parse_variants('A=1 B=x=y; A=0;')
    assert_raises(ArgumentError) { BuildBench.parse_variants('yjit') }
  end

  def test_median
    assert_in_delta 2.0, BuildBench.median([3.0, 1.0, 2.0])
    assert_in_delta 2.5, BuildBench.median([4.0, 1.0, 2.0, 3.0])
  end

  def test_measure_alternates_variants_and_discards_warmup
    log = File.join(@root, 'log')
    variants = [{ 'MARK' => 'a' }, { 'MARK' => 'b' }]
    out = StringIO.new
    samples = BuildBench.measure(@root, variants, runs: 2, warmup: 1, command: fake_build(log), out: out)

    assert_equal 'abbaab', File.read(log)
    assert_equal [2, 2], samples.map(&:length)
    assert(samples.flatten.all? { |sample| (sample.compile - 1.5).abs < 1e-9 && sample.cpu.positive? })
    BuildBench.report(variants, samples, out: out)

    assert_includes out.string, 'MARK=b'
  end

  def test_report_pairs_each_round_with_the_first_variant
    samples = [[10.0, 20.0, 30.0], [9.0, 28.0, 27.0]].map { |cpus| cpus.map { |cpu| BuildBench::Sample.new(cpu, cpu) } }
    out = StringIO.new
    BuildBench.report([{ 'A' => '0' }, { 'A' => '1' }], samples, out: out)

    # Paired changes are -10%, +40%, -10%; the unpaired medians differ by +35%.
    assert_match(/A=1 .*paired cpu change\s+-10\.0%/, out.string)
    assert_match(/A=0 .*paired cpu change\s+\+0\.0%/, out.string)
  end

  def test_measure_prepares_a_fresh_site_each_run
    FileUtils.mkdir_p(File.join(@root, '_site'))
    File.write(File.join(@root, '_site', 'stale'), 'x')
    BuildBench.measure(@root, [{}], runs: 1, warmup: 0, command: fake_build(File.join(@root, 'log')), out: StringIO.new)

    refute_path_exists File.join(@root, '_site', 'stale')
  end

  def test_build_without_compile_time_raises
    error = assert_raises(RuntimeError) do
      BuildBench.measure(@root, [{}], runs: 1, warmup: 0, command: ['ruby', '-e', 'puts 1'], out: StringIO.new)
    end
    assert_includes error.message, 'no compile time'
  end

  def test_failed_build_raises
    assert_raises(RuntimeError) do
      BuildBench.measure(@root, [{}], runs: 1, warmup: 0, command: ['ruby', '-e', 'exit 1'], out: StringIO.new)
    end
  end
end
