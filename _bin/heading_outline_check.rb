# frozen_string_literal: true

require 'html-proofer'

# HTMLProofer check, run by check_links.rb over every page in _site/: a
# page needs exactly one <h1>, the <h1> must be its first heading, and no
# heading may skip a level on the way down (<h1> then <h3>). Going back up
# any number of levels (<h4> then <h2>) is allowed. Screen-reader users
# move through a page by its headings; a second <h1> or a skipped level
# misstates the page's structure.
#
# Post layouts supply the page title as the <h1>, so sections in post
# Markdown start at `##`.
#
# This runs over the built site rather than as a post_render hook because
# it applies to every page: as a hook it would also fire on the minimal
# fixture sites and fake pages the plugin tests build, none of which have
# an outline.
class HeadingOutline < HTMLProofer::Check
  # The Markdown test page renders one of every element, including several
  # <h1>s, on purpose.
  EXEMPT_PAGES = ['test/index.html'].freeze

  HEADINGS = 'h1, h2, h3, h4, h5, h6'

  def run
    return if exempt?

    headings = @html.css(HEADINGS).map { |node| [node.name[1].to_i, create_element(node)] }
    check_h1_count(headings)
    headings.each_cons(2) { |previous, current| check_step(previous, current) }
    check_first(headings.first)
  end

  private

  def exempt?
    path = @runner.current_filename.to_s
    EXEMPT_PAGES.any? { |page| path.end_with?("/#{page}") }
  end

  def check_h1_count(headings)
    count = headings.count { |level, _| level == 1 }
    return if count == 1

    add_failure("page has #{count} <h1> headings; it needs exactly one", line: headings.first&.last&.line)
  end

  def check_first(first)
    return if first.nil? || first[0] == 1

    level, element = first
    add_failure("first heading is <h#{level}> \"#{text(element)}\"; it must be the <h1>", element: element)
  end

  def check_step(previous, current)
    previous_level, previous_element = previous
    level, element = current
    return if level <= previous_level + 1

    add_failure(
      "heading skips from <h#{previous_level}> \"#{text(previous_element)}\" to <h#{level}> \"#{text(element)}\"",
      element: element,
    )
  end

  def text(element)
    element.node.text.gsub(/\s+/, ' ').strip
  end
end
