# frozen_string_literal: true

# Finds markdown reference-link problems in a single document's source.
#
# The source is Liquid-flavored markdown, so it cannot be parsed as pure
# markdown: Liquid appears inside link URLs (`[id]: {% post_url ... %}`),
# inside link text (`[{% book_title %}][id]`), and as bare control flow.
# Rather than deleting Liquid, every construct is replaced by an opaque
# placeholder word that preserves the surrounding markdown structure and the
# original line count, so reported line numbers match the file on disk.
#
# Deleting Liquid is what causes false positives: dropping a `{% capture %}`
# body loses the references inside it, and truncating a definition line at
# its first Liquid tag loses references that follow (footnote definitions
# routinely contain both).
module ReferenceLinkScanner
  # Stands in for any Liquid construct. Must be a bare word so that it is a
  # valid URL body in `[id]: <placeholder>` and valid link text in
  # `[<placeholder>][id]`.
  PLACEHOLDER = 'liquid-placeholder'

  COMMENT_BLOCK_RE = /\{%-?\s*comment\s*-?%\}.*?\{%-?\s*endcomment\s*-?%\}/m
  FENCED_CODE_RE = /^([ \t]*)(`{3,}|~{3,}).*?^\1\2[ \t]*$/m
  INLINE_CODE_RE = /(`+)(?:(?!\1)[^\n])+\1/
  LIQUID_OUTPUT_RE = /\{\{.*?\}\}/m
  LIQUID_TAG_RE = /\{%.*?%\}/m

  # Full-form reference: [text][id], or [text][] which reuses text as the id.
  # Spans lines because link text is frequently wrapped.
  FULL_REF_RE = /\[([^\]]+)\]\[([^\]]*)\]/m
  # Shorthand reference: [id] not followed by [, : or ( — i.e. not a full
  # reference, a definition, or an inline link. Only used to suppress orphan
  # warnings; never to report undefined links, because editorial brackets in
  # prose ("[sic]", "[...]") are indistinguishable from real shorthand.
  SHORTHAND_REF_RE = /\[([^\]]+)\](?!\[|:|\()/
  # Definition: [id]: URL, indented at most 3 spaces. Footnote definitions
  # ([^id]:) are excluded — they are prose that can contain real references.
  DEFINITION_RE = /^ {0,3}\[([^\^\]][^\]]*)\]:[ \t]+\S/

  module_function

  # Returns every problem as [{ line:, message: }], ordered by line, with
  # line numbers offset into the original file. All three kinds are fatal,
  # so there is no severity to report — the message names the kind.
  def scan(content, line_offset: 0)
    neutralized = neutralize_liquid(content)
    # Offset up front so that every line number a message quotes is already
    # a real file line.
    definitions = offset(find_definitions(neutralized), line_offset)
    references = find_references(neutralized).transform_values { |refs| offset(refs, line_offset) }

    problems = undefined_errors(references[:full], definitions) +
               duplicate_errors(definitions) +
               orphan_errors(definitions, references)

    problems.sort_by { |problem| problem[:line] }
  end

  # How many lines of the file precede `content`. Jekyll hands us the body
  # with the YAML front matter already removed, so scanner line numbers need
  # this offset to point at the real file. Located by matching the body
  # against the file rather than by re-parsing front matter, so it stays
  # correct whatever Jekyll's delimiter handling does.
  def content_line_offset(path, content)
    raw = File.read(path)
    index = raw.index(content)
    index ? raw[0...index].count("\n") : 0
  end

  def offset(entries, amount)
    entries.map { |entry| entry.merge(line: entry[:line] + amount) }
  end

  # Replace every Liquid construct with a placeholder that keeps both the
  # markdown structure and the line count intact. Code is removed too: it is
  # not markdown, so brackets inside it are not links.
  def neutralize_liquid(content)
    content
      .gsub(COMMENT_BLOCK_RE) { blank_lines(::Regexp.last_match(0)) }
      .gsub(FENCED_CODE_RE) { blank_lines(::Regexp.last_match(0)) }
      .gsub(INLINE_CODE_RE) { PLACEHOLDER }
      .gsub(LIQUID_OUTPUT_RE) { placeholder_lines(::Regexp.last_match(0)) }
      .gsub(LIQUID_TAG_RE) { placeholder_lines(::Regexp.last_match(0)) }
  end

  def blank_lines(text)
    "\n" * text.count("\n")
  end

  def placeholder_lines(text)
    PLACEHOLDER + blank_lines(text)
  end

  def find_definitions(content)
    definitions = []
    content.each_line.with_index(1) do |line, lineno|
      next unless (match = line.match(DEFINITION_RE))

      definitions << { id: match[1].downcase, line: lineno }
    end
    definitions
  end

  def find_references(content)
    # Definition lines hold URLs, not prose; scanning them would treat a
    # bracketed URL fragment as a reference.
    body = content.lines.map { |line| line.match?(DEFINITION_RE) ? "\n" : line }.join

    full = []
    body.scan(FULL_REF_RE) do |text, id|
      id = text if id.empty?
      next if id.start_with?('^')

      full << { id: id.downcase, line: body[0...::Regexp.last_match.begin(0)].count("\n") + 1 }
    end

    shorthand = []
    body.each_line.with_index(1) do |line, lineno|
      line.scan(SHORTHAND_REF_RE) do |id,|
        next if id.start_with?('^')

        shorthand << { id: id.downcase, line: lineno }
      end
    end

    { full: full, shorthand: shorthand }
  end

  def undefined_errors(full_references, definitions)
    defined_ids = Set.new(definitions.map { |definition| definition[:id] })

    full_references.reject { |ref| defined_ids.include?(ref[:id]) }
                   .map { |ref| { line: ref[:line], message: "undefined reference link [#{ref[:id]}]" } }
  end

  def duplicate_errors(definitions)
    first_seen = {}
    definitions.filter_map do |definition|
      first = first_seen[definition[:id]]
      if first.nil?
        first_seen[definition[:id]] = definition[:line]
        next
      end

      {
        line: definition[:line],
        message: "duplicate link definition [#{definition[:id]}] (first defined on line #{first})",
      }
    end
  end

  def orphan_errors(definitions, references)
    used = Set.new(
      references[:full].map { |ref| ref[:id] } +
      references[:shorthand].map { |ref| ref[:id] },
    )

    definitions.reject { |definition| used.include?(definition[:id]) }
               .map { |d| { line: d[:line], message: "orphaned link definition [#{d[:id]}]" } }
  end
end
