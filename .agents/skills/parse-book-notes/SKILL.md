---
name: parse-book-notes
description: >-
  Turns rough book-review notes into verified Liquid capture blocks. Uses
  strict bundled generators for author/work groups, standalone references,
  and media titles. Use when starting a book review from notes, especially
  voice-transcribed notes.
---

# Parse Book Notes

Turn rough review notes into Liquid captures for references the review will
use. The bundled scripts format names and titles that have already been
resolved. They do not extract references from prose or decide what a note
means.

## Workflow

1. Identify books, authors, series, short stories, movies, games, and TV shows
   in the notes. Correct transcription errors before generating captures.
2. Check spelling against `_books/`, `books/authors/`, and `books/series/`.
   Existing content is the source for the site's stored names. A missing page
   is not an error: the link tags render styled text for unreviewed works.
3. Keep agent-found comparison candidates separate from confirmed references.
   Report candidates first. Generate captures only for references the review
   will use.
4. Classify each confirmed reference and run the matching script:
   - Use `generate_reference_group.py` for an author and associated books or
     series. This is the standard path.
   - Use `generate_standalone_reference.py` only for an intentionally unlinked
     author, book, or series.
   - Use `generate_media_reference.py` for movies, games, and TV shows.
5. Put generated captures below the opening paragraph. The opening paragraph
   is the Jekyll excerpt; a capture block above it replaces the excerpt with
   empty output.
6. Draft with every generated author variant. After the prose is complete,
   remove only capture variants the prose does not use.
7. Check the remaining names, titles, and variable names. Run
   `make check-liquid` after inserting or pruning captures.

Run the scripts from `.agents/skills/parse-book-notes/`. Every reference value
accepts `NAME` or `NAME=variable_name`. Use an explicit variable name for a
familiar abbreviation or to resolve a collision.

## Generate an author/work group

One invocation represents one author group. It requires at least one
`--author` and at least one `--book` or `--series`:

```bash
uv run scripts/generate_reference_group.py \
    --author "Iain M. Banks" \
    --series "Culture" \
    --book "Surface Detail" \
    --book "The Player of Games"
```

The script writes one contiguous group to stdout:

```liquid
{% capture banks %}{% author_link "Iain M. Banks" %}{% endcapture %}
{% capture bankss %}{% author_link "Iain M. Banks" possessive %}{% endcapture %}
{% capture banks_lastname %}{% author_link "Iain M. Banks" link_text="Banks" %}{% endcapture %}
{% capture bankss_lastname %}{% author_link "Iain M. Banks" link_text="Banks" possessive %}{% endcapture %}
{% capture culture %}{% series_link "Culture" %}{% endcapture %}
{% capture surface_detail %}{% book_link "Surface Detail" %}{% endcapture %}
{% capture the_player_of_games %}{% book_link "The Player of Games" %}{% endcapture %}
```

Run the script again for a different author, then separate the two generated
groups with one blank line in the review:

```bash
uv run scripts/generate_reference_group.py \
    --author "Vernor Vinge" \
    --book "A Fire Upon The Deep=fire_deep"

uv run scripts/generate_reference_group.py \
    --author "Iain M. Banks" \
    --book "Matter"
```

Do not combine unrelated authors in one invocation. Put every referenced book
or series by the same author in that author's invocation. The book template
already defines captures for the review's own book, author, and series.

The script rejects incomplete groups. Two-author works require both individual
author bundles and one combined pair capture:

```bash
uv run scripts/generate_reference_group.py \
    --author "Amal El-Mohtar" \
    --author "Max Gladstone" \
    --author-pair "Amal El-Mohtar|Max Gladstone" \
    --book "This Is How You Lose the Time War"
```

For siblings, give the pair an explicit first-name variable, such as
`--author-pair "Arkady Strugatsky|Boris Strugatsky=arkady_and_boris"`. For
three or more contributors, give each `--author` an `author_`-prefixed variable
name to prevent surname collisions. A three-or-more-author anthology does not
require a combined pair capture.

The four author variables cover full name, full-name possessive, surname, and
surname possessive. Keep all four while drafting. The possessive variable adds
`s`, so `banks` becomes `bankss`, as required by the review convention.

## Generate an intentionally standalone reference

The standalone script accepts exactly one `--author`, `--book`, or `--series`:

```bash
uv run scripts/generate_standalone_reference.py \
    --book "Network Effect=mb5"
```

This script always emits several `You are probably doing this wrong` warnings
to stderr. Read them before using its stdout. Use it only when the prose
deliberately omits the normal author/work relationship, such as title-only
shorthand for another book by the review's already-captured author. An
author-only invocation still emits the complete four-capture author bundle.

Do not use the standalone script as a shorter way to generate several books.
Use the standard group script with their author.

## Generate media references

Movies, games, and TV shows are legitimately standalone. Generate one or more
with the media script:

```bash
uv run scripts/generate_media_reference.py \
    --movie "Alien" \
    --game "Control" \
    --tv-show "The Expanse=expanse"
```

The script emits `movie_title`, `game_title`, and `tv_show_title` captures in
that order. Use `--book "Disco Elysium"` through the standard or standalone
book workflow; it is the exception to the game-title rule. Generate a filmmaker
or showrunner named without an associated book through the standalone
`--author` path because that person uses an `author_link` page.

## Output and cleanup

All three scripts write only paste-ready Liquid to stdout. Errors and warnings
go to stderr. They support `--help` and `--porcelain`; porcelain output is the
same plain Liquid, and standalone warnings remain visible.

The scripts deduplicate repeated inputs and reject incompatible variable-name
collisions. They do not write to the review.

Finished reviews are post-pruning artifacts. Do not infer parse-stage capture
shape from their missing author variants. After drafting, preview unused
captures from the repository root:

```bash
uv run _scripts/content/jekyll_clean_captures.py \
    _books/example_review.md \
    --dry-run
```

Remove only variants confirmed unused by the completed prose, then run
`make check-liquid`.

## Other reference types

Do not pass `--series` for a standalone work. Write short-story captures
manually when a `from_book` disambiguator is needed:

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
