# frozen_string_literal: true

require 'prism'

# Match the method token so a call split across lines uses the same line as
# TracePoint. Prism also parses a bare re-raise as a call.
class RaiseSiteVisitor < Prism::Visitor
  attr_reader :lines

  def initialize
    super
    @lines = []
  end

  def visit_call_node(node)
    @lines << node.message_loc.start_line if %i[raise fail].include?(node.name)
    super
  end
end

Dir.glob('_plugins/**/*.rb').each do |path|
  result = Prism.parse_file(path)
  abort "Cannot parse #{path}: #{result.errors.map(&:message).join(', ')}" unless result.success?

  visitor = RaiseSiteVisitor.new
  visitor.visit(result.value)
  visitor.lines.uniq.sort.each { |line| puts "#{path}:#{line}" }
end
