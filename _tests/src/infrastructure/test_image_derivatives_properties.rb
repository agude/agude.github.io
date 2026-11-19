# frozen_string_literal: true

require 'test_helper'
require 'support/property_test'
require 'digest'
require 'fileutils'
require 'json'
require 'tmpdir'
require 'src/infrastructure/image_derivatives'
require_relative '../../support/image_fixture'

# Model-based sequences of source, width, output, and manifest changes, each
# followed by a build. ImageDerivatives encodes through a stub, so no
# ImageMagick runs. The model is interpreted here, not by ImageDerivatives.
class TestImageDerivativesProperties < Minitest::Test
  include PropertyTestSupport

  Derivatives = Jekyll::Infrastructure::ImageDerivatives
  G = PropCheck::Generators

  # Reference model of the state a build depends on: the source files, the
  # requested widths, which output files exist, and what the manifest holds.
  # It writes its own paths and keys, and it takes digests from the bytes the
  # test writes, not from ImageDerivatives.
  class Model
    NAMES = %w[a b c].freeze
    WIDTH_SETS = [[250], [500], [250, 500]].freeze
    INITIAL_WIDTHS = [250, 500].freeze
    # Width and tag are the content. Both 1000 px variants share a size, so
    # changing between them is a same-size content change. 500 equals a
    # requested width, so that output is skipped.
    VARIANTS = [
      { width: 1000, height: 1500, tag: 'wide' },
      { width: 1000, height: 1500, tag: 'wide-edited' },
      { width: 300, height: 450, tag: 'narrow' },
      { width: 500, height: 750, tag: 'exact' },
    ].freeze
    # Not JSON, so the manifest reads as empty.
    CORRUPT_MANIFEST = '{"truncated": '

    # A JPEG header from ImageFixture, plus a COM segment that carries the
    # tag, so variants of one size differ in bytes.
    def self.image_bytes(variant)
      spec = VARIANTS.fetch(variant)
      body = ImageFixture.jpeg(spec.fetch(:width), spec.fetch(:height))
      comment = "tag=#{spec.fetch(:tag)}".b
      segment = [0xFF, 0xFE, comment.bytesize + 2].pack('CCn') + comment
      body.delete_suffix("\xFF\xD9".b) + segment + "\xFF\xD9".b
    end

    def self.digest(variant)
      Digest::SHA256.hexdigest(image_bytes(variant))
    end

    # @return [Array(Array<String>, Array<String>)] Interactions that each
    #   operation exercises, in order, without touching the filesystem.
    def self.interactions(ops)
      model = new
      ops.flat_map { |operation| model.apply(operation).last }
    end

    attr_reader :files, :manifest

    def initialize
      @present = {}
      @history = Hash.new { |hash, name| hash[name] = [] }
      @removed = Set.new
      @widths = INITIAL_WIDTHS
      # Relative cache path => key of the encoding that wrote it.
      @files = {}
      # nil when absent, :corrupt when unreadable, else Hash of relative path => key.
      @manifest = nil
      @last_kind = nil
      # True after a failed build until the next successful build.
      @pending_failure = false
    end

    # @return [Array(Hash, Array<String>)] The filesystem action (or nil),
    #   and the interactions the operation exercises.
    def apply(operation)
      result = case operation.fetch(:kind)
               when :build then build
               when :build_fails then build_fails(operation)
               when :change then change(operation)
               when :restore then restore(operation)
               when :delete_output then delete_output(operation)
               when :delete_manifest then delete_manifest
               when :corrupt_manifest then corrupt_manifest
               when :change_widths then change_widths(operation)
               when :remove_source then remove_source(operation)
               when :add_source then add_source(operation)
               else raise ArgumentError, "unknown operation #{operation.inspect}"
               end
      # A build_fails that finds nothing stale succeeds as a build.
      succeeded_build = result.first && result.first[:kind] == :build
      @last_kind = succeeded_build ? :build : operation.fetch(:kind)
      result
    end

    private

    def build
      planned = planned_outputs
      names = []
      names << 'warm_rebuild_no_change' if @last_kind == :build && !planned.empty?

      base = @manifest.is_a?(Hash) ? @manifest : {}
      stale = planned.reject { |output| @files.key?(output[:rel]) && base[output[:rel]] == output[:key] }
      names << 'encode_failed_then_rebuilt' if @pending_failure && !stale.empty?
      @pending_failure = false
      unless stale.empty?
        stale.each { |output| @files[output[:rel]] = output[:key] }
        @manifest = base.merge(stale.to_h { |output| [output[:rel], output[:key]] })
      end

      action = {
        kind: :build,
        widths: @widths.dup,
        expected: relatives(stale),
        written: relatives(stale),
        srcset_names: planned.map { |output| output[:name] }.uniq.sort,
        files: @files.keys.sort,
        manifest: manifest_snapshot,
      }
      [action, names]
    end

    # A build whose encode_all fails. As in production, the groups the mask
    # selects (one per source, in sorted order) finish and write their files,
    # then the build raises. The manifest is not written.
    def build_fails(operation)
      planned = planned_outputs
      names = []
      names << 'warm_rebuild_no_change' if @last_kind == :build && !planned.empty?

      base = @manifest.is_a?(Hash) ? @manifest : {}
      stale = planned.reject { |output| @files.key?(output[:rel]) && base[output[:rel]] == output[:key] }
      return build_without_failure(planned, names) if stale.empty?

      groups = stale.map { |output| output[:name] }.uniq.sort
      chosen = groups.each_with_index.select { |_name, index| operation.fetch(:mask)[index] == 1 }.map(&:first)
      written = stale.select { |output| chosen.include?(output[:name]) }
      written.each { |output| @files[output[:rel]] = output[:key] }
      @pending_failure = true

      action = {
        kind: :build_fails,
        widths: @widths.dup,
        expected: relatives(stale),
        written: relatives(written),
        srcset_names: [],
        files: @files.keys.sort,
        manifest: manifest_snapshot,
      }
      [action, names]
    end

    # build_fails with nothing stale encodes nothing, so it succeeds.
    def build_without_failure(planned, names)
      @pending_failure = false
      action = {
        kind: :build,
        widths: @widths.dup,
        expected: [],
        written: [],
        srcset_names: planned.map { |output| output[:name] }.uniq.sort,
        files: @files.keys.sort,
        manifest: manifest_snapshot,
      }
      [action, names]
    end

    def relatives(outputs)
      outputs.map { |output| output[:rel] }.sort
    end

    def manifest_snapshot
      @manifest.is_a?(Hash) ? @manifest.dup : @manifest
    end

    # One entry per output a build plans: a requested width below the
    # original's width, for every present source.
    def planned_outputs
      @present.sort.flat_map do |name, variant|
        original_width = VARIANTS.fetch(variant).fetch(:width)
        @widths.select { |width| width < original_width }.map do |width|
          {
            name: name,
            rel: "books/covers/derived/#{name}-#{width}.webp",
            key: "#{self.class.digest(variant)} #{width} #{Derivatives::SETTINGS}",
          }
        end
      end
    end

    def change(operation)
      name = pick_name(operation[:pick], @present.keys)
      return [nil, []] unless name

      old = @present.fetch(name)
      names = []
      names << 'same_size_content_change' if old != operation[:variant] && same_size?(old, operation[:variant])
      [set_content(name, operation[:variant]), names]
    end

    # Writes an earlier version of a present source, not its current one.
    def restore(operation)
      name = pick_name(operation[:pick], @present.keys)
      return [nil, []] unless name

      current = @present.fetch(name)
      earlier = @history[name].uniq.reject { |variant| variant == current }
      return [nil, []] if earlier.empty?

      [set_content(name, earlier[operation[:history] % earlier.size]), ['content_restored']]
    end

    def delete_output(operation)
      rels = @files.keys.sort
      return [nil, []] if rels.empty?

      rel = rels[operation[:pick] % rels.size]
      @files.delete(rel)
      [{ kind: :delete_output, rel: rel }, ['output_deleted']]
    end

    def delete_manifest
      return [nil, []] if @manifest.nil?

      @manifest = nil
      [{ kind: :delete_manifest }, ['manifest_deleted']]
    end

    def corrupt_manifest
      @manifest = :corrupt
      [{ kind: :corrupt_manifest }, ['manifest_corrupted']]
    end

    def change_widths(operation)
      widths = WIDTH_SETS[operation[:pick] % WIDTH_SETS.size]
      names = []
      names << 'width_added' unless (widths - @widths).empty?
      names << 'width_removed' unless (@widths - widths).empty?
      @widths = widths
      [nil, names]
    end

    def remove_source(operation)
      name = pick_name(operation[:pick], @present.keys)
      return [nil, []] unless name

      @present.delete(name)
      @removed << name
      [{ kind: :remove_source, name: name }, []]
    end

    def add_source(operation)
      name = pick_name(operation[:pick], NAMES - @present.keys)
      return [nil, []] unless name

      names = @removed.include?(name) ? ['source_removed_then_readded'] : []
      [set_content(name, operation[:variant]), names]
    end

    def set_content(name, variant)
      @present[name] = variant
      @history[name] << variant
      { kind: :write_source, name: name, variant: variant }
    end

    def same_size?(old, new)
      VARIANTS.fetch(old).fetch(:width) == VARIANTS.fetch(new).fetch(:width)
    end

    def pick_name(pick, names)
      sorted = names.sort
      sorted[pick % sorted.size] unless sorted.empty?
    end
  end

  INTERACTIONS = %w[
    warm_rebuild_no_change
    same_size_content_change
    content_restored
    output_deleted
    manifest_deleted
    manifest_corrupted
    width_added
    width_removed
    source_removed_then_readded
    encode_failed_then_rebuilt
  ].freeze

  def test_property_build_reencodes_exactly_the_stale_outputs
    check_property(
      operation_sequence_generator,
      seed: 7101,
      classify: ->(ops) { Model.interactions(ops) },
      interactions: INTERACTIONS,
    ) do |ops|
      run_sequence(ops)
    end
  end

  private

  def operation_sequence_generator
    G.array(operation_generator, min: 1, max: 12)
  end

  # Picks are reduced modulo the current state, so a generated operation
  # applies to whatever sources, outputs, or widths exist when it runs.
  def operation_generator
    pick = G.choose(0..9)
    G.one_of(
      G.constant({ kind: :build }),
      G.constant({ kind: :build }),
      G.choose(0..7).map { |mask| { kind: :build_fails, mask: mask } },
      G.tuple(pick, G.choose(0..3)).map { |p, variant| { kind: :change, pick: p, variant: variant } },
      G.tuple(pick, pick).map { |p, history| { kind: :restore, pick: p, history: history } },
      pick.map { |p| { kind: :delete_output, pick: p } },
      G.constant({ kind: :delete_manifest }),
      G.constant({ kind: :corrupt_manifest }),
      G.choose(0..2).map { |p| { kind: :change_widths, pick: p } },
      pick.map { |p| { kind: :remove_source, pick: p } },
      G.tuple(pick, G.choose(0..3)).map { |p, variant| { kind: :add_source, pick: p, variant: variant } },
    )
  end

  # Runs one generated sequence in a fresh temporary source directory.
  def run_sequence(ops)
    Dir.mktmpdir('image-derivatives-property') do |root|
      FileUtils.mkdir_p(File.join(root, 'books', 'covers'))
      model = Model.new
      ops.each do |operation|
        action, = model.apply(operation)
        perform(root, action) if action
      end
    end
  end

  def perform(root, action)
    case action.fetch(:kind)
    when :write_source
      File.binwrite(source_path(root, action.fetch(:name)), Model.image_bytes(action.fetch(:variant)))
    when :remove_source
      FileUtils.rm(source_path(root, action.fetch(:name)))
    when :delete_output
      FileUtils.rm(File.join(root, Derivatives::CACHE_DIR, action.fetch(:rel)))
    when :delete_manifest
      FileUtils.rm(manifest_path(root))
    when :corrupt_manifest
      FileUtils.mkdir_p(File.join(root, Derivatives::CACHE_DIR))
      File.write(manifest_path(root), Model::CORRUPT_MANIFEST)
    when :build, :build_fails
      check_build(root, action)
    end
  end

  # Runs one build with encode_all stubbed. The stub writes the outputs the
  # model names as written, then raises for a failing build, as production
  # does when a group raises after the others have finished.
  def check_build(root, action)
    Jekyll::Infrastructure::ImageDimensions.reset
    test_site = create_site({ 'source' => root, 'image_derivatives' => [spec(action.fetch(:widths))] })
    received = []
    written = action.fetch(:written)
    encoder = lambda do |outputs|
      outputs.each do |output|
        rel = relative_to_cache(root, output.cache_file)
        received << rel
        next unless written.include?(rel)

        FileUtils.mkdir_p(File.dirname(output.cache_file))
        File.binwrite(output.cache_file, 'placeholder')
      end
      next unless action.fetch(:kind) == :build_fails

      raise Jekyll::Errors::FatalException, 'ImageDerivatives: stub encode failed.'
    end
    run = lambda do
      Derivatives.stub(:imagemagick, -> { flunk 'ImageMagick must not run in this property' }) do
        Derivatives.stub(:encode_all, encoder) { Derivatives.build(test_site) }
      end
    end

    srcsets = if action.fetch(:kind) == :build_fails
                assert_raises(Jekyll::Errors::FatalException, &run)
              else
                run.call
              end

    assert_equal action.fetch(:expected), received.sort, 'encode_all was given outputs other than the stale set'
    if action.fetch(:kind) == :build
      expected_srcsets = action.fetch(:srcset_names).map { |name| "/books/covers/#{name}.jpg" }
      assert_equal expected_srcsets, srcsets.keys.sort, 'srcset entries differ from the planned outputs'
    end
    cache_root = File.join(root, Derivatives::CACHE_DIR)
    on_disk = Dir.glob('**/*.webp', base: cache_root).sort
    assert_equal action.fetch(:files), on_disk, 'cache files on disk differ from the model'
    check_manifest(root, action.fetch(:manifest))
  end

  def check_manifest(root, expected)
    case expected
    when nil
      refute File.exist?(manifest_path(root)), 'manifest exists, but the model has none'
    when :corrupt
      assert_equal Model::CORRUPT_MANIFEST, File.read(manifest_path(root)), 'manifest was rewritten unexpectedly'
    else
      written = JSON.parse(File.read(manifest_path(root)))
      relative = written.to_h { |key, value| [relative_to_cache(root, key), value] }
      assert_equal expected, relative, 'manifest differs from the model'
    end
  end

  def spec(widths)
    { 'source_dir' => 'books/covers', 'widths' => widths, 'sizes' => '250px' }
  end

  def source_path(root, name)
    File.join(root, 'books', 'covers', "#{name}.jpg")
  end

  def manifest_path(root)
    File.join(root, Derivatives::CACHE_DIR, Derivatives::MANIFEST)
  end

  def relative_to_cache(root, path)
    path.delete_prefix("#{File.join(root, Derivatives::CACHE_DIR)}/")
  end
end
