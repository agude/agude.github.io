# frozen_string_literal: true

# _plugins/optional_filter.rb
require 'jekyll'
require 'liquid'

module Jekyll
  # A filter to safely access optional variables when strict_variables is enabled.
  # Usage: {{ page | optional: "my_variable" }}
  module OptionalFilter
    def optional(object, property)
      # If the object is nil, we can't look anything up.
      return nil if object.nil?

      # If it doesn't respond to [], it's definitely not a container we can index.
      return nil unless object.respond_to?(:[])

      # Try to access the property.
      # We rescue TypeError and ArgumentError because some objects (like Integer or Array)
      # respond to [] but will crash if passed a key of the wrong type (e.g. a String).
      begin
        object[property]
      rescue TypeError, ArgumentError
        nil
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::OptionalFilter)
