# frozen_string_literal: true

require 'html-proofer'

# HTMLProofer check, run by check_links.rb over every page in _site/: no
# page text may contain raw TeX, meaning a math delimiter (`$$`, `\(`, `\)`,
# `\[`, `\]`) or a command (`\phi`). The command pattern matters because
# kramdown reads `\(` in Markdown as an escaped parenthesis, so MathJax-style
# math in a Markdown caption renders as `(\phi^*)`, with no delimiter left.
# Math is converted to MathML at build time (TexToMathml), but only where
# kramdown parses the Markdown; TeX inside raw HTML, or written in
# MathJax's `\( \)` form, passes through untouched. MathJax used to render
# such leftovers in the browser. Without it they show as raw TeX.
#
# Code is exempt: `<pre>`, `<code>`, `<script>`, `<style>`, and `<textarea>`
# may hold these characters legitimately, as may MathML (matched by local
# name: the HTML5 parser puts <math> in the MathML namespace).
class RawTex < HTMLProofer::Check
  RAW_TEX = /\$\$|\\[()\[\]]|\\[A-Za-z]+/
  TEXT_OUTSIDE_CODE = '//body//text()[not(ancestor::pre or ancestor::code or ancestor::script ' \
                      'or ancestor::style or ancestor::textarea or ancestor::*[local-name()="math"])]'

  def run
    @html.xpath(TEXT_OUTSIDE_CODE).each do |node|
      text = node.text
      next unless (match = text.match(RAW_TEX))

      add_failure(
        "raw TeX '#{match[0]}' in \"#{excerpt(text, match.begin(0))}\"; " \
        'write math as $$...$$ where kramdown parses it (a figure caption works; raw HTML does not)',
        line: node.line,
      )
    end
  end

  private

  def excerpt(text, index)
    text[[index - 30, 0].max, 70].gsub(/\s+/, ' ').strip
  end
end
