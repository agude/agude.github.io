# frozen_string_literal: true

require 'digest'
require 'etc'
require 'fileutils'
require 'json'
require 'jekyll'
require 'open3'
require_relative 'front_matter_image'
require_relative 'image_dimensions'
require_relative 'local_image'

module Jekyll
  module Infrastructure
    # Builds smaller WebP copies of configured images and publishes them,
    # so pages can offer them through `srcset` instead of the full-size
    # originals.
    #
    # Configuration (`_config.yml`), one entry per image set:
    #
    #   image_derivatives:
    #     - source_dir: books/covers   # every image in a directory
    #       widths: [300, 600]         # output widths in pixels
    #       sizes: 300px               # the `sizes` value pages use
    #     - front_matter: posts        # the `image` of every post
    #       widths: [300, 600]
    #       sizes: 800px
    #
    # A `source_dir` must hold only JPEGs and PNGs. A `front_matter` entry
    # names a collection; each document's front-matter `image` must be a
    # local JPEG or PNG, or an SVG, which needs no copies and is skipped.
    # Extensions must be lowercase (`.jpg`, `.jpeg`, `.png`, `.svg`): the CI
    # cache key hashes `files/**/*.jpg` and the like, and that glob is
    # case-sensitive, so a `.JPG` source would never refresh the cache.
    # Post images share directories with plots and data files, which is why
    # they are listed by front matter rather than by directory.
    #
    # With no `image_derivatives` key nothing is generated, and
    # ImageDimensionsInjector adds no `srcset`.
    #
    # Outputs for `books/covers/dune.jpg` are `books/covers/derived/dune-300.webp`
    # and `dune-600.webp`. A width at or above the original's is skipped;
    # the original then joins the `srcset` at its own width, so a 2x screen
    # never gets an upscaled or too-small copy.
    #
    # Encoding is the slow part (about 30 s for 400 outputs on 4 cores), so
    # outputs are cached under `.jekyll-cache/image-derivatives/`. A manifest
    # records the source digest and encoding settings for each output; an
    # output is re-encoded only when either changes. CI restores the same
    # directory with actions/cache.
    #
    # ImageMagick does the encoding: `magick` (version 7) when present,
    # otherwise `convert` (version 6, as on Ubuntu runners).
    #
    # @validator A configured `source_dir` that is missing or holds a file
    #   that is not a JPEG or PNG; a `front_matter` collection that does not
    #   exist, or a document `image` that is remote, missing, or not a JPEG,
    #   PNG, or SVG; two sources in one directory whose names differ only in
    #   extension; one image in two entries; invalid `widths` or `sizes`;
    #   no ImageMagick with WebP support; or a failed encode.
    module ImageDerivatives
      CACHE_DIR = File.join('.jekyll-cache', 'image-derivatives')
      DERIVED_DIR = 'derived'
      SOURCE_EXTENSIONS = %w[.jpg .jpeg .png].freeze
      QUALITY = 80
      # Part of every output's cache key: changing encoding settings
      # re-encodes everything.
      SETTINGS = "webp q#{QUALITY} strip auto-orient v1".freeze
      MANIFEST = 'manifest.json'

      # One output to publish.
      Output = Struct.new(:source, :width, :url, :cache_file, keyword_init: true)

      class << self
        # Encodes missing or stale outputs and publishes every output.
        #
        # @param site [Jekyll::Site]
        # @return [Hash{String => Hash}] Source URL path (`/books/covers/dune.jpg`)
        #   to `{ 'srcset' =>, 'sizes' => }`.
        def build(site)
          specs = Array(site.config['image_derivatives'])
          return {} if specs.empty?

          cache_root = File.join(site.source, CACHE_DIR)
          entries = specs.flat_map { |spec| plan(site, spec, cache_root) }
          check_names(entries)
          encode_stale(entries.flat_map { |entry| entry[:outputs] }, cache_root)
          publish(site, entries, cache_root)
        end

        # @return [Array<Hash>] One entry per source: `{ source:, url:,
        #   width:, outputs:, sizes: }`.
        def plan(site, spec, cache_root)
          label, widths, sizes = validate_spec(spec)
          relatives = spec.key?('front_matter') ? front_matter_sources(site, label) : directory_sources(site, label)

          relatives.map do |relative|
            plan_source(File.join(site.source, relative), relative, widths, sizes, cache_root)
          end
        end

        private

        # Across every entry: no image twice, and no two sources whose
        # outputs would share a name.
        def check_names(entries)
          entries.group_by { |entry| entry[:url] }.each do |url, group|
            fail_with("#{url.delete_prefix('/')} is in more than one entry") if group.size > 1
          end
          stems = {}
          entries.each { |entry| claim_stem(stems, entry[:url].delete_prefix('/')) }
        end

        def validate_spec(spec)
          unless spec.is_a?(Hash)
            fail_with("each entry needs source_dir or front_matter, widths, and sizes; got #{spec.inspect}")
          end
          if spec.key?('source_dir') == spec.key?('front_matter')
            fail_with("each entry needs exactly one of source_dir and front_matter; got #{spec.inspect}")
          end

          label = (spec['source_dir'] || spec['front_matter']).to_s.delete_prefix('/').chomp('/')
          widths = spec['widths']
          sizes = spec['sizes'].to_s.strip
          fail_with("source_dir or front_matter is empty in #{spec.inspect}") if label.empty?
          unless widths.is_a?(Array) && !widths.empty? && widths.all? { |w| w.is_a?(Integer) && w.positive? }
            fail_with("widths for '#{label}' must be a list of positive integers")
          end
          fail_with("sizes for '#{label}' is missing") if sizes.empty?

          [label, widths.sort.uniq, sizes]
        end

        # @return [Array<String>] Source-relative paths of every file in the directory.
        def directory_sources(site, source_dir)
          absolute_dir = File.join(site.source, source_dir)
          fail_with("source_dir '#{source_dir}' does not exist") unless File.directory?(absolute_dir)

          Dir.children(absolute_dir).sort.filter_map do |name|
            next if File.directory?(File.join(absolute_dir, name))

            fail_with("#{source_dir}/#{name} is not a JPEG or PNG (.jpg, .jpeg, or .png)") unless source_image?(name)

            "#{source_dir}/#{name}"
          end
        end

        # @return [Array<String>] Source-relative paths of the collection's
        #   front-matter images, without duplicates or SVGs.
        def front_matter_sources(site, label)
          collection = site.collections[label]
          fail_with("front_matter collection '#{label}' does not exist") unless collection

          collection.docs.filter_map do |doc|
            source = FrontMatterImage.source_name(doc)
            image = FrontMatterImage.path(doc.data['image'], source: source)
            image && front_matter_source(site, image, source)
          end.uniq.sort
        end

        # @return [String, nil] The source-relative path, or nil for an SVG.
        def front_matter_source(site, image, source)
          resolved = LocalImage.resolve(image, site)
          problem = LocalImage::PROBLEMS[resolved.status]
          fail_with("image '#{image}' in #{source} #{problem}") if problem
          return nil if File.extname(resolved.relative) == '.svg'

          unless source_image?(resolved.relative)
            fail_with("image '#{image}' in #{source} is not a JPEG, PNG, or SVG (.jpg, .jpeg, .png, or .svg)")
          end
          fail_with("image '#{image}' in #{source} names no file") unless resolved.found?

          resolved.relative
        end

        def source_image?(name)
          SOURCE_EXTENSIONS.include?(File.extname(name))
        end

        # Output names drop the extension, so `dune.jpg` and `dune.png` in
        # one directory would write and publish the same `dune-300.webp`.
        def claim_stem(stems, relative)
          key = File.join(File.dirname(relative), File.basename(relative, '.*'))
          if (other = stems[key])
            fail_with(
              "#{other} and #{relative} would share derivative names " \
              "(#{File.basename(key)}-<width>.webp); rename one",
            )
          end
          stems[key] = relative
        end

        def plan_source(file, relative, widths, sizes, cache_root)
          original_width, = ImageDimensions.of(file)
          stem = File.basename(relative, '.*')
          derived_dir = File.join(File.dirname(relative), DERIVED_DIR)
          outputs = widths.select { |width| width < original_width }.map do |width|
            name = "#{stem}-#{width}.webp"
            Output.new(
              source: file,
              width: width,
              url: "/#{derived_dir}/#{name}",
              cache_file: File.join(cache_root, derived_dir, name),
            )
          end
          {
            source: file,
            url: "/#{relative}",
            width: original_width,
            outputs: outputs,
            sizes: sizes,
            # Any skipped width leaves the original as the widest candidate.
            include_original: original_width <= widths.max,
          }
        end

        def encode_stale(outputs, cache_root)
          manifest_path = File.join(cache_root, MANIFEST)
          manifest = read_manifest(manifest_path)
          digests = Hash.new { |hash, file| hash[file] = Digest::SHA256.file(file).hexdigest }
          stale = outputs.reject do |output|
            File.file?(output.cache_file) && manifest[output.cache_file] == key(output, digests)
          end
          return if stale.empty?

          Jekyll.logger.info 'ImageDerivatives:', "encoding #{stale.size} of #{outputs.size} images"
          encode_all(stale)
          stale.each { |output| manifest[output.cache_file] = key(output, digests) }
          FileUtils.mkdir_p(cache_root)
          File.write(manifest_path, JSON.pretty_generate(manifest.sort.to_h))
        end

        def key(output, digests)
          "#{digests[output.source]} #{output.width} #{SETTINGS}"
        end

        def read_manifest(path)
          File.file?(path) ? JSON.parse(File.read(path)) : {}
        rescue JSON::ParserError
          {}
        end

        # Runs one ImageMagick process per source, as many at once as there
        # are processors. Decoding the original dominates, so each process
        # decodes once and writes every width, largest first.
        def encode_all(outputs)
          command = imagemagick
          queue = Queue.new
          outputs.group_by(&:source).each_value { |group| queue << group.sort_by { |o| -o.width } }
          errors = Queue.new
          workers = Array.new([Etc.nprocessors, queue.size].min) do
            Thread.new do
              while (group = queue.pop(timeout: 0))
                error = encode(command, group)
                errors << error if error
              end
            end
          end
          workers.each(&:join)
          fail_with(errors.pop) unless errors.empty?
        end

        # @param group [Array<Output>] Outputs of one source, widest first.
        # @return [String, nil] An error message, or nil on success.
        def encode(command, group)
          temporaries = group.map do |output|
            FileUtils.mkdir_p(File.dirname(output.cache_file))
            "#{output.cache_file}.tmp.webp"
          end
          steps = group.zip(temporaries).flat_map do |output, temporary|
            ['-resize', "#{output.width}x", '-quality', QUALITY.to_s, '-write', temporary]
          end
          _out, err, status = Open3.capture3(
            command,
            group.first.source,
            '-auto-orient',
            '-strip',
            *steps,
            'null:',
          )
          return "encoding #{group.first.source} failed: #{err.strip}" unless status.success?

          group.zip(temporaries).each { |output, temporary| File.rename(temporary, output.cache_file) }
          nil
        end

        # @return [String] The ImageMagick command that can write WebP.
        def imagemagick
          @imagemagick ||= %w[magick convert].find { |command| writes_webp?(command) } ||
                           fail_with('needs ImageMagick with WebP support (`magick` or `convert`) on the PATH')
        end

        def writes_webp?(command)
          out, status = Open3.capture2e(command, '-list', 'format')
          status.success? && out.match?(/^\s*WEBP\*?\s+\S+\s+r?w/)
        rescue SystemCallError
          false
        end

        # Keys are source paths without `baseurl`, as ImageDimensionsInjector
        # looks them up; candidate URLs carry `baseurl`, as `src` does.
        def publish(site, entries, cache_root)
          base = site.config['baseurl'].to_s.chomp('/')
          entries.each_with_object({}) do |entry, srcsets|
            entry[:outputs].each do |output|
              relative = output.cache_file.delete_prefix("#{cache_root}/")
              site.static_files << Jekyll::StaticFile.new(
                site,
                cache_root,
                File.dirname(relative),
                File.basename(relative),
              )
            end
            next if entry[:outputs].empty?

            candidates = entry[:outputs].map { |output| "#{base}#{output.url} #{output.width}w" }
            candidates << "#{base}#{entry[:url]} #{entry[:width]}w" if entry[:include_original]
            srcsets[entry[:url]] = { 'srcset' => candidates.join(', '), 'sizes' => entry[:sizes] }
          end
        end

        def fail_with(problem)
          raise Jekyll::Errors::FatalException, "ImageDerivatives: #{problem}."
        end
      end
    end

    # Runs ImageDerivatives and stores its `srcset` table where
    # ImageDimensionsInjector reads it.
    class ImageDerivativesGenerator < Jekyll::Generator
      safe true

      def generate(site)
        site.data['image_srcsets'] = ImageDerivatives.build(site)
      end
    end
  end
end
