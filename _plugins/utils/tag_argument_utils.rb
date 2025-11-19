# frozen_string_literal: true

# _plugins/utils/tag_argument_utils.rb

module TagArgumentUtils
  # Resolves a Liquid markup string.
  # - If the markup is quoted (single or double), returns the literal string content.
  # - If the markup is NOT quoted, assumes it's a variable name (simple or dot notation)
  #   and attempts to look it up in the context using context[].
  # - Returns the variable's value if found (which can be any object, including nil or false).
  # - Returns nil if the unquoted variable name is not found in the context.
  #
  # @param markup [String] The markup string from the Liquid tag.
  # @param context [Liquid::Context] The current Liquid context.
  # @return [String, Object, nil] The resolved value.
  def self.resolve_value(markup, context)
    return nil if markup.nil? || markup.empty?

    stripped_markup = markup.strip
    return nil if stripped_markup.empty?

    if quoted?(stripped_markup)
      # It's a quoted literal. Return the content inside the quotes.
      stripped_markup[1..-2]
    else
      # Not quoted. Assume it's a variable name (simple or dot notation).
      # Look it up using context[]. This handles dot notation and returns nil
      # for failed lookups or if the variable's actual value is nil.
      context[stripped_markup]
    end
  end

  def self.quoted?(markup)
    (markup.start_with?('"') && markup.end_with?('"')) ||
      (markup.start_with?("'") && markup.end_with?("'"))
  end
  private_class_method :quoted?
end
