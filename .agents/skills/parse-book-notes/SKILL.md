---
name: parse-book-notes
description: >-
  Turns rough book-review notes into verified Liquid capture blocks. Uses a
  bundled generator for repeatable book, author, series, and media captures.
  Use when starting a book review from notes, especially voice-transcribed notes.
---

# Parse Book Notes

Turn rough book-review notes into Liquid captures for the references used in a
review. The bundled generator formats names and titles that have already been
resolved; it does not extract references from prose or decide what a note means.

## Workflow

1. Identify books, authors, series, short stories, movies, games, and TV shows
   in the notes. Correct transcription errors before generating captures.
2. Check spelling against `_books/`, `books/authors/`, and `books/series/`.
   Existing content is the source for the site's stored names. A missing page
   is not an error: the link tags render styled text for unreviewed works.
3. Run `scripts/generate_captures.py` for references other than the review's
   own book, author, and series. The book template already defines captures
   for those three values.
4. Put the generated captures below the opening paragraph. The opening
   paragraph is the Jekyll excerpt; a capture block above it replaces the
   excerpt with empty output.
5. Check the rendered blocks for the intended name, title, and variable name.
   Run `make check-liquid` after inserting them into the review.

## Generate standard captures

Run the generator from this skill directory. Each repeatable flag accepts
`NAME` or `NAME=variable_name`. Use the explicit variable name for a familiar
abbreviation or when two references would otherwise collide.

```bash
uv run scripts/generate_captures.py \
    --author "Iain M. Banks" \
    --series "Culture" \
    --book "Surface Detail"
```

The command writes paste-ready Liquid to stdout:

```liquid
{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}
{% capture bankss_lastname %}{% author_link "Iain M. Banks" link_text="Banks" possessive %}{% endcapture %}

{% capture culture %}{% series_link "Culture" %}{% endcapture %}

{% capture surface_detail %}{% book_link "Surface Detail" %}{% endcapture %}
```

Repeat `--book` to generate captures for several books in one invocation:

```bash
uv run scripts/generate_captures.py \
    --book "Surface Detail" \
    --book "The Player of Games"
```

The generator deduplicates repeated inputs and rejects variable-name
collisions. Do not trim the four-capture author bundle: a missing full-name,
possessive, surname, or surname-possessive form becomes a drafting error later.
Do not pass `--series` for a standalone work.

| Flag | Generates |
| --- | --- |
| `--author NAME[=VARIABLE]` | The four standard author captures. |
| `--author-pair 'NAME|NAME[=VARIABLE]'` | Full-name and possessive captures for a pair. |
| `--book TITLE[=VARIABLE]` | A `book_link` capture. |
| `--series TITLE[=VARIABLE]` | A `series_link` capture. |
| `--movie`, `--game`, `--tv-show` | The matching media-title capture. |

For example, use `--series "The Book of the New Sun=botns"` for an
abbreviation. Use `--author "Linda Evans=author_evans"` for each contributor
to a 3-or-more-author anthology. The generated possessive variable appends
`s`, so `banks` becomes `bankss`, as required by the review convention.

The script intentionally does not write to the review. Inspect its output,
then place it where the draft needs it. Run `uv run scripts/generate_captures.py
--help` for the complete interface.

## Multiple authors and other media

Generate each author's four-capture bundle once. When prose needs a combined
form, add a pair capture as well:

```bash
uv run scripts/generate_captures.py \
    --author "Amal El-Mohtar" \
    --author "Max Gladstone" \
    --author-pair "Amal El-Mohtar|Max Gladstone"
```

For siblings, use an explicit pair name with first names, such as
`--author-pair "Arkady Strugatsky|Boris Strugatsky=arkady_and_boris"`. For
three or more contributors, give each `--author` an `author_`-prefixed variable
name to prevent collisions.

Use `--movie`, `--game`, and `--tv-show` for media titles. Filmmakers and
showrunners use `--author`, because they receive `author_link` pages. Use
`--book "Disco Elysium"`; it is the exception to the game-title rule.

Write short-story captures manually when a `from_book` disambiguator is
needed:

```liquid
{% capture new_rose_hotel %}{% short_story_link "New Rose Hotel" from_book="Burning Chrome" %}{% endcapture %}
```

## Treat the notes as source material

- Notes outrank recollection. Do not contradict a note's claim about plot,
  character, or biography unless the text is available or the claim has been
  verified. A note describing Sandii in "New Rose Hotel" as an early version
  of Kumiko in _Mona Lisa Overdrive_ was correct: both are mixed-heritage
  Japanese women caught between larger powers.
- Drafts are scratchpads. A sentence in an unexpected section is usually a
  parking place, not a misfiled argument. Ask before treating it as an error.
- `notes.md` keeps raw notes above its separator and `# Review Plan` below it.
  Append factual corrections, theme assignments, and missing-capture work to
  the plan. Never edit the raw notes above the separator.

## Resolve uncertainty and report

Use existing content and reliable sources to resolve voice-transcription
mistakes such as "shriek" for Shrike, "telehard" for Teilhard, and
"forecaster" for farcaster. If a reference remains ambiguous, report it rather
than guessing.

Return the generated blocks and identify every unresolved spelling, identity,
or capture-name choice. Before publishing the completed review, run
`make check-links && make check-refs && make check-liquid`.
