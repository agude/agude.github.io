# frozen_string_literal: true

# Minimal valid image files for fixture sites. A fixture build runs
# ImageDimensionsInjector, which reads each local <img>'s header and stops
# the build on a file that is not an image, so placeholder text no longer
# passes as a cover.
module ImageFixture
  # @return [String] A JPEG with only a start-of-frame header: enough for
  #   ImageDimensions, not a decodable picture.
  def self.jpeg(width, height)
    frame = [8, height, width, 3].pack('CnnC') + ("\0" * 9)
    "\xFF\xD8".b + [0xFF, 0xC0, frame.bytesize + 2].pack('CCn') + frame + "\xFF\xD9".b
  end
end
