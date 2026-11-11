# frozen_string_literal: true

require 'fastimage'
require 'jekyll'
require 'nokogiri'
require 'stringio'

module Jekyll
  module Infrastructure
    # Reads the intrinsic size of a local image file, so
    # ImageDimensionsInjector can give every `<img>` a `width` and `height`
    # and the browser can reserve the image's box before it loads.
    #
    # The size is the one the browser displays:
    # - Raster images (PNG, GIF, JPEG, WebP, AVIF, and others) are read by
    #   FastImage, which swaps the axes of a JPEG whose EXIF orientation
    #   rotates it, as browsers do (`image-orientation: from-image`).
    # - An SVG uses its root `width` and `height`, converted from absolute
    #   units (px, pt, pc, mm, cm, in) to CSS pixels. FastImage does not
    #   convert units, and Matplotlib writes sizes in `pt`, so SVG is read
    #   with Nokogiri instead.
    #
    # A file whose first non-blank byte is `<` is treated as SVG; no raster
    # format starts with `<`.
    #
    # Sizes are memoized per path for one build, because a cover appears on
    # many pages (its book, cards, previews). The memo is cleared when the
    # site resets, before generators run, so neither ImageDerivatives nor a
    # page in a `make serve` rebuild reuses a stale size.
    #
    # @validator An image file that is unreadable, in an unsupported format,
    #   truncated before its size, or zero pixels wide or high, and an SVG
    #   whose root lacks an absolute `width` or `height`. A percentage or
    #   missing SVG size has no intrinsic pixel size, so emitting attributes
    #   would change how it renders.
    module ImageDimensions
      # CSS pixels per unit (CSS Values 4, absolute lengths).
      SVG_UNITS = {
        '' => 1.0,
        'px' => 1.0,
        'pt' => 96.0 / 72,
        'pc' => 16.0,
        'mm' => 96.0 / 25.4,
        'cm' => 96.0 / 2.54,
        'in' => 96.0,
      }.freeze
      MARKUP_START = /\A(?:\xEF\xBB\xBF)?\s*</n
      private_constant :SVG_UNITS, :MARKUP_START

      @sizes = {}

      class << self
        # @param file [String] Absolute path of an existing image file.
        # @return [Array(Integer, Integer)] Display width and height in CSS pixels.
        # @raise [Jekyll::Errors::FatalException] When the size cannot be read.
        def of(file)
          @sizes[file] ||= read(file)
        rescue SystemCallError => e
          fail_with(file, "cannot be read (#{e.message})")
        end

        # Forgets every size. Runs at the start of each build; tests call it
        # between cases that reuse a path.
        def reset
          @sizes = {}
        end

        private

        def read(file)
          bytes = File.binread(file)
          size = bytes.match?(MARKUP_START) ? svg_size(bytes, file) : raster_size(bytes, file)
          fail_with(file, "has a zero dimension (#{size.join('x')})") if size.include?(0)
          size
        end

        def raster_size(bytes, file)
          FastImage.size(StringIO.new(bytes), raise_on_failure: true)
        rescue FastImage::FastImageException => e
          fail_with(file, "is not a readable image (#{e.class.name.split('::').last})")
        end

        # Reads only up to the root element, so a large plot is not parsed
        # in full. External DTDs are never fetched.
        def svg_size(bytes, file)
          root = svg_root_attributes(bytes)
          fail_with(file, 'is markup without an <svg> root element') unless root

          [svg_length(root['width'], 'width', file), svg_length(root['height'], 'height', file)]
        end

        # @return [Hash{String => String}, nil] The root's un-prefixed
        #   attributes, entity-decoded; nil unless the root is <svg>.
        def svg_root_attributes(bytes)
          reader = Nokogiri::XML::Reader(bytes, nil, nil, Nokogiri::XML::ParseOptions::NONET)
          root = reader.find { |node| node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT }
          root&.local_name == 'svg' ? root.attribute_hash : nil
        rescue Nokogiri::XML::SyntaxError
          nil
        end

        def svg_length(raw, name, file)
          match = raw&.strip&.match(/\A(\d+(?:\.\d+)?|\.\d+)\s*([a-z]*)\z/i)
          factor = match && SVG_UNITS[match[2].downcase]
          unless factor
            fail_with(
              file,
              "is an SVG whose root #{name} is #{raw ? "'#{raw}'" : 'missing'}; " \
              'set an absolute width and height on the <svg> element',
            )
          end
          (match[1].to_f * factor).round
        end

        def fail_with(file, problem)
          raise Jekyll::Errors::FatalException, "ImageDimensions: #{file} #{problem}."
        end
      end
    end
  end
end

Jekyll::Hooks.register :site, :after_reset do |_site|
  Jekyll::Infrastructure::ImageDimensions.reset
end
